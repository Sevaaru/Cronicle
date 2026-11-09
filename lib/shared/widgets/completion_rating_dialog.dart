import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/trakt/data/trakt_library_remote_sync.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

/// Material 3 dialog shown right after the user finishes a title (anime,
/// manga, movie, TV show, game or book). Asks them to optionally drop a
/// score and a personal note, persisting both to the local database and
/// syncing to AniList / Trakt using the same code paths the
/// add_to_library_sheet uses.
///
/// Returns true if anything was saved, false if the user skipped.
Future<bool> showCompletionRatingDialog({
  required BuildContext context,
  required WidgetRef ref,
  required LibraryEntry entry,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CompletionRatingDialog(entry: entry),
  );
  return saved ?? false;
}

class _CompletionRatingDialog extends ConsumerStatefulWidget {
  const _CompletionRatingDialog({required this.entry});
  final LibraryEntry entry;

  @override
  ConsumerState<_CompletionRatingDialog> createState() =>
      _CompletionRatingDialogState();
}

class _CompletionRatingDialogState
    extends ConsumerState<_CompletionRatingDialog> {
  late double _score;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _scoreCtrl;
  bool _saving = false;
  // Avoid feedback loops between the slider's onChanged and the text
  // field's onChanged when one updates the other programmatically.
  bool _syncingScoreText = false;

  @override
  void initState() {
    super.initState();
    final scoring = ref.read(scoringSystemSettingProvider);
    _score = scoring.fromStoredScore(widget.entry.score);
    _notesCtrl = TextEditingController(text: widget.entry.notes ?? '');
    _scoreCtrl = TextEditingController(text: _formatScoreInput(scoring, _score));
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  /// Plain numeric representation of the current score for the manual text
  /// input. Empty string when no score is set.
  String _formatScoreInput(ScoringSystem scoring, double v) {
    if (v <= 0) return '';
    return switch (scoring) {
      ScoringSystem.point10Decimal => v.toStringAsFixed(1),
      _ => v.round().toString(),
    };
  }

  void _onSliderChanged(double v, ScoringSystem scoring) {
    setState(() => _score = v);
    _syncingScoreText = true;
    _scoreCtrl.value = TextEditingValue(
      text: _formatScoreInput(scoring, v),
      selection: TextSelection.collapsed(
        offset: _formatScoreInput(scoring, v).length,
      ),
    );
    _syncingScoreText = false;
  }

  void _onScoreTextChanged(String raw, ScoringSystem scoring) {
    if (_syncingScoreText) return;
    final cleaned = raw.replaceAll(',', '.').trim();
    if (cleaned.isEmpty) {
      setState(() => _score = 0);
      return;
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return;
    final clamped = parsed.clamp(0.0, scoring.max).toDouble();
    setState(() => _score = clamped);
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Modern Material 3 expressive slider: tall rectangular track with a
    // gap around the handle, rectangular handle bar, and visible stop
    // indicators. Matches Android 15 / Material 3 expressive guidance.
    return SliderTheme.of(context).copyWith(
      year2023: false,
      trackHeight: 16,
      activeTrackColor: cs.primary,
      inactiveTrackColor: cs.surfaceContainerHighest,
      thumbColor: cs.primary,
      overlayColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.dragged) ||
            states.contains(WidgetState.pressed)) {
          return cs.primary.withAlpha(40);
        }
        return Colors.transparent;
      }),
      // M3 expressive shapes (Flutter 3.27+).
      trackShape: const GappedSliderTrackShape(),
      thumbShape: const HandleThumbShape(),
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
      activeTickMarkColor: cs.onPrimary.withAlpha(160),
      inactiveTickMarkColor: cs.onSurfaceVariant.withAlpha(110),
      valueIndicatorColor: cs.inverseSurface,
      valueIndicatorTextStyle: TextStyle(
        color: cs.onInverseSurface,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      showValueIndicator: ShowValueIndicator.onlyForContinuous,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final scoring = ref.read(scoringSystemSettingProvider);
    final db = ref.read(databaseProvider);
    final storedScore =
        _score > 0 ? scoring.toStoredScore(_score) : null;
    final notes = _notesCtrl.text.trim();
    final notesValue = notes.isNotEmpty ? notes : null;

    try {
      await db.updateLibraryEntryRatingAndNotes(
        entryId: widget.entry.id,
        score: storedScore,
        notes: notesValue,
      );

      // Sync to AniList for anime/manga.
      final kind = MediaKind.fromCode(widget.entry.kind);
      if (kind == MediaKind.anime || kind == MediaKind.manga) {
        unawaited(_syncToAnilist(storedScore, notesValue));
      }
      // Sync to Trakt for movies/TV (Trakt has no anime category).
      if (kind == MediaKind.movie || kind == MediaKind.tv) {
        final tid = int.tryParse(widget.entry.externalId);
        if (tid != null) {
          unawaited(syncTraktEntryFromLocalDatabase(ref, kind, tid));
        }
      }
    } catch (_) {
      // Local DB write failed — surface nothing extra; the +1 already
      // happened. Pop with false so caller doesn't think we saved.
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop(false);
      }
      return;
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _syncToAnilist(int? score, String? notes) async {
    try {
      final token = await ref.read(anilistTokenProvider.future);
      if (token == null) return;
      final mediaId = int.tryParse(widget.entry.externalId);
      if (mediaId == null) return;
      final graphql = ref.read(anilistGraphqlProvider);
      await graphql.saveMediaListEntry(
        mediaId: mediaId,
        token: token,
        score: score,
        notes: notes,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final scoring = ref.watch(scoringSystemSettingProvider);
    // For the precise text input, allow decimals only on the decimal scale.
    final allowDecimals = scoring == ScoringSystem.point10Decimal;

    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.entry.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Score block.
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 18,
                          color: _score > 0
                              ? Colors.amber.shade600
                              : cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(l10n.addToListScore,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          )),
                      const Spacer(),
                      // Manual numeric input. Two-way bound with the slider.
                      SizedBox(
                        width: 78,
                        child: TextField(
                          controller: _scoreCtrl,
                          enabled: !_saving,
                          textAlign: TextAlign.end,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: allowDecimals,
                            signed: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              allowDecimals
                                  ? RegExp(r'[0-9.,]')
                                  : RegExp(r'[0-9]'),
                            ),
                          ],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: cs.surfaceContainerHighest,
                            hintText: '—',
                            suffixText: '/${_maxLabel(scoring)}',
                            suffixStyle: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: cs.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (raw) =>
                              _onScoreTextChanged(raw, scoring),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: _sliderTheme(context),
                    child: Slider(
                      value: _score.clamp(0.0, scoring.max),
                      min: 0,
                      max: scoring.max,
                      divisions: scoring.divisions,
                      label: _score == 0
                          ? l10n.addToListNoScore
                          : scoring.formatScore(_score),
                      onChanged: _saving
                          ? null
                          : (v) => _onSliderChanged(v, scoring),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Notes block.
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _notesCtrl,
                maxLines: 3,
                minLines: 2,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: l10n.addToListNotesHint,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.completionDialogSkip),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(l10n.addToListSave),
        ),
      ],
    );
  }

  /// Numeric upper bound shown next to the manual score field.
  String _maxLabel(ScoringSystem scoring) => switch (scoring) {
        ScoringSystem.point100 => '100',
        ScoringSystem.point10Decimal || ScoringSystem.point10 => '10',
        ScoringSystem.point5 => '5',
        ScoringSystem.point3 => '3',
      };
}
