import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

/// Géneros admitidos por AniList (nombre exacto para la API).
const kAnilistBrowseGenres = <String>[
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Fantasy',
  'Horror',
  'Mystery',
  'Psychological',
  'Romance',
  'Sci-Fi',
  'Slice of Life',
  'Sports',
  'Supernatural',
  'Thriller',
];

/// Elige un género y abre el listado con filtros (`/browse/media`).
class SearchAnilistGenreListPage extends StatelessWidget {
  const SearchAnilistGenreListPage({super.key, required this.mediaType});

  /// `ANIME` o `MANGA`.
  final String mediaType;

  MediaKind get _kind => mediaType == 'MANGA' ? MediaKind.manga : MediaKind.anime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = mediaType == 'MANGA'
        ? l10n.searchBrowseGenresManga
        : l10n.searchBrowseGenresAnime;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(title),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: kAnilistBrowseGenres.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final genre = kAnilistBrowseGenres[i];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text(genre),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                final encoded = Uri.encodeQueryComponent(genre);
                context.push(
                  '/browse/media?kind=${_kind.code}&genre=$encoded&sort=popularity',
                );
              },
            ),
          );
        },
      ),
    );
  }
}
