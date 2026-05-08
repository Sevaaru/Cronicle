import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      },
      child: Scaffold(
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

class _SteamGameRow extends ConsumerWidget {
  const _SteamGameRow({required this.game});

  final Map<String, dynamic> game;

  Future<bool> _openSheet(
    BuildContext context,
    WidgetRef ref, {
    LibraryEntry? existing,
  }) async {
    final appId = (game['appid'] as num?)?.toInt() ?? 0;
    final name = game['name'] as String? ?? '—';
    final syntheticItem = {
      'id': appId,
      'name': name,
      'coverImage': {'large': SteamApiDatasource.capsuleUrl(appId)},
    };
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: syntheticItem,
      kind: MediaKind.game,
      existingEntry: existing,
    );
    if (context.mounted && added) {
      showLibrarySnackbar(context, wasEdit: existing != null);
    }
    return added;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final appId = (game['appid'] as num?)?.toInt() ?? 0;
    final name = game['name'] as String? ?? '—';
    final playtimeMin = (game['playtime_forever'] as num?)?.toInt() ?? 0;
    final hours = playtimeMin / 60.0;
    final capsule = SteamApiDatasource.capsuleUrl(appId);

    final libraryEntries =
        ref.watch(libraryByKindProvider(MediaKind.game)).valueOrNull ?? [];
    final existing = libraryEntries.cast<LibraryEntry?>().firstWhere(
          (e) => e?.externalId == appId.toString(),
          orElse: () => null,
        );
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
              child: SizedBox(
                width: 100,
                height: 56,
                child: Image.network(
                  capsule,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.sports_esports_rounded,
                        color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.steamHoursPlayed(hours.toStringAsFixed(1)),
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Builder(
                builder: (btnCtx) => IconButton(
                  icon: Icon(
                    inLibrary ? Icons.edit : Icons.add_circle_outline,
                    color: cs.primary,
                  ),
                  tooltip:
                      inLibrary ? l10n.editLibraryEntry : l10n.addToLibrary,
                  onPressed: () async {
                    final wasInLibrary = inLibrary;
                    final added = await _openSheet(context, ref, existing: existing);
                    if (added && !wasInLibrary && btnCtx.mounted) {
                      playLibraryInsertAnimation(
                        sourceContext: btnCtx,
                        imageUrl: capsule,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
