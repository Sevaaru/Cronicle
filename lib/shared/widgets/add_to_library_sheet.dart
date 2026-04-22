import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/books/domain/book_progress_calculator.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/library/domain/anime_airing_progress.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
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

const _bookStatusData = [
  ('CURRENT', Icons.auto_stories_rounded),
  ('PLANNING', Icons.bookmark_add_outlined),
  ('COMPLETED', Icons.check_circle_outline),
  ('DROPPED', Icons.cancel_outlined),
  ('PAUSED', Icons.pause_circle_outline),
  ('REPEATING', Icons.replay_rounded),
];

SliderThemeData _m3ScoreSliderTheme(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final base = SliderTheme.of(context);
  return base.copyWith(
    trackHeight: 4,
    activeTrackColor: cs.primary,
    inactiveTrackColor: cs.surfaceContainerHighest,
    thumbColor: cs.primary,
    overlayColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.dragged) ||
          states.contains(WidgetState.pressed)) {
        return cs.primary.withAlpha(51);
      }
      return cs.primary.withAlpha(31);
    }),
    thumbShape: const RoundSliderThumbShape(
      enabledThumbRadius: 11,
      elevation: 1,
      pressedElevation: 3,
    ),
    trackShape: const RoundedRectSliderTrackShape(),
    valueIndicatorColor: cs.inverseSurface,
    valueIndicatorTextStyle: TextStyle(
      color: cs.onInverseSurface,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    showValueIndicator: ShowValueIndicator.onlyForContinuous,
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

Future<bool> showAddToLibrarySheet({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> item,
  required MediaKind kind,
  LibraryEntry? existingEntry,
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
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
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
    ref.invalidate(paginatedLibraryProvider);
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
  const _AddToLibrarySheet({required this.item, required this.kind, this.existingEntry});
  final Map<String, dynamic> item;
  final MediaKind kind;
  final LibraryEntry? existingEntry;

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

  bool get _isAnilist =>
      widget.kind == MediaKind.anime || widget.kind == MediaKind.manga;

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    _status = e?.status ?? 'PLANNING';
    final scoring = ref.read(scoringSystemSettingProvider);
    _score = scoring.fromStoredScore(e?.score);
    _progressCtrl = TextEditingController(text: '${e?.progress ?? 0}');
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
  }

  bool get _isManga => widget.kind == MediaKind.manga;
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
    final kindAccent = switch (widget.kind) {
      MediaKind.anime => cs.primary,
      MediaKind.manga => cs.secondary,
      MediaKind.movie => cs.tertiary,
      MediaKind.tv => cs.tertiary,
      MediaKind.game => cs.primary,
      MediaKind.book => cs.secondary,
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

    final isEdit = widget.existingEntry != null;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.32,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottomPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _SheetHeroHeader(
                posterUrl: posterUrl,
                title: name,
                kindLabel: kindLabel,
                kindIcon: kindIcon,
                kindAccent: kindAccent,
                isEdit: isEdit,
                titleLabel: isEdit ? l10n.editLibraryEntry : l10n.addToListTitle,
              ),
              if (_isBook && workKey != null && workKey.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(l10n.bookEditionLabel, style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                )),
                const SizedBox(height: 6),
                editionsAsync.when(
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
                          initialValue: editions.any((e) =>
                            (e['editionKey'] as String?) == _selectedEditionKey)
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
                ),
              ],
              const SizedBox(height: 20),

              _SectionLabel(text: l10n.addToListStatus),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusData.map((s) {
                  final selected = _status == s.$1;
                  return _StatusChip(
                    icon: s.$2,
                    label: _statusLabel(l10n, s.$1, widget.kind),
                    selected: selected,
                    accent: kindAccent,
                    onTap: () => setState(() => _status = s.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            key: ValueKey(_score > 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _score > 0
                                  ? Colors.amber.shade600.withValues(alpha: 0.18)
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _score > 0
                                  ? ref
                                      .watch(scoringSystemSettingProvider)
                                      .formatScore(_score)
                                  : l10n.addToListNoScore,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _score > 0
                                    ? Colors.amber.shade700
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: _m3ScoreSliderTheme(context),
                      child: Slider(
                        value: _score,
                        min: 0,
                        max: ref.watch(scoringSystemSettingProvider).max,
                        divisions:
                            ref.watch(scoringSystemSettingProvider).divisions,
                        label: _score == 0
                            ? l10n.addToListNoScore
                            : ref
                                .watch(scoringSystemSettingProvider)
                                .formatScore(_score),
                        onChanged: (v) => setState(() => _score = v),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isAnilist && ref.watch(anilistAdvancedScoringEnabledProvider)) ...[
                const SizedBox(height: 4),
                ...kAnilistAdvancedScoringCategories.map((cat) {
                  final scoring = ref.watch(scoringSystemSettingProvider);
                  final val = _advScores[cat] ?? 0;
                  final label = switch (cat) {
                    'Story' => l10n.advScoringStory,
                    'Characters' => l10n.advScoringCharacters,
                    'Visuals' => l10n.advScoringVisuals,
                    'Audio' => l10n.advScoringAudio,
                    'Enjoyment' => l10n.advScoringEnjoyment,
                    _ => cat,
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 85,
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: _m3ScoreSliderTheme(context).copyWith(
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
                              onChanged: (v) =>
                                  setState(() => _advScores[cat] = v),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 38,
                          child: Text(
                            scoring.formatScore(val),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: val > 0
                                    ? Colors.amber.shade600
                                    : cs.onSurfaceVariant),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 12),

              if (_isBook) ...[
                Text(l10n.bookTrackingModeLabel, style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                )),
                const SizedBox(height: 8),
                SegmentedButton<BookTrackingMode>(
                  segments: [
                    ButtonSegment(
                      value: BookTrackingMode.pages,
                      label: Text(l10n.bookTrackingModePages),
                      icon: const Icon(Icons.menu_book, size: 16),
                    ),
                    ButtonSegment(
                      value: BookTrackingMode.percentage,
                      label: Text(l10n.bookTrackingModePercent),
                      icon: const Icon(Icons.percent, size: 16),
                    ),
                    ButtonSegment(
                      value: BookTrackingMode.chapters,
                      label: Text(l10n.bookTrackingModeChapters),
                      icon: const Icon(Icons.list, size: 16),
                    ),
                  ],
                  selected: {_bookTrackingMode},
                  onSelectionChanged: (v) =>
                      setState(() => _bookTrackingMode = v.first),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              _ProgressStepper(
                label: countLabel,
                controller: _progressCtrl,
                totalCount: _totalCount,
                ofLabel: _totalCount != null
                    ? l10n.addToListOf(_totalCount!)
                    : null,
                maxLabel: l10n.addToListMax,
                accent: kindAccent,
                onMaxTapped: _totalCount == null
                    ? null
                    : () {
                        _progressCtrl.text = '$_totalCount';
                        setState(() => _status = 'COMPLETED');
                      },
              ),
              if (_isBook && _bookTrackingMode == BookTrackingMode.pages && _totalCount != null)
                Builder(builder: (_) {
                  final current = int.tryParse(_progressCtrl.text) ?? 0;
                  final remaining = _totalCount! - current;
                  if (remaining > 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.libraryPagesRemaining(remaining),
                        style: TextStyle(fontSize: 12, color: cs.primary.withAlpha(180)),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

              if (_isBook && _bookTrackingMode == BookTrackingMode.chapters) ...[
                const SizedBox(height: 12),
                _ProgressStepper(
                  label: l10n.bookChapterProgress,
                  controller: _chapterCtrl,
                  totalCount: int.tryParse(_totalChaptersOverrideCtrl.text),
                  ofLabel: null,
                  maxLabel: l10n.addToListMax,
                  accent: kindAccent,
                  onMaxTapped: null,
                ),
              ],

              if (_isBook) ...[
                const SizedBox(height: 12),
                Text(l10n.bookOverrideTotalsLabel, style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                )),
                const SizedBox(height: 4),
                Text(
                  l10n.bookOverrideTotalsHint,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withAlpha(160)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _totalPagesOverrideCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.bookTotalPagesOverride,
                          hintText: _totalPagesFromApi?.toString() ?? '',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _totalChaptersOverrideCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.bookTotalChaptersOverride,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 18),

              _SectionLabel(text: l10n.addToListNotes),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.addToListNotesHint,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  icon: Icon(isEdit ? Icons.save_rounded : Icons.check_rounded),
                  label: Text(l10n.addToListSave),
                  onPressed: () {
                    var progress = int.tryParse(_progressCtrl.text);
                    if (widget.kind == MediaKind.anime && progress != null) {
                      final max = AnimeAiringProgress.maxProgressForStoredAnime(
                            totalEpisodes: widget.existingEntry?.totalEpisodes ??
                                (widget.item['episodes'] as num?)?.toInt(),
                            releasedEpisodes: widget.existingEntry?.releasedEpisodes ??
                                AnimeAiringProgress.releasedEpisodesFromAnilistMedia(
                                    widget.item),
                          ) ??
                          AnimeAiringProgress.maxProgressForAnimeItem(widget.item);
                      if (max != null && progress > max) progress = max;
                    }
                    final notes = _notesCtrl.text.trim();
                    Navigator.of(context).pop(_AddResult(
                      status: _status,
                      score: _score > 0 ? ref.read(scoringSystemSettingProvider).toStoredScore(_score) : null,
                      progress: progress != null && progress > 0 ? progress : null,
                      notes: notes.isNotEmpty ? notes : null,
                      editionKey: _isBook ? _selectedEditionKey : null,
                      isbn: _isBook ? _selectedIsbn : null,
                      totalPagesFromApi: _isBook ? _totalPagesFromApi : null,
                      totalChaptersFromApi: _isBook ? _totalChaptersFromApi : null,
                      userTotalPagesOverride: _isBook
                          ? int.tryParse(_totalPagesOverrideCtrl.text)
                          : null,
                      userTotalChaptersOverride: _isBook
                          ? int.tryParse(_totalChaptersOverrideCtrl.text)
                          : null,
                      currentChapter: _isBook
                          ? (int.tryParse(_chapterCtrl.text) ?? 0) > 0
                              ? int.tryParse(_chapterCtrl.text)
                              : null
                          : null,
                      bookTrackingMode:
                          _isBook ? _bookTrackingMode.name : null,
                    ));
                  },
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: cs.errorContainer.withValues(alpha: 0.5),
                      foregroundColor: cs.onErrorContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: Text(l10n.removeFromLibrary),
                    onPressed: () => Navigator.of(context).pop(_AddResult.remove),
                  ),
                ),
              ],
            ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SheetHeroHeader extends StatelessWidget {
  const _SheetHeroHeader({
    required this.posterUrl,
    required this.title,
    required this.kindLabel,
    required this.kindIcon,
    required this.kindAccent,
    required this.isEdit,
    required this.titleLabel,
  });

  final String? posterUrl;
  final String title;
  final String kindLabel;
  final IconData kindIcon;
  final Color kindAccent;
  final bool isEdit;
  final String titleLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 56,
              height: 78,
              child: posterUrl != null
                  ? Image.network(
                      posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: cs.surfaceContainerHigh,
                        child: Icon(kindIcon,
                            color: cs.onSurfaceVariant, size: 28),
                      ),
                    )
                  : Container(
                      color: cs.surfaceContainerHigh,
                      child: Icon(kindIcon,
                          color: cs.onSurfaceVariant, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kindAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(kindIcon, size: 12, color: kindAccent),
                          const SizedBox(width: 4),
                          Text(
                            kindLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: kindAccent,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isEdit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.tertiaryContainer
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'EDIT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.onTertiaryContainer,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title.isNotEmpty ? title : titleLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? accent : cs.surfaceContainerHigh;
    final fg = selected ? cs.onPrimary : cs.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(selected ? 14 : 18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: (selected ? cs.onPrimary : accent)
              .withValues(alpha: 0.16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressStepper extends StatelessWidget {
  const _ProgressStepper({
    required this.label,
    required this.controller,
    required this.totalCount,
    required this.ofLabel,
    required this.maxLabel,
    required this.accent,
    required this.onMaxTapped,
  });

  final String label;
  final TextEditingController controller;
  final int? totalCount;
  final String? ofLabel;
  final String maxLabel;
  final Color accent;
  final VoidCallback? onMaxTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              if (ofLabel != null)
                Text(
                  ofLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  final c = int.tryParse(controller.text) ?? 0;
                  if (c > 0) controller.text = '${c - 1}';
                },
                cs: cs,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: () {
                  final c = int.tryParse(controller.text) ?? 0;
                  if (totalCount == null || c < totalCount!) {
                    controller.text = '${c + 1}';
                  }
                },
                cs: cs,
                accent: accent,
                filled: true,
              ),
            ],
          ),
          if (onMaxTapped != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onMaxTapped,
                icon: const Icon(Icons.flag_rounded, size: 16),
                label: Text(maxLabel),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.cs,
    this.accent,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;
  final Color? accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? (accent ?? cs.primary)
        : cs.surfaceContainerHighest;
    final fg = filled ? cs.onPrimary : cs.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Icon(icon, size: 22, color: fg)),
        ),
      ),
    );
  }
}
