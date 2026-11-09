import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';

int _anilistFuzzyMin(int year, int? month) {
  if (month == null) return year * 10000 + 101;
  return year * 10000 + month * 100 + 1;
}

int _anilistFuzzyMax(int year, int? month) {
  if (month == null) return year * 10000 + 1231;
  final last = DateTime(year, month + 1, 0);
  return year * 10000 + month * 100 + last.day;
}

List<Map<String, dynamic>> _filterTraktByMonth(
  List<Map<String, dynamic>> items,
  int year,
  int month,
) {
  final y = year.toString().padLeft(4, '0');
  final m = month.toString().padLeft(2, '0');
  final prefix = '$y-$m';
  return items.where((e) {
    final r = e['released'] as String?;
    if (r == null || r.length < 7) return false;
    return r.startsWith(prefix);
  }).toList();
}

class SearchBrowseByReleaseDatePage extends ConsumerStatefulWidget {
  const SearchBrowseByReleaseDatePage({super.key, required this.mediaKind});

  final MediaKind mediaKind;

  @override
  ConsumerState<SearchBrowseByReleaseDatePage> createState() =>
      _SearchBrowseByReleaseDatePageState();
}

class _SearchBrowseByReleaseDatePageState
    extends ConsumerState<SearchBrowseByReleaseDatePage> {
  late int _year;
  int? _month;
  var _loading = false;
  String? _error;
  final _items = <Map<String, dynamic>>[];
  final _scrollController = ScrollController();

  int _anilistPage = 1;
  var _anilistHasMore = false;
  var _loadingMoreAnilist = false;

  static const _perPage = 24;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isAnilistKind) return;
    if (!_anilistHasMore || _loadingMoreAnilist || _loading) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 400) return;
    _loadMoreAnilist();
  }

  bool get _isAnilistKind =>
      widget.mediaKind == MediaKind.anime ||
      widget.mediaKind == MediaKind.manga;

  String get _anilistType =>
      widget.mediaKind == MediaKind.manga ? 'MANGA' : 'ANIME';

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _anilistPage = 1;
      _anilistHasMore = false;
    });

    try {
      if (_isAnilistKind) {
        final graphql = ref.read(anilistGraphqlProvider);
        final minD = _anilistFuzzyMin(_year, _month);
        final maxD = _anilistFuzzyMax(_year, _month);
        final page = await graphql.fetchMediaByReleaseDateRange(
          type: _anilistType,
          startDateGreaterOrEqual: minD,
          startDateLesserOrEqual: maxD,
          page: 1,
          perPage: _perPage,
        );
        if (!mounted) return;
        setState(() {
          _items.addAll(page.items);
          _anilistHasMore = page.hasNextPage;
          _anilistPage = 1;
          _loading = false;
        });
      } else {
        final list = await _fetchPage(page: 1);
        if (!mounted) return;
        setState(() {
          _items.addAll(list);
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _loadMoreAnilist() async {
    if (!_isAnilistKind || !_anilistHasMore || _loadingMoreAnilist) return;
    _loadingMoreAnilist = true;
    final nextPage = _anilistPage + 1;
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final minD = _anilistFuzzyMin(_year, _month);
      final maxD = _anilistFuzzyMax(_year, _month);
      final page = await graphql.fetchMediaByReleaseDateRange(
        type: _anilistType,
        startDateGreaterOrEqual: minD,
        startDateLesserOrEqual: maxD,
        page: nextPage,
        perPage: _perPage,
      );
      if (!mounted) return;
      setState(() {
        final seen = _items.map((m) => (m['id'] as num).toInt()).toSet();
        for (final m in page.items) {
          final id = (m['id'] as num).toInt();
          if (!seen.contains(id)) {
            seen.add(id);
            _items.add(m);
          }
        }
        _anilistHasMore = page.hasNextPage;
        _anilistPage = nextPage;
        _loadingMoreAnilist = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMoreAnilist = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPage({required int page}) async {
    switch (widget.mediaKind) {
      case MediaKind.anime:
      case MediaKind.manga:
        throw StateError('anilist handled in _reload/_loadMoreAnilist');
      case MediaKind.movie:
      case MediaKind.tv:
        final api = ref.read(traktApiProvider);
        final y = _year.toString();
        final raw = widget.mediaKind == MediaKind.movie
            ? await api.moviesPopular(limit: 100, years: '$y-$y')
            : await api.showsPopular(limit: 100, years: '$y-$y');
        if (_month == null) return raw;
        return _filterTraktByMonth(raw, _year, _month!);
      case MediaKind.game:
        final start = DateTime.utc(_year, _month ?? 1, 1);
        final end = _month == null
            ? DateTime.utc(_year, 12, 31, 23, 59, 59)
            : DateTime.utc(
                _year,
                _month!,
                DateTime.utc(_year, _month! + 1, 0).day,
                23,
                59,
                59,
              );
        final startSec = start.millisecondsSinceEpoch ~/ 1000;
        final endSec = end.millisecondsSinceEpoch ~/ 1000;
        try {
          final api = ref.read(igdbApiProvider);
          final raw = await api.fetchGamesByFirstReleaseBetween(
            startSec: startSec,
            endSec: endSec,
            limit: 100,
          );
          return raw.map(IgdbApiDatasource.normalize).toList();
        } on IgdbWebUnsupportedException {
          return [];
        }
      case MediaKind.book:
        final api = ref.read(googleBooksApiProvider);
        return api.searchBooksByPublishYear(
          year: _year,
          month: _month,
          limit: 40,
          offset: 0,
        );
    }
  }

  Future<bool> _addToLibrary(Map<String, dynamic> item, MediaKind k) async {
    final db = ref.read(databaseProvider);
    final externalId = k == MediaKind.book
        ? (item['workKey'] as String? ?? item['id'].toString())
        : item['id'].toString();
    final existing = await db.getLibraryEntryByKindAndExternalId(
      k.code,
      externalId,
    );
    if (!mounted) return false;
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: k,
      existingEntry: existing,
    );
    if (!mounted || !added) return added;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.addedToLibrary)),
    );
    return added;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final libraryEntries =
        ref.watch(libraryByKindProvider(widget.mediaKind)).valueOrNull ?? [];
    final libraryIds = {
      for (final e in libraryEntries) '${e.kind}:${e.externalId}': true,
    };

    final yearItems = <DropdownMenuItem<int>>[
      for (var y = DateTime.now().year + 1; y >= 1960; y--)
        DropdownMenuItem(value: y, child: Text('$y')),
    ];

    final monthItems = <DropdownMenuItem<int?>>[
      DropdownMenuItem<int?>(
        value: null,
        child: Text(l10n.searchReleaseDateAllMonths),
      ),
      for (var m = 1; m <= 12; m++)
        DropdownMenuItem(value: m, child: Text(_monthLabel(context, m))),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.searchBrowseByStartDate),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Material(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.searchReleaseDateHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.searchReleaseDateYear,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _year,
                                isExpanded: true,
                                items: yearItems,
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _year = v);
                                  _reload();
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.searchReleaseDateMonth,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: _month,
                                isExpanded: true,
                                items: monthItems,
                                onChanged: (v) {
                                  setState(() => _month = v);
                                  _reload();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.error),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.25,
                          ),
                          Center(child: Text(l10n.searchReleaseDateEmpty)),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount:
                            _items.length + (_anilistHasMore && _isAnilistKind ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= _items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final item = _items[i];
                          final id = item['id']?.toString() ?? '';
                          final ext = widget.mediaKind == MediaKind.book
                              ? (item['workKey'] as String? ?? id)
                              : id;
                          final inLib = libraryIds.containsKey(
                            '${widget.mediaKind.code}:$ext',
                          );
                          return BrowseResultCard(
                            item: item,
                            kind: widget.mediaKind,
                            inLibrary: inLib,
                            onAdd: _addToLibrary,
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }

  String _monthLabel(BuildContext context, int m) {
    final d = DateTime(2000, m);
    return MaterialLocalizations.of(context).formatMonthYear(d).split(' ').first;
  }
}
