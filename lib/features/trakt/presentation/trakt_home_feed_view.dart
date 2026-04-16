import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

/// Listado Trakt (películas o series) para el feed o `/movies` / `/tv`.
class TraktHomeFeedView extends ConsumerWidget {
  const TraktHomeFeedView({super.key, required this.kind});

  final MediaKind kind;

  bool get _isMovie => kind == MediaKind.movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (EnvConfig.traktClientId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.traktNotConfiguredHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (_isMovie) {
      final homeAsync = ref.watch(traktMoviesHomeProvider);
      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(traktMoviesHomeProvider);
          await ref.read(traktMoviesHomeProvider.future);
        },
        child: homeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.errorWithMessage(e)),
            ),
          ),
          data: (d) => _homeList(l10n, d.trending, d.watching, d.popular, kind),
        ),
      );
    }

    final showsAsync = ref.watch(traktShowsHomeProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(traktShowsHomeProvider);
        await ref.read(traktShowsHomeProvider.future);
      },
      child: showsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.errorWithMessage(e)),
          ),
        ),
        data: (d) => _homeList(l10n, d.trending, d.watching, d.popular, kind),
      ),
    );
  }
}

Widget _homeList(
  AppLocalizations l10n,
  List<Map<String, dynamic>> trending,
  List<Map<String, dynamic>> watching,
  List<Map<String, dynamic>> popular,
  MediaKind kind,
) {
  return ListView(
    padding: const EdgeInsets.only(bottom: 32),
    children: [
      _TraktCarouselSection(
        title: l10n.traktSectionTrending,
        items: trending,
        kind: kind,
      ),
      _TraktCarouselSection(
        title: l10n.traktSectionWatchingNow,
        items: watching,
        kind: kind,
      ),
      _TraktCarouselSection(
        title: l10n.traktSectionPopular,
        items: popular,
        kind: kind,
      ),
    ],
  );
}

class _TraktCarouselSection extends StatelessWidget {
  const _TraktCarouselSection({
    required this.title,
    required this.items,
    required this.kind,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final route = kind == MediaKind.movie ? '/trakt-movie' : '/trakt-show';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                final titleMap = item['title'] as Map<String, dynamic>? ?? {};
                final cover =
                    (item['coverImage'] as Map?)?['large'] as String?;
                final name = (titleMap['english'] as String?) ?? '';
                final score = item['averageScore'] as int?;
                final id = item['id'] as int?;

                return GestureDetector(
                  onTap: id != null ? () => context.push('$route/$id') : null,
                  child: SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: cover != null
                              ? CachedNetworkImage(
                                  imageUrl: cover,
                                  width: 110,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 110,
                                  height: 150,
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(
                                    kind == MediaKind.movie
                                        ? Icons.movie_rounded
                                        : Icons.tv_rounded,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (score != null)
                          Row(
                            children: [
                              Icon(Icons.star,
                                  size: 11, color: Colors.amber.shade600),
                              const SizedBox(width: 2),
                              Text(
                                '$score%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
