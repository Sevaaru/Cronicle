import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';
import 'package:drift/drift.dart' as drift;

class AnimePage extends ConsumerStatefulWidget {
  const AnimePage({super.key});

  @override
  ConsumerState<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends ConsumerState<AnimePage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectAnilist() async {
    final auth = ref.read(anilistAuthProvider);
    final url = auth.authorizeUrl;
    if (EnvConfig.anilistClientId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ANILIST_CLIENT_ID no configurado. '
            'Usa --dart-define=ANILIST_CLIENT_ID=... al ejecutar.',
          ),
        ),
      );
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _addToLibrary(Map<String, dynamic> anime) async {
    final db = ref.read(databaseProvider);
    final title = anime['title'] as Map<String, dynamic>? ?? {};
    final coverImage = anime['coverImage'] as Map<String, dynamic>? ?? {};

    await db.upsertLibraryEntry(
      LibraryEntriesCompanion(
        kind: drift.Value(MediaKind.anime.code),
        externalId: drift.Value(anime['id'].toString()),
        title: drift.Value(
          (title['english'] as String?) ??
              (title['romaji'] as String?) ??
              'Unknown',
        ),
        posterUrl: drift.Value(coverImage['large'] as String?),
        status: const drift.Value('planning'),
        totalEpisodes: drift.Value(anime['episodes'] as int?),
        updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Añadido a la biblioteca')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokenAsync = ref.watch(anilistTokenProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navAnime),
        actions: [
          tokenAsync.when(
            data: (token) => token != null
                ? IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () =>
                        ref.read(anilistTokenProvider.notifier).clearToken(),
                  )
                : IconButton(
                    icon: const Icon(Icons.link),
                    onPressed: _connectAnilist,
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar anime...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Text(
                      'Escribe para buscar anime',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : _SearchResults(query: _query, onAdd: _addToLibrary),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.onAdd});

  final String query;
  final Future<void> Function(Map<String, dynamic>) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(animeSearchProvider(query));
    final colorScheme = Theme.of(context).colorScheme;

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text('Sin resultados'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final anime = list[i];
            final title = anime['title'] as Map<String, dynamic>? ?? {};
            final coverImage =
                anime['coverImage'] as Map<String, dynamic>? ?? {};
            final name = (title['english'] as String?) ??
                (title['romaji'] as String?) ??
                '';
            final poster = coverImage['large'] as String?;
            final episodes = anime['episodes'];
            final score = anime['averageScore'];
            final genres =
                (anime['genres'] as List?)?.cast<String>().take(3).join(', ');

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onAdd(anime),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20),
                      ),
                      child: poster != null
                          ? CachedNetworkImage(
                              imageUrl: poster,
                              width: 80,
                              height: 110,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 110,
                              color: colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            if (genres != null)
                              Text(
                                genres,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (episodes != null) ...[
                                  Icon(Icons.tv,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('$episodes ep',
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 12),
                                ],
                                if (score != null) ...[
                                  Icon(Icons.star,
                                      size: 14, color: Colors.amber.shade600),
                                  const SizedBox(width: 4),
                                  Text('$score%',
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(Icons.add_circle_outline,
                            color: colorScheme.primary),
                        onPressed: () => onAdd(anime),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
