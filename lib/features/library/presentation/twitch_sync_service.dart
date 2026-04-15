import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

enum TwitchSyncDialogResult {
  /// Usuario pulsó «Ahora no» o cerró sin elegir.
  skipped,

  /// Combinar o sobreescribir completado (con snackbars propios).
  synced,

  /// Error durante la sincronización.
  failed,
}

/// Importación remota de juegos del usuario.
///
/// La API pública `api.igdb.com/v4` solo expone **metadatos** (juegos, portadas, etc.).
/// La colección personal de **igdb.com** (Jugado, listas, etc.) **no** está disponible
/// por ese API; por eso hoy devuelve 0. Cuando haya una fuente (Helix, Steam u otra),
/// implementar aquí los upserts en la tabla local de juegos (`MediaKind.game`).
Future<int> importTwitchRemoteGamesToLocal({required AppDatabase db}) async {
  return 0;
}

Future<TwitchSyncDialogResult> showTwitchGameSyncDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String login,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final displayName = login.trim().isEmpty ? '—' : login.trim();

  final choice = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(l10n.twitchSyncTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.twitchSyncWelcome(displayName),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.twitchSyncIgdbApiFootnote,
              style: TextStyle(fontSize: 11, height: 1.35, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _TwitchSyncOptionRow(
              icon: Icons.cloud_download,
              title: l10n.twitchGameSyncOverwrite,
              subtitle: l10n.twitchGameSyncOverwriteDesc,
              cs: cs,
            ),
            const SizedBox(height: 8),
            _TwitchSyncOptionRow(
              icon: Icons.merge_type,
              title: l10n.twitchGameSyncMerge,
              subtitle: l10n.twitchGameSyncMergeDesc,
              cs: cs,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'skip'),
            child: Text(l10n.syncNotNow),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: Text(l10n.twitchGameSyncMerge),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'import'),
            child: Text(l10n.twitchGameSyncOverwrite),
          ),
        ],
      );
    },
  );

  if (choice == null || choice == 'skip' || !context.mounted) {
    return TwitchSyncDialogResult.skipped;
  }

  final nav = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.syncLoading)),
          ],
        ),
      ),
    ),
  );

  try {
    final db = ref.read(databaseProvider);

    if (choice == 'import') {
      final existing = await db.getAllLibraryEntries();
      for (final e in existing) {
        if (e.kind == MediaKind.game.code) {
          await db.deleteLibraryEntry(e.id);
        }
      }
    }

    final count = await importTwitchRemoteGamesToLocal(db: db);
    ref.invalidate(paginatedLibraryProvider);

    if (nav.mounted) nav.pop();

    if (!context.mounted) return TwitchSyncDialogResult.synced;

    if (choice == 'import' && count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.twitchSyncImportedZeroWarning)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.twitchSyncImportedCount(count))),
      );
    }
    return TwitchSyncDialogResult.synced;
  } catch (e) {
    if (nav.mounted) nav.pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSyncMessage(e))),
      );
    }
    return TwitchSyncDialogResult.failed;
  }
}

class _TwitchSyncOptionRow extends StatelessWidget {
  const _TwitchSyncOptionRow({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
