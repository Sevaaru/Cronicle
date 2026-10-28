import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/widget/home_widget_bridge.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/books/domain/book_progress_calculator.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/library/domain/anime_airing_progress.dart';
import 'package:cronicle/features/library/domain/repeat_count_rules.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/trakt/data/trakt_library_remote_sync.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/library_entry_sheet_parts.dart';
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
  ('PLAYED', Icons.done_all_rounded),
  ('DROPPED', Icons.cancel_outlined),
  ('PAUSED', Icons.pause_circle_outline),
  ('REPEATING', Icons.replay_rounded),
];

const _bookStatusData = [
  ('CURRENT', Icons.auto_stories_rounded),
  ('PLANNING', Icons.bookmark_add_outlined),
  ('COMPLETED', Icons.check_circle_outline),
  ('DROPPED', Icons.cancel_outlined),
  ('PAUSED', Icons.pause_circle_outline),
  ('REPEATING', Icons.replay_rounded),
];

SliderThemeData _m3ScoreSliderTheme(BuildContext context, Color color) {
  final cs = Theme.of(context).colorScheme;
  final base = SliderTheme.of(context);
  return base.copyWith(
    trackHeight: 6,
    activeTrackColor: color,
    inactiveTrackColor: cs.surfaceContainerHighest,
    thumbColor: color,
    overlayColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.dragged) ||
          states.contains(WidgetState.pressed)) {
        return color.withAlpha(51);
      }
      return color.withAlpha(31);
    }),
    thumbShape: const RoundSliderThumbShape(
      enabledThumbRadius: 13,
      elevation: 2,
      pressedElevation: 6,
    ),
    trackShape: const RoundedRectSliderTrackShape(),
    valueIndicatorColor: cs.inverseSurface,
    valueIndicatorTextStyle: TextStyle(
      color: cs.onInverseSurface,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    showValueIndicator: ShowValueIndicator.always,
  );
}

String _statusLabel(AppLocalizations l10n, String key, MediaKind kind) {
  return switch (key) {
    'CURRENT' => switch (kind) {
        MediaKind.manga => l10n.statusCurrentManga,
        MediaKind.game => l10n.statusCurrentGame,
        MediaKind.book => l10n.statusCurrentBook,
        _ => l10n.statusCurrentAnime,
      },
    'PLANNING' => l10n.statusPlanning,
    'COMPLETED' => l10n.statusCompleted,
    'PLAYED' => l10n.statusPlayedGame,
    'DROPPED' => l10n.statusDropped,
    'PAUSED' => l10n.statusPaused,
    'REPEATING' => switch (kind) {
        MediaKind.game => l10n.statusReplayingGame,
        MediaKind.book => l10n.statusRereadingBook,
        _ => l10n.statusRepeating,
      },
    _ => key,
  };
}

String _repeatLabel(AppLocalizations l10n, MediaKind kind) => switch (kind) {
      MediaKind.manga || MediaKind.book => l10n.addToListRepeatRead,
      MediaKind.game => l10n.addToListRepeatPlay,
      _ => l10n.addToListRepeatWatch,
    };

Future<bool> showAddToLibrarySheet({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> item,
  required MediaKind kind,
  LibraryEntry? existingEntry,
  int? initialProgress,
  /// Set to true when the calling page is inside the ShellRoute so the sheet
  /// is pushed on the root navigator. This lets GoRouter's back-button handler
  /// see the sheet and close it instead of popping the page underneath.
  bool useRootNavigator = false,
  /// Steam app ID — stored on the library entry so the app can open the
  /// Steam detail view from the library later. Pass only when adding/editing
  /// a game that was found via the Steam library pages.
  int? steamAppId,
}) async {
  final db = ref.read(databaseProvider);

  if (kind == MediaKind.anime || kind == MediaKind.manga) {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null || token.isEmpty) {
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
  }

  if (!context.mounted) return false;

  final result = await showModalBottomSheet<_AddResult>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AddToLibrarySheet(item: item, kind: kind, existingEntry: existingEntry, initialProgress: initialProgress),
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
    ref.invalidate(paginatedLibraryProvider);
    unawaited(HomeWidgetBridge.refresh());
    return true;
  }

  final title = item['title'] as Map<String, dynamic>? ?? {};
  final coverImage = item['coverImage'] as Map<String, dynamic>? ?? {};
  final mediaId = item['id'];
  final bookExternalId = kind == MediaKind.book
      ? (item['workKey'] as String? ?? mediaId.toString())
      : mediaId.toString();

  await db.upsertLibraryEntry(
    LibraryEntriesCompanion(
      kind: drift.Value(kind.code),
      externalId: drift.Value(bookExternalId),
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
      repeatCount: drift.Value(result.repeatCount),
      totalEpisodes: drift.Value(
        kind == MediaKind.game
            ? null
            : kind == MediaKind.movie
                ? 1
                : kind == MediaKind.book
                    ? (item['pages'] as num?)?.toInt()
                    : kind == MediaKind.manga
                        ? (item['chapters'] as num?)?.toInt()
                        : (item['episodes'] as num?)?.toInt(),
      ),
      animeMediaStatus: drift.Value(
        kind == MediaKind.anime ? item['status'] as String? : null,
      ),
      releasedEpisodes: drift.Value(
        kind == MediaKind.anime
            ? AnimeAiringProgress.releasedEpisodesFromAnilistMedia(item)
            : null,
      ),
      nextEpisodeAirsAt: drift.Value(
        kind == MediaKind.anime
            ? AnimeAiringProgress.nextEpisodeAirsAtSecondsFromAnilistMedia(item)
            : null,
      ),
      notes: drift.Value(result.notes),
      editionKey: drift.Value(result.editionKey),
      isbn: drift.Value(result.isbn),
      totalPagesFromApi: drift.Value(result.totalPagesFromApi),
      totalChaptersFromApi: drift.Value(result.totalChaptersFromApi),
      userTotalPagesOverride: drift.Value(result.userTotalPagesOverride),
      userTotalChaptersOverride: drift.Value(result.userTotalChaptersOverride),
      currentChapter: drift.Value(result.currentChapter),
      bookTrackingMode: drift.Value(result.bookTrackingMode),
      steamAppId: steamAppId != null
          ? drift.Value(steamAppId)
          : const drift.Value.absent(),
      updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
    ),
  );

  if ((kind == MediaKind.anime || kind == MediaKind.manga) && mediaId != null) {
    _syncEntryToAnilist(ref, mediaId as int, result);
  }

  if (kind == MediaKind.anime && mediaId != null) {
    unawaited(_enrichAnimeAiringAfterSave(ref, mediaId as int));
  }

  if ((kind == MediaKind.movie || kind == MediaKind.tv) && mediaId != null) {
    final tid = int.tryParse(mediaId.toString());
    if (tid != null) {
      unawaited(syncTraktEntryFromLocalDatabase(ref, kind, tid));
    }
  }

  ref.invalidate(paginatedLibraryProvider);
  unawaited(HomeWidgetBridge.refresh());
  return true;
}

Future<void> _enrichAnimeAiringAfterSave(WidgetRef ref, int mediaId) async {
  try {
    final db = ref.read(databaseProvider);
    final g = ref.read(anilistGraphqlProvider);
    final detail = await g.fetchMediaDetail(mediaId);
    if (detail == null) return;
    final entry = await db.getLibraryEntryByKindAndExternalId(
      MediaKind.anime.code,
      '$mediaId',
    );
    if (entry == null) return;
    final rel = AnimeAiringProgress.releasedEpisodesFromAnilistMedia(detail);
    final st = detail['status'] as String?;
    final airAt =
        AnimeAiringProgress.nextEpisodeAirsAtSecondsFromAnilistMedia(detail);
    await db.updateAnimeAiringMetadata(
      id: entry.id,
      animeMediaStatus: st,
      releasedEpisodes: rel,
      nextEpisodeAirsAt: airAt,
    );
  } catch (_) {}
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
      repeat: result.repeatCount,
    );
  } catch (_) {}
}

class _AddResult {
  const _AddResult({
    required this.status,
    this.score,
    this.progress,
    this.repeatCount = 0,
    this.notes,
    this.deleted = false,
    this.editionKey,
    this.isbn,
    this.totalPagesFromApi,
    this.totalChaptersFromApi,
    this.userTotalPagesOverride,
    this.userTotalChaptersOverride,
    this.currentChapter,
    this.bookTrackingMode,
  });
  final String status;
  final int? score;
  final int? progress;
  final int repeatCount;
  final String? notes;
  final bool deleted;
  final String? editionKey;
  final String? isbn;
  final int? totalPagesFromApi;
  final int? totalChaptersFromApi;
  final int? userTotalPagesOverride;
  final int? userTotalChaptersOverride;
  final int? currentChapter;
  final String? bookTrackingMode;

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

class _AddToLibrarySheet extends ConsumerStatefulWidget {
  const _AddToLibrarySheet({required this.item, required this.kind, this.existingEntry, this.initialProgress});
  final Map<String, dynamic> item;
  final MediaKind kind;
  final LibraryEntry? existingEntry;
  final int? initialProgress;

  @override
  ConsumerState<_AddToLibrarySheet> createState() => _AddToLibrarySheetState();
}

class _AddToLibrarySheetState extends ConsumerState<_AddToLibrarySheet> {
  late String _status;
  late double _score;
  late final TextEditingController _progressCtrl;
  late final TextEditingController _notesCtrl;
  late final Map<String, double> _advScores;

  late BookTrackingMode _bookTrackingMode;
  late final TextEditingController _chapterCtrl;
  late final TextEditingController _totalPagesOverrideCtrl;
  late final TextEditingController _totalChaptersOverrideCtrl;
  String? _selectedEditionKey;
  String? _selectedIsbn;
  int? _totalPagesFromApi;
  int? _totalChaptersFromApi;
  late int _repeatCount;
  bool _repeatAutoBumped = false;

  bool get _isAnilist =>
      widget.kind == MediaKind.anime || widget.kind == MediaKind.manga;

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    _status = e?.status ?? 'PLANNING';
    final scoring = ref.read(scoringSystemSettingProvider);
    _score = scoring.fromStoredScore(e?.score);
    final initialProg = e?.progress ?? widget.initialProgress ?? 0;
    _progressCtrl = TextEditingController(text: '$initialProg');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _advScores = {for (final c in kAnilistAdvancedScoringCategories) c: 0};

    _bookTrackingMode = e != null
        ? BookTrackingMode.fromString(e.bookTrackingMode)
        : BookTrackingMode.pages;
    _chapterCtrl = TextEditingController(text: '${e?.currentChapter ?? 0}');
    _totalPagesOverrideCtrl = TextEditingController(
        text: e?.userTotalPagesOverride?.toString() ?? '');
    _totalChaptersOverrideCtrl = TextEditingController(
        text: e?.userTotalChaptersOverride?.toString() ?? '');
    _selectedEditionKey = e?.editionKey;
    _selectedIsbn = e?.isbn;
    _totalPagesFromApi = e?.totalPagesFromApi ?? (widget.item['pages'] as num?)?.toInt();
    _totalChaptersFromApi = e?.totalChaptersFromApi;
    _repeatCount = e?.repeatCount ?? 0;
  }

  void _selectStatus(String next) {
    final r = RepeatCountRules.onEditorStatusChange(
      fromStatus: _status,
      toStatus: next,
      count: _repeatCount,
      autoBumped: _repeatAutoBumped,
    );
    setState(() {
      _status = next;
      _repeatCount = r.count;
      _repeatAutoBumped = r.autoBumped;
    });
  }

  bool get _isManga => widget.kind == MediaKind.manga;

  void _onScoreChanged(double v) {
    HapticFeedback.selectionClick();
    setState(() => _score = v);
  }

  double _parseScoreInput(String text, ScoringSystem scoring) {
    final raw =
        double.tryParse(text.trim().replaceAll(',', '.')) ?? _score;
    final clamped = raw.clamp(0.0, scoring.max);
    return switch (scoring) {
      ScoringSystem.point10Decimal =>
        (clamped * 10).round() / 10.0,
      _ => clamped.roundToDouble(),
    };
  }

  Future<void> _editScoreViaKeyboard(BuildContext context) async {
    final scoring = ref.read(scoringSystemSettingProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDecimal = scoring == ScoringSystem.point10Decimal;
    final ctrl = TextEditingController(
      text: _score > 0
          ? (isDecimal
              ? _score.toStringAsFixed(1)
              : _score.round().toString())
          : '',
    );
    final rangeHint = isDecimal
        ? '0.0 – ${scoring.max.toStringAsFixed(1)}'
        : '0 – ${scoring.max.round()}';

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star_rounded,
                color: Colors.amber.shade600, size: 22),
            const SizedBox(width: 8),
            Text(l10n.addToListScore),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(
              decimal: isDecimal),
          decoration: InputDecoration(
            hintText: rangeHint,
            suffixText: isDecimal
                ? '/ ${scoring.max.toStringAsFixed(1)}'
                : '/ ${scoring.max.round()}',
          ),
          onSubmitted: (_) {
            final v = _parseScoreInput(ctrl.text, scoring);
            Navigator.of(ctx).pop(v);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(0.0),
            child: Text(l10n.addToListNoScore),
          ),
          FilledButton(
            onPressed: () {
              final v = _parseScoreInput(ctrl.text, scoring);
              Navigator.of(ctx).pop(v);
            },
            child: Text(l10n.scoreSet),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      HapticFeedback.lightImpact();
      setState(() => _score = result);
    }
  }
  bool get _isGame => widget.kind == MediaKind.game;
  bool get _isMovie => widget.kind == MediaKind.movie;
  bool get _isBook => widget.kind == MediaKind.book;

  List<(String, IconData)> get _statusData => switch (widget.kind) {
        MediaKind.manga => _mangaStatusData,
        MediaKind.game => _gameStatusData,
        MediaKind.book => _bookStatusData,
        _ => _animeStatusData,
      };

  int? get _totalCount => _isGame
      ? null
      : _isMovie
          ? 1
          : _isBook
              ? _bookEffectiveTotal
              : _isManga
                  ? widget.item['chapters'] as int?
                  : widget.kind == MediaKind.anime
                      ? (AnimeAiringProgress.maxProgressForStoredAnime(
                            totalEpisodes: widget.existingEntry?.totalEpisodes ??
                                (widget.item['episodes'] as num?)?.toInt(),
                            releasedEpisodes: widget.existingEntry?.releasedEpisodes ??
                                AnimeAiringProgress.releasedEpisodesFromAnilistMedia(
                                    widget.item),
                          ) ??
                          AnimeAiringProgress.maxProgressForAnimeItem(widget.item))
                      : widget.item['episodes'] as int?;

  int? get _bookEffectiveTotal {
    switch (_bookTrackingMode) {
      case BookTrackingMode.pages:
        final override = int.tryParse(_totalPagesOverrideCtrl.text);
        return override ?? _totalPagesFromApi;
      case BookTrackingMode.percentage:
        return 100;
      case BookTrackingMode.chapters:
        final override = int.tryParse(_totalChaptersOverrideCtrl.text);
        return override ?? _totalChaptersFromApi;
    }
  }

  String _bookProgressLabel(AppLocalizations l10n) => switch (_bookTrackingMode) {
        BookTrackingMode.pages => l10n.addToListPagesRead,
        BookTrackingMode.percentage => l10n.bookPercentageRead,
        BookTrackingMode.chapters => l10n.addToListChapters,
      };

  void _syncEditionSelection(List<Map<String, dynamic>> editions) {
    if (editions.isEmpty) return;
    Map<String, dynamic>? selected;

    if (_selectedEditionKey != null && _selectedEditionKey!.isNotEmpty) {
      for (final e in editions) {
        if ((e['editionKey'] as String?) == _selectedEditionKey) {
          selected = e;
          break;
        }
      }
    }

    selected ??= editions.firstWhere(
      (e) => (e['pages'] as num?)?.toInt() != null,
      orElse: () => editions.first,
    );

    final key = selected['editionKey'] as String?;
    final isbn = selected['isbn'] as String?;
    final pages = (selected['pages'] as num?)?.toInt();
    final chapters = (selected['chapters'] as num?)?.toInt();

    final changed = _selectedEditionKey != key ||
        _selectedIsbn != isbn ||
        _totalPagesFromApi != pages ||
        _totalChaptersFromApi != chapters;
    if (!changed) return;

    setState(() {
      _selectedEditionKey = key;
      _selectedIsbn = isbn;
      _totalPagesFromApi = pages;
      _totalChaptersFromApi = chapters;
    });
  }

  String _editionLabel(Map<String, dynamic> e, AppLocalizations l10n) {
    final title = (e['title'] as String?)?.trim();
    final key = e['editionKey'] as String?;
    final pages = (e['pages'] as num?)?.toInt();
    final base = (title != null && title.isNotEmpty)
        ? title
        : (key != null && key.isNotEmpty)
            ? key
            : 'Edition';
    final pagesLabel = pages != null
        ? l10n.bookDetailPages(pages)
        : l10n.bookEditionUnknownPages;
    return '$base • $pagesLabel';
  }


  @override
  void dispose() {
    _progressCtrl.dispose();
    _notesCtrl.dispose();
    _chapterCtrl.dispose();
    _totalPagesOverrideCtrl.dispose();
    _totalChaptersOverrideCtrl.dispose();
    super.dispose();
  }

  void _save() {
    var progress = int.tryParse(_progressCtrl.text);
    if (widget.kind == MediaKind.anime && progress != null) {
      final max = AnimeAiringProgress.maxProgressForStoredAnime(
            totalEpisodes: widget.existingEntry?.totalEpisodes ??
                (widget.item['episodes'] as num?)?.toInt(),
            releasedEpisodes: widget.existingEntry?.releasedEpisodes ??
                AnimeAiringProgress.releasedEpisodesFromAnilistMedia(widget.item),
          ) ??
          AnimeAiringProgress.maxProgressForAnimeItem(widget.item);
      if (max != null && progress > max) progress = max;
    }
    final notes = _notesCtrl.text.trim();
    final chapter = int.tryParse(_chapterCtrl.text) ?? 0;
    Navigator.of(context).pop(_AddResult(
      status: _status,
      score: _score > 0
          ? ref.read(scoringSystemSettingProvider).toStoredScore(_score)
          : null,
      progress: progress != null && progress > 0 ? progress : null,
      repeatCount: _repeatCount,
      notes: notes.isNotEmpty ? notes : null,
      editionKey: _isBook ? _selectedEditionKey : null,
      isbn: _isBook ? _selectedIsbn : null,
      totalPagesFromApi: _isBook ? _totalPagesFromApi : null,
      totalChaptersFromApi: _isBook ? _totalChaptersFromApi : null,
      userTotalPagesOverride:
          _isBook ? int.tryParse(_totalPagesOverrideCtrl.text) : null,
      userTotalChaptersOverride:
          _isBook ? int.tryParse(_totalChaptersOverrideCtrl.text) : null,
      currentChapter: _isBook && chapter > 0 ? chapter : null,
      bookTrackingMode: _isBook ? _bookTrackingMode.name : null,
    ));
  }

  Future<void> _confirmRemove(String name) async {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: cs.error),
        title: Text(l10n.removeFromLibrary),
        content: name.isEmpty ? null : Text(name, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(material.cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.removeFromLibrary),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop(_AddResult.remove);
  }

  Widget _editionPicker(
    AppLocalizations l10n,
    ColorScheme cs,
    AsyncValue<List<Map<String, dynamic>>> editionsAsync,
  ) {
    return editionsAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, _) => Text(
        l10n.bookEditionUnknownPages,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      data: (editions) {
        if (editions.isEmpty) {
          return Text(
            l10n.bookEditionNoPageHint,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncEditionSelection(editions);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: editions.any(
                      (e) => (e['editionKey'] as String?) == _selectedEditionKey)
                  ? _selectedEditionKey
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              hint: Text(l10n.bookEditionLabel),
              items: editions.map((e) {
                final key = e['editionKey'] as String? ?? '';
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text(
                    _editionLabel(e, l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                final selected = editions.firstWhere(
                  (e) => (e['editionKey'] as String?) == value,
                );
                _syncEditionSelection([selected]);
              },
            ),
            const SizedBox(height: 4),
            Text(
              l10n.bookEditionNoPageHint,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        );
      },
    );
  }

  Widget _advancedScores(AppLocalizations l10n, ColorScheme cs, Color gold) {
    final scoring = ref.watch(scoringSystemSettingProvider);
    return Column(
      children: kAnilistAdvancedScoringCategories.map((cat) {
        final val = _advScores[cat] ?? 0;
        final label = switch (cat) {
          'Story' => l10n.advScoringStory,
          'Characters' => l10n.advScoringCharacters,
          'Visuals' => l10n.advScoringVisuals,
          'Audio' => l10n.advScoringAudio,
          'Enjoyment' => l10n.advScoringEnjoyment,
          _ => cat,
        };
        return Row(
          children: [
            SizedBox(
              width: 85,
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: _m3ScoreSliderTheme(context, gold).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                    elevation: 1,
                    pressedElevation: 2,
                  ),
                ),
                child: Slider(
                  value: val,
                  min: 0,
                  max: scoring.max,
                  divisions: scoring.divisions,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _advScores[cat] = v);
                  },
                ),
              ),
            ),
            SizedBox(
              width: 38,
              child: Text(
                scoring.formatScore(val),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: val > 0 ? gold : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  InputDecoration _fieldDecoration(ColorScheme cs, {String? label, String? hint}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final workKey = widget.item['workKey'] as String?;
    final editionsAsync = _isBook && workKey != null && workKey.isNotEmpty
        ? ref.watch(bookWorkEditionsProvider(workKey))
        : const AsyncData<List<Map<String, dynamic>>>([]);
    final title = widget.item['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        (widget.item['name'] as String?) ??
        '';
    final coverImage = widget.item['coverImage'] as Map<String, dynamic>? ?? {};
    final posterUrl = (coverImage['extraLarge'] as String?) ??
        (coverImage['large'] as String?) ??
        (coverImage['medium'] as String?) ??
        widget.existingEntry?.posterUrl;
    final kindLabel = switch (widget.kind) {
      MediaKind.anime => l10n.mediaKindAnime,
      MediaKind.manga => l10n.mediaKindManga,
      MediaKind.movie => l10n.mediaKindMovie,
      MediaKind.tv => l10n.mediaKindTv,
      MediaKind.game => l10n.mediaKindGame,
      MediaKind.book => l10n.mediaKindBook,
    };
    final kindIcon = switch (widget.kind) {
      MediaKind.anime => Icons.animation_rounded,
      MediaKind.manga => Icons.menu_book_rounded,
      MediaKind.movie => Icons.movie_rounded,
      MediaKind.tv => Icons.live_tv_rounded,
      MediaKind.game => Icons.sports_esports_rounded,
      MediaKind.book => Icons.auto_stories_rounded,
    };
    final countLabel = _isGame
        ? l10n.addToListHoursPlayed
        : _isBook
            ? _bookProgressLabel(l10n)
            : _isManga
                ? l10n.addToListChapters
                : _isMovie
                    ? l10n.addToListMovieProgress
                    : l10n.addToListEpisodes;
    final accent = entryKindAccent(widget.kind);
    final gold = Colors.amber.shade500;
    final scoring = ref.watch(scoringSystemSettingProvider);
    final isEdit = widget.existingEntry != null;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final total = _totalCount;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.96,
        builder: (context, scrollController) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  CartridgeHeader(
                    title: name.isNotEmpty
                        ? name
                        : (isEdit ? l10n.editLibraryEntry : l10n.addToListTitle),
                    kindLabel: kindLabel,
                    kindIcon: kindIcon,
                    accent: accent,
                    badge: isEdit
                        ? l10n.entrySheetEditBadge
                        : l10n.entrySheetNewBadge,
                    posterUrl: posterUrl,
                  ),
                  const SizedBox(height: 18),
                  if (_isBook && workKey != null && workKey.isNotEmpty)
                    CartridgeSection(
                      icon: Icons.library_books_rounded,
                      title: l10n.bookEditionLabel,
                      child: _editionPicker(l10n, cs, editionsAsync),
                    ),
                  CartridgeSection(
                    icon: Icons.bolt_rounded,
                    title: l10n.addToListStatus,
                    child: CartridgeStatusGrid(
                      options: [
                        for (final s in _statusData)
                          (
                            key: s.$1,
                            icon: s.$2,
                            label: _statusLabel(l10n, s.$1, widget.kind),
                          ),
                      ],
                      selected: _status,
                      accent: accent,
                      onSelect: _selectStatus,
                    ),
                  ),
                  if (_isBook)
                    CartridgeSection(
                      icon: Icons.tune_rounded,
                      title: l10n.bookTrackingModeLabel,
                      child: CartridgeStatusGrid(
                        options: [
                          (
                            key: BookTrackingMode.pages.name,
                            icon: Icons.menu_book_rounded,
                            label: l10n.bookTrackingModePages,
                          ),
                          (
                            key: BookTrackingMode.percentage.name,
                            icon: Icons.percent_rounded,
                            label: l10n.bookTrackingModePercent,
                          ),
                          (
                            key: BookTrackingMode.chapters.name,
                            icon: Icons.format_list_numbered_rounded,
                            label: l10n.bookTrackingModeChapters,
                          ),
                        ],
                        selected: _bookTrackingMode.name,
                        accent: accent,
                        onSelect: (k) => setState(
                          () => _bookTrackingMode = BookTrackingMode.values.byName(k),
                        ),
                      ),
                    ),
                  CartridgeSection(
                    icon: _isGame ? Icons.timer_rounded : Icons.speed_rounded,
                    title: countLabel,
                    child: CartridgeCounter(
                      controller: _progressCtrl,
                      accent: accent,
                      title: countLabel,
                      tapHint: l10n.entrySheetTapToType,
                      max: total,
                      maxLabel: l10n.addToListMax,
                      onMax: total == null
                          ? null
                          : () {
                              _progressCtrl.text = '$total';
                              _selectStatus('COMPLETED');
                            },
                      footer: _isBook &&
                              _bookTrackingMode == BookTrackingMode.pages &&
                              total != null
                          ? (current) => total - current > 0
                              ? Text(
                                  l10n.libraryPagesRemaining(total - current),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                )
                              : const SizedBox()
                          : null,
                    ),
                  ),
                  if (_isBook && _bookTrackingMode == BookTrackingMode.chapters)
                    CartridgeSection(
                      icon: Icons.format_list_numbered_rounded,
                      title: l10n.bookChapterProgress,
                      child: CartridgeCounter(
                        controller: _chapterCtrl,
                        accent: accent,
                        title: l10n.bookChapterProgress,
                        tapHint: l10n.entrySheetTapToType,
                        max: int.tryParse(_totalChaptersOverrideCtrl.text),
                      ),
                    ),
                  CartridgeSection(
                    icon: Icons.replay_rounded,
                    title: _repeatLabel(l10n, widget.kind),
                    child: CartridgeRepeatStamps(
                      count: _repeatCount,
                      accent: accent,
                      summary: l10n.addToListRepeatSummary(_repeatCount),
                      hint: l10n.addToListRepeatHint,
                      onChanged: (v) => setState(() {
                        _repeatCount = v;
                        _repeatAutoBumped = false;
                      }),
                    ),
                  ),
                  CartridgeSection(
                    icon: Icons.star_rounded,
                    title: l10n.addToListScore,
                    child: Column(
                      children: [
                        CartridgeScoreStars(
                          value: _score,
                          scoring: scoring,
                          emptyLabel: l10n.addToListNoScore,
                          onChanged: (v) => setState(() => _score = v),
                          onTapNumber: () => _editScoreViaKeyboard(context),
                        ),
                        SliderTheme(
                          data: _m3ScoreSliderTheme(context, gold),
                          child: Slider(
                            value: _score,
                            min: 0,
                            max: scoring.max,
                            divisions: scoring.divisions,
                            label: _score == 0
                                ? l10n.addToListNoScore
                                : scoring.formatScore(_score),
                            onChanged: _onScoreChanged,
                          ),
                        ),
                        if (_isAnilist &&
                            ref.watch(anilistAdvancedScoringEnabledProvider))
                          _advancedScores(l10n, cs, gold),
                      ],
                    ),
                  ),
                  if (_isBook)
                    CartridgeSection(
                      icon: Icons.edit_note_rounded,
                      title: l10n.bookOverrideTotalsLabel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.bookOverrideTotalsHint,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _totalPagesOverrideCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _fieldDecoration(
                                    cs,
                                    label: l10n.bookTotalPagesOverride,
                                    hint: _totalPagesFromApi?.toString() ?? '',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _totalChaptersOverrideCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _fieldDecoration(
                                    cs,
                                    label: l10n.bookTotalChaptersOverride,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  CartridgeSection(
                    icon: Icons.sticky_note_2_rounded,
                    title: l10n.addToListNotes,
                    child: TextField(
                      controller: _notesCtrl,
                      minLines: 2,
                      maxLines: 5,
                      decoration: _fieldDecoration(cs, hint: l10n.addToListNotesHint),
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: cs.outlineVariant.withAlpha(90)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8 + bottomPad),
                child: Row(
                  children: [
                    if (isEdit) ...[
                      ChunkyButton(
                        color: cs.errorContainer,
                        foreground: cs.onErrorContainer,
                        padding: const EdgeInsets.all(14),
                        tooltip: l10n.removeFromLibrary,
                        onTap: () => _confirmRemove(name),
                        child: const Icon(Icons.delete_outline_rounded),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ChunkyButton(
                        color: accent,
                        depth: 5,
                        radius: 16,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        onTap: _save,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isEdit
                                ? Icons.save_rounded
                                : Icons.sim_card_download_rounded),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isEdit ? l10n.addToListSave : l10n.entrySheetInsert,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
