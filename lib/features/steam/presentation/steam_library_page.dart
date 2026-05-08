import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/steam/data/datasources/steam_api_datasource.dart';
import 'package:cronicle/features/steam/presentation/steam_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';
import 'package:cronicle/shared/widgets/library_insert_animation.dart';
import 'package:cronicle/shared/widgets/library_snackbar.dart';

/// Sort options for the Steam owned-games list.
enum _SteamSort { playtimeDesc, lastPlayedDesc, nameAsc }

class SteamLibraryPage extends ConsumerStatefulWidget {
  const SteamLibraryPage({super.key});

  @override
  ConsumerState<SteamLibraryPage> createState() => _SteamLibraryPageState();
}

class _SteamLibraryPageState extends ConsumerState<SteamLibraryPage> {
  _SteamSort _sort = _SteamSort.playtimeDesc;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(steamSessionProvider);
    final gamesAsync = ref.watch(steamOwnedGamesProvider);

    return Scaffold(
        appBar: AppBar(
          title: Text(l10n.steamLibraryTitle),
          actions: [
          IconButton(
            tooltip: l10n.steamRefresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(steamOwnedGamesProvider),
          ),
        ],
      ),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
        data: (s) {
          if (!s.connected) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.steamNotConnectedHint,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            children: [
              _SteamHeader(
                personaName: s.personaName ?? '—',
                avatarUrl: s.avatarUrl,
              ),
              _FilterRow(
                sort: _sort,
                onSortChanged: (v) => setState(() => _sort = v),
                query: _query,
                searchCtrl: _searchCtrl,
                onQueryChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              ),
              Expanded(
                child: gamesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text(l10n.errorWithMessage(e))),
                  data: (games) {
                    final filtered = _applyFilters(games);
                    if (filtered.isEmpty) {
                      return Center(child: Text(l10n.steamNoGames));
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(steamOwnedGamesProvider);
                        await ref.read(steamOwnedGamesProvider.future);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, kGlassBottomNavContentHeight + 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final g = filtered[i];
                          return _SteamGameRow(game: g);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> games) {
    final q = _query.trim().toLowerCase();
    Iterable<Map<String, dynamic>> it = games;
    if (q.isNotEmpty) {
      it = it.where(
          (g) => (g['name'] as String? ?? '').toLowerCase().contains(q));
    }
    final list = it.toList();
    switch (_sort) {
      case _SteamSort.playtimeDesc:
        list.sort((a, b) => ((b['playtime_forever'] as num?) ?? 0)
            .compareTo((a['playtime_forever'] as num?) ?? 0));
      case _SteamSort.lastPlayedDesc:
        list.sort((a, b) => ((b['rtime_last_played'] as num?) ?? 0)
            .compareTo((a['rtime_last_played'] as num?) ?? 0));
      case _SteamSort.nameAsc:
        list.sort((a, b) => ((a['name'] as String?) ?? '')
            .toLowerCase()
            .compareTo(((b['name'] as String?) ?? '').toLowerCase()));
    }
    return list;
  }
}

class _SteamHeader extends StatelessWidget {
  const _SteamHeader({required this.personaName, this.avatarUrl});

  final String personaName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                ? NetworkImage(avatarUrl!)
                : null,
            child: (avatarUrl == null || avatarUrl!.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              personaName,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.sort,
    required this.onSortChanged,
    required this.query,
    required this.searchCtrl,
    required this.onQueryChanged,
    required this.onClear,
  });

  final _SteamSort sort;
  final ValueChanged<_SteamSort> onSortChanged;
  final String query;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: l10n.steamSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: onClear,
                    )
                  : null,
            ),
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                label: Text(l10n.steamSortPlaytime),
                selected: sort == _SteamSort.playtimeDesc,
                onSelected: (_) => onSortChanged(_SteamSort.playtimeDesc),
              ),
              ChoiceChip(
                label: Text(l10n.steamSortLastPlayed),
                selected: sort == _SteamSort.lastPlayedDesc,
                onSelected: (_) => onSortChanged(_SteamSort.lastPlayedDesc),
              ),
              ChoiceChip(
                label: Text(l10n.steamSortName),
                selected: sort == _SteamSort.nameAsc,
                onSelected: (_) => onSortChanged(_SteamSort.nameAsc),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SteamGameRow extends ConsumerStatefulWidget {
  const _SteamGameRow({required this.game});

  final Map<String, dynamic> game;

  @override
  ConsumerState<_SteamGameRow> createState() => _SteamGameRowState();
}

class _SteamGameRowState extends ConsumerState<_SteamGameRow> {
  /// Cached IGDB id string once we've resolved it. Used to match library
  /// entries, which store the IGDB id (not the Steam appId) as externalId.
  String? _igdbExternalId;

  /// Cached normalized IGDB game map so subsequent taps (edit) are instant.
  Map<String, dynamic>? _cachedIgdbGame;

  /// Whether the IGDB lookup is currently running; shows a spinner on the button.
  bool _loading = false;

  final _btnKey = GlobalKey();

  Map<String, dynamic> get game => widget.game;

  LibraryEntry? _findExisting(List<LibraryEntry> entries) {
    final appId = (game['appid'] as num?)?.toInt() ?? 0;
    // Primary: match by steamAppId stored in the DB
    final bySteam = entries.cast<LibraryEntry?>().firstWhere(
          (e) => e?.steamAppId == appId,
          orElse: () => null,
        );
    if (bySteam != null) {
      // Keep the IGDB id cached to skip the lookup on next "edit" tap
      _igdbExternalId ??= bySteam.externalId;
      return bySteam;
    }
    // Fallback: match by cached IGDB id
    if (_igdbExternalId != null) {
      return entries.cast<LibraryEntry?>().firstWhere(
            (e) => e?.externalId == _igdbExternalId,
            orElse: () => null,
          );
    }
    return null;
  }

  Future<bool> _openSheet(
    BuildContext context, {
    required LibraryEntry? existing,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final appId = (game['appid'] as num?)?.toInt() ?? 0;
    final name = game['name'] as String? ?? '—';
    final playtimeMin = (game['playtime_forever'] as num?)?.toInt() ?? 0;

    // Use cached game map if available; otherwise fetch from IGDB.
    Map<String, dynamic>? igdbGame = _cachedIgdbGame;

    if (igdbGame == null) {
      if (mounted) setState(() => _loading = true);
      try {
        final igdb = ref.read(igdbApiProvider);
        final igdbId =
            await igdb.findGameIdBySteamAppId(appId, gameName: name);
        if (igdbId != null) {
          igdbGame = IgdbApiDatasource.normalize(
              await igdb.fetchGameDetail(igdbId) ?? {});
          if (mounted) {
            setState(() {
              _igdbExternalId = igdbId.toString();
              _cachedIgdbGame = igdbGame;
            });
          }
        }
      } catch (_) {}
      if (mounted) setState(() => _loading = false);
      if (!context.mounted) return false;
    }

    if (igdbGame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.steamNoIgdbMatch(name))),
      );
      return false;
    }

    // Re-check existing entry by IGDB id now that we know it
    LibraryEntry? resolvedExisting = existing;
    if (resolvedExisting == null && _igdbExternalId != null) {
      final db = ref.read(databaseProvider);
      resolvedExisting = await db.getLibraryEntryByKindAndExternalId(
        MediaKind.game.code,
        _igdbExternalId!,
      );
    }
    final wasEdit = resolvedExisting != null;

    if (!context.mounted) return false;

    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: igdbGame,
      kind: MediaKind.game,
      existingEntry: resolvedExisting,
      initialProgress: (!wasEdit && playtimeMin > 0)
          ? (playtimeMin / 60).round()
          : null,
      useRootNavigator: false,
      steamAppId: appId,
    );
    if (context.mounted && added) {
      showLibrarySnackbar(context, wasEdit: wasEdit);
    }
    return added;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final appId = (game['appid'] as num?)?.toInt() ?? 0;
    final name = game['name'] as String? ?? '—';
    final playtimeMin = (game['playtime_forever'] as num?)?.toInt() ?? 0;
    final hours = playtimeMin / 60.0;
    final capsuleUrl = SteamApiDatasource.capsuleUrl(appId);
    final fallbackUrl = SteamApiDatasource.headerUrl(appId);

    final libraryEntries =
        ref.watch(libraryByKindProvider(MediaKind.game)).valueOrNull ?? [];
    final existing = _findExisting(libraryEntries);
    final inLibrary = existing != null;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/profile/steam/game/$appId'),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: capsuleUrl,
                width: 75,
                height: 105,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => CachedNetworkImage(
                  imageUrl: fallbackUrl,
                  width: 75,
                  height: 105,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    width: 75,
                    height: 105,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.sports_esports_rounded,
                        color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.steamHoursPlayed(hours.toStringAsFixed(1)),
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                key: _btnKey,
                icon: _loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: cs.primary,
                        ),
                      )
                    : Icon(
                        inLibrary
                            ? Icons.edit_rounded
                            : Icons.add_circle_outline_rounded,
                        color: cs.primary,
                      ),
                tooltip:
                    inLibrary ? l10n.editLibraryEntry : l10n.addToLibrary,
                onPressed: _loading
                    ? null
                    : () async {
                        final wasInLibrary = inLibrary;
                        final added =
                            await _openSheet(context, existing: existing);
                        if (added &&
                            !wasInLibrary &&
                            _btnKey.currentContext != null) {
                          playLibraryInsertAnimation(
                            sourceContext: _btnKey.currentContext!,
                            imageUrl: capsuleUrl,
                          );
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
