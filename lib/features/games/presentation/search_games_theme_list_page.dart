import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/features/games/data/games_feed_section.dart';
import 'package:cronicle/features/games/presentation/games_section_titles.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class SearchGamesThemeListPage extends StatelessWidget {
  const SearchGamesThemeListPage({super.key});

  static const _themeSlugs = <String>[
    GamesFeedSection.indie,
    GamesFeedSection.horror,
    GamesFeedSection.multiplayer,
    GamesFeedSection.rpg,
    GamesFeedSection.sports,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.searchBrowseGameThemes),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _themeSlugs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final slug = _themeSlugs[i];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text(gamesHomeSectionTitle(l10n, slug)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/games/section/$slug'),
            ),
          );
        },
      ),
    );
  }
}
