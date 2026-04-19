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
      // Book-specific fields
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
    // Book-specific
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
  // Book-specific
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

  // Book-specific state
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

    // Book-specific init
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

  /// For books, the effective total depends on the tracking mode.
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
        '';
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
                    ref.watch(scoringSystemSettingProvider).formatScore(_score),
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
                max: ref.watch(scoringSystemSettingProvider).max,
                divisions: ref.watch(scoringSystemSettingProvider).divisions,
                label: _score == 0 ? l10n.addToListNoScore : ref.watch(scoringSystemSettingProvider).formatScore(_score),
                onChanged: (v) => setState(() => _score = v),
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
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
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

              // Book tracking mode selector
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

              // Book chapter tracking (shown when mode == chapters)
              if (_isBook && _bookTrackingMode == BookTrackingMode.chapters) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(l10n.bookChapterProgress, style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    )),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        final c = int.tryParse(_chapterCtrl.text) ?? 0;
                        if (c > 0) _chapterCtrl.text = '${c - 1}';
                      },
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _chapterCtrl,
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
                        final c = int.tryParse(_chapterCtrl.text) ?? 0;
                        final max = int.tryParse(_totalChaptersOverrideCtrl.text);
                        if (max == null || c < max) _chapterCtrl.text = '${c + 1}';
                      },
                    ),
                  ],
                ),
              ],

              // Book totals override section
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
                      // Book-specific
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
