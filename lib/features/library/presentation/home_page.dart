import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/l10n/app_localizations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final items = <_HomeNavItem>[
      _HomeNavItem(l10n.navLibrary, Icons.collections_bookmark_rounded, '/library'),
      _HomeNavItem(l10n.navAnime, Icons.animation_rounded, '/anime'),
      _HomeNavItem(l10n.navMovies, Icons.movie_rounded, '/movies'),
      _HomeNavItem(l10n.navTv, Icons.tv_rounded, '/tv'),
      _HomeNavItem(l10n.navGames, Icons.sports_esports_rounded, '/games'),
      _HomeNavItem(l10n.navAuth, Icons.link_rounded, '/auth'),
      _HomeNavItem(l10n.navSettings, Icons.settings_rounded, '/settings'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.homeSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(e.route),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(e.icon, color: colorScheme.primary),
                        const SizedBox(width: 16),
                        Expanded(child: Text(e.label)),
                        Icon(Icons.chevron_right, color: colorScheme.outline),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeNavItem {
  const _HomeNavItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
