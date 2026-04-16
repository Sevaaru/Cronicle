import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/trakt/data/trakt_library_remote_sync.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:drift/drift.dart' as drift;

const _animeStatusData = [
  ('CURRENT', Icons.play_arrow_rounded),
  ('PLANNING', Icons.bookmark_add_outlined),
  ('COMPLETED', Icons.check_circle_outline),
  ('DROPPED', Icons.cancel_outlined),
  ('PAUSED', Icons.pause_circle_outline),
  ('REPEATING', Icons.replay_rounded),
];

const _mangaStatusData = [
  ('CURRENT', Icons.auto_stories_rounded),
  ('PLANNING', Icons.bookmark_add_outlined),
  ('COMPLETED', Icons.check_circle_outline),
  ('DROPPED', Icons.cancel_outlined),
  ('PAUSED', Icons.pause_circle_outline),
  ('REPEATING', Icons.replay_rounded),
];

const _gameStatusData = [
  ('CURRENT', Icons.sports_esports_rounded),
  ('PLANNING', Icons.bookmark_add_outlined),
  ('COMPLETED', Icons.check_circle_outline),
  ('DROPPED', Icons.cancel_outlined),
  ('PAUSED', Icons.pause_circle_outline),
  ('REPEATING', Icons.replay_rounded),
];

String _statusLabel(AppLocalizations l10n, String key, MediaKind kind) {
  return switch (key) {
    'CURRENT' => switch (kind) {
        MediaKind.manga => l10n.statusCurrentManga,
        MediaKind.game => l10n.statusCurrentGame,
        _ => l10n.statusCurrentAnime,
      },
    'PLANNING' => l10n.statusPlanning,
    'COMPLETED' => l10n.statusCompleted,
    'DROPPED' => l10n.statusDropped,
    'PAUSED' => l10n.statusPaused,
    'REPEATING' => switch (kind) {
        MediaKind.game => l10n.statusReplayingGame,
        _ => l10n.statusRepeating,
      },
    _ => key,
  };
}

Future<bool> showAddToLibrarySheet({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> item,
  required MediaKind kind,
  LibraryEntry? existingEntry,
}) async {
  final db = ref.read(databaseProvider);

  if (kind == MediaKind.anime || kind == MediaKind.manga) {
    final prompted = await db.getKeyValue('anilist_prompt_shown');
    if (prompted == null && context.mounted) {
      final choice = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _AnilistPromptDialog(),
      );
      await db.setKeyValue('anilist_prompt_shown', 'true');

      if (choice == 'connect' && context.mounted) {
        final auth = ref.read(anilistAuthProvider);
        await launchUrl(
          Uri.parse(auth.authorizeUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  if (kind == MediaKind.game) {
    final prompted = await db.getKeyValue('twitch_prompt_shown');
    if (prompted == null && context.mounted) {
      await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _TwitchPromptDialog(),
      );
      await db.setKeyValue('twitch_prompt_shown', 'true');
    }
  }

  if (!context.mounted) return false;

  final result = await showModalBottomSheet<_AddResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddToLibrarySheet(item: item, kind: kind, existingEntry: existingEntry),
  );

  if (result == null) return false;

  if (result.deleted && existingEntry != null) {
    await db.deleteLibraryEntry(existingEntry.id);
    if (kind == MediaKind.anime || kind == MediaKind.manga) {
      _deleteEntryFromAnilist(ref, int.tryParse(existingEntry.externalId));
    }
    if (kind == MediaKind.movie || kind == MediaKind.tv) {
      final tid = int.tryParse(existingEntry.externalId);
      if (tid != null) {
        unawaited(removeTraktRemoteForDeletedEntry(ref, kind, tid));
      }
    }
    return true;
  }

  final title = item['title'] as Map<String, dynamic>? ?? {};
  final coverImage = item['coverImage'] as Map<String, dynamic>? ?? {};
  final mediaId = item['id'];

  await db.upsertLibraryEntry(
    LibraryEntriesCompanion(
      kind: drift.Value(kind.code),
      externalId: drift.Value(mediaId.toString()),
      title: drift.Value(
        (title['english'] as String?) ??
            (title['romaji'] as String?) ??
            (item['name'] as String?) ??
            'Unknown',
      ),
      posterUrl: drift.Value(
        (coverImage['extraLarge'] as String?) ??
            (coverImage['large'] as String?),
      ),
      status: drift.Value(result.status),
      score: drift.Value(result.score),
      progress: drift.Value(result.progress),
      totalEpisodes: drift.Value(
        kind == MediaKind.game
            ? null
            : kind == MediaKind.movie
                ? 1
                : kind == MediaKind.manga
                    ? (item['chapters'] as num?)?.toInt()
                    : (item['episodes'] as num?)?.toInt(),
      ),
      notes: drift.Value(result.notes),
      updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
    ),
  );

  if ((kind == MediaKind.anime || kind == MediaKind.manga) && mediaId != null) {
    _syncEntryToAnilist(ref, mediaId as int, result);
  }

  if ((kind == MediaKind.movie || kind == MediaKind.tv) && mediaId != null) {
    final tid = int.tryParse(mediaId.toString());
    if (tid != null) {
      unawaited(syncTraktEntryFromLocalDatabase(ref, kind, tid));
    }
  }

  return true;
}

void _deleteEntryFromAnilist(WidgetRef ref, int? mediaId) async {
  if (mediaId == null) return;
  try {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) return;
    final graphql = ref.read(anilistGraphqlProvider);
    final entryId = await graphql.findMediaListEntryId(mediaId, token);
    if (entryId != null) {
      await graphql.deleteMediaListEntry(entryId, token);
    } else if (kDebugMode) {
      debugPrint('[Cronicle] No Anilist entry found for mediaId=$mediaId');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('[Cronicle] Error deleting from Anilist: $e');
  }
}

void _syncEntryToAnilist(WidgetRef ref, int mediaId, _AddResult result) async {
  try {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) return;
    final graphql = ref.read(anilistGraphqlProvider);
    await graphql.saveMediaListEntry(
      mediaId: mediaId,
      token: token,
      status: result.status,
      score: result.score,
      progress: result.progress,
      notes: result.notes,
    );
  } catch (_) {}
}

class _AddResult {
  const _AddResult({
    required this.status,
    this.score,
    this.progress,
    this.notes,
    this.deleted = false,
  });
  final String status;
  final int? score;
  final int? progress;
  final String? notes;
  final bool deleted;

  static const remove = _AddResult(status: '', deleted: true);
}

class _AnilistPromptDialog extends StatelessWidget {
  const _AnilistPromptDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.sync_rounded, size: 40, color: cs.primary),
      title: Text(l10n.syncPromptTitle),
      content: Text(
        l10n.syncPromptBody,
        style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('skip'),
          child: Text(l10n.syncPromptNoThanks),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.login, size: 18),
          label: Text(l10n.anilistConnect),
          onPressed: () => Navigator.of(context).pop('connect'),
        ),
      ],
    );
  }
}

class _TwitchPromptDialog extends StatelessWidget {
  const _TwitchPromptDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.sports_esports_rounded, size: 40, color: cs.primary),
      title: Text(l10n.twitchSyncPromptTitle),
      content: Text(
        l10n.twitchSyncPromptBody,
        style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop('skip'),
          child: Text(l10n.twitchSyncPromptNoThanks),
        ),
      ],
    );
  }
}

class _AddToLibrarySheet extends StatefulWidget {
  const _AddToLibrarySheet({required this.item, required this.kind, this.existingEntry});
  final Map<String, dynamic> item;
  final MediaKind kind;
  final LibraryEntry? existingEntry;

  @override
  State<_AddToLibrarySheet> createState() => _AddToLibrarySheetState();
}

class _AddToLibrarySheetState extends State<_AddToLibrarySheet> {
  late String _status;
  late double _score;
  late final TextEditingController _progressCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    _status = e?.status ?? 'PLANNING';
    _score = (e?.score ?? 0).toDouble();
    if (_score > 10) _score = _score / 10;
    _progressCtrl = TextEditingController(text: '${e?.progress ?? 0}');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
  }

  bool get _isManga => widget.kind == MediaKind.manga;
  bool get _isGame => widget.kind == MediaKind.game;
  bool get _isMovie => widget.kind == MediaKind.movie;

  List<(String, IconData)> get _statusData => switch (widget.kind) {
        MediaKind.manga => _mangaStatusData,
        MediaKind.game => _gameStatusData,
        _ => _animeStatusData,
      };

  int? get _totalCount => _isGame
      ? null
      : _isMovie
          ? 1
          : _isManga
              ? widget.item['chapters'] as int?
              : widget.item['episodes'] as int?;

  @override
  void dispose() {
    _progressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final title = widget.item['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        '';
    final countLabel = _isGame
        ? l10n.addToListHoursPlayed
        : _isManga
            ? l10n.addToListChapters
            : _isMovie
                ? l10n.addToListMovieProgress
                : l10n.addToListEpisodes;

    final isEdit = widget.existingEntry != null;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isEdit ? l10n.editLibraryEntry : l10n.addToListTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              Text(l10n.addToListStatus, style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusData.map((s) {
                  final selected = _status == s.$1;
                  return ChoiceChip(
                    selected: selected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.$2, size: 16),
                        const SizedBox(width: 4),
                        Text(_statusLabel(l10n, s.$1, widget.kind)),
                      ],
                    ),
                    onSelected: (_) => setState(() => _status = s.$1),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Text(l10n.addToListScore, style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  )),
                  const Spacer(),
                  Text(
                    _score == 0 ? '—' : '${_score.round()}/10',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _score > 0 ? Colors.amber.shade600 : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _score,
                min: 0,
                max: 10,
                divisions: 10,
                label: _score == 0 ? l10n.addToListNoScore : '${_score.round()}',
                onChanged: (v) => setState(() => _score = v),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Text(countLabel, style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  )),
                  const Spacer(),
                  if (_totalCount != null)
                    Text(
                      l10n.addToListOf(_totalCount!),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      final current = int.tryParse(_progressCtrl.text) ?? 0;
                      if (current > 0) {
                        _progressCtrl.text = '${current - 1}';
                      }
                    },
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _progressCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      final current = int.tryParse(_progressCtrl.text) ?? 0;
                      final max = _totalCount;
                      if (max == null || current < max) {
                        _progressCtrl.text = '${current + 1}';
                      }
                    },
                  ),
                  if (_totalCount != null) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _progressCtrl.text = '$_totalCount';
                        setState(() => _status = 'COMPLETED');
                      },
                      child: Text(l10n.addToListMax, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              Text(l10n.addToListNotes, style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              )),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.addToListNotesHint,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(l10n.addToListSave),
                  onPressed: () {
                    final progress = int.tryParse(_progressCtrl.text);
                    final notes = _notesCtrl.text.trim();
                    Navigator.of(context).pop(_AddResult(
                      status: _status,
                      score: _score > 0 ? _score.round() : null,
                      progress: progress != null && progress > 0 ? progress : null,
                      notes: notes.isNotEmpty ? notes : null,
                    ));
                  },
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    label: Text(l10n.removeFromLibrary, style: TextStyle(color: cs.error)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: cs.error.withAlpha(120))),
                    onPressed: () => Navigator.of(context).pop(_AddResult.remove),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
