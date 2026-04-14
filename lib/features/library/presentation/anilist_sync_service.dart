import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/shared/models/media_kind.dart';

/// Importa las listas de anime y manga del usuario de Anilist a la DB local.
Future<int> importAnilistToLocal({
  required AnilistGraphqlDatasource graphql,
  required AppDatabase db,
  required String token,
  required String userName,
}) async {
  final results = await Future.wait([
    graphql.fetchUserMediaList(token, userName, type: 'ANIME'),
    graphql.fetchUserMediaList(token, userName, type: 'MANGA'),
  ]);

  int count = 0;
  for (final entry in [...results[0], ...results[1]]) {
    final media = entry['media'] as Map<String, dynamic>? ?? {};
    final title = media['title'] as Map<String, dynamic>? ?? {};
    final coverImage = media['coverImage'] as Map<String, dynamic>? ?? {};
    final mediaType = media['type'] as String?;
    final kind = mediaType == 'MANGA' ? MediaKind.manga : MediaKind.anime;

    final totalEp = kind == MediaKind.manga
        ? media['chapters'] as int?
        : media['episodes'] as int?;

    await db.upsertLibraryEntry(LibraryEntriesCompanion(
      kind: drift.Value(kind.code),
      externalId: drift.Value(media['id'].toString()),
      title: drift.Value(
        (title['english'] as String?) ??
            (title['romaji'] as String?) ??
            'Unknown',
      ),
      posterUrl: drift.Value(coverImage['large'] as String?),
      status: drift.Value(entry['status'] as String? ?? 'PLANNING'),
      score: drift.Value(entry['score'] as int?),
      progress: drift.Value(entry['progress'] as int?),
      totalEpisodes: drift.Value(totalEp),
      notes: drift.Value(entry['notes'] as String?),
      updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
    ));
    count++;
  }
  return count;
}

/// Muestra el diálogo de primera sincronización con Anilist.
Future<void> showAnilistSyncDialog({
  required BuildContext context,
  required AnilistGraphqlDatasource graphql,
  required AppDatabase db,
  required String token,
}) async {
  final viewer = await graphql.fetchViewer(token);
  if (viewer == null) return;
  final userName = viewer['name'] as String? ?? '';
  if (userName.isEmpty || !context.mounted) return;

  final choice = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: const Text('Sincronizar con Anilist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Bienvenido, $userName! ¿Cómo quieres sincronizar tu biblioteca?',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _SyncOption(
              icon: Icons.cloud_download,
              title: 'Importar de Anilist',
              subtitle: 'Trae toda tu lista de Anilist aquí (recomendado)',
              cs: cs,
            ),
            const SizedBox(height: 8),
            _SyncOption(
              icon: Icons.merge_type,
              title: 'Combinar',
              subtitle: 'Fusiona registros locales con Anilist',
              cs: cs,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'skip'),
            child: const Text('Ahora no'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: const Text('Combinar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'import'),
            child: const Text('Importar'),
          ),
        ],
      );
    },
  );

  if (choice == null || choice == 'skip' || !context.mounted) return;

  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Sincronizando...'),
        ],
      ),
    ),
  );

  try {
    if (choice == 'import') {
      // Borrar locales de anime/manga antes de importar
      final existing = await db.getAllLibraryEntries();
      for (final e in existing) {
        if (e.kind == MediaKind.anime.code || e.kind == MediaKind.manga.code) {
          await db.deleteLibraryEntry(e.id);
        }
      }
    }

    final count = await importAnilistToLocal(
      graphql: graphql,
      db: db,
      token: token,
      userName: userName,
    );

    if (context.mounted) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importados $count títulos de Anilist')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al sincronizar: $e')),
      );
    }
  }
}

class _SyncOption extends StatelessWidget {
  const _SyncOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
