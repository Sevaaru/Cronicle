import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/backup/backup_repository_provider.dart';
import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/errors/app_failure.dart';
import 'package:cronicle/core/network/google_sign_in_provider.dart';
import 'package:cronicle/features/settings/presentation/locale_notifier.dart';
import 'package:cronicle/features/settings/presentation/theme_mode_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final googleSignIn = ref.watch(googleSignInProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Theme
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.themeMode,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem)),
                    ButtonSegment(
                        value: ThemeMode.light, label: Text(l10n.themeLight)),
                    ButtonSegment(
                        value: ThemeMode.dark, label: Text(l10n.themeDark)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) {
                    ref
                        .read(themeModeNotifierProvider.notifier)
                        .setTheme(s.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Language
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.language,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                SegmentedButton<Locale>(
                  segments: const [
                    ButtonSegment(value: Locale('es'), label: Text('ES')),
                    ButtonSegment(value: Locale('en'), label: Text('EN')),
                  ],
                  selected: {locale},
                  onSelectionChanged: (s) {
                    ref
                        .read(localeNotifierProvider.notifier)
                        .setLocale(s.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Google account
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.navAuth,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await googleSignIn.authenticate(
                        scopeHint: const [
                          'email',
                          'https://www.googleapis.com/auth/drive.appdata',
                        ],
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Conectado con Google')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: Text(l10n.googleSignIn),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await googleSignIn.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.googleSignOut),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Backup
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.backupTitle,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _uploadBackup(context, ref),
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Subir'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadBackup(context, ref),
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Restaurar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final db = ref.read(databaseProvider);
      final entries = await db.getAllLibraryEntries();
      final kv = await db.getAllKeyValues();

      final payload = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'library': entries
            .map((e) => {
                  'kind': e.kind,
                  'externalId': e.externalId,
                  'title': e.title,
                  'posterUrl': e.posterUrl,
                  'status': e.status,
                  'score': e.score,
                  'progress': e.progress,
                  'totalEpisodes': e.totalEpisodes,
                  'notes': e.notes,
                  'updatedAt': e.updatedAt,
                })
            .toList(),
        'keyValues': kv
            .map((e) => {'key': e.key, 'value': e.value})
            .toList(),
      };

      final bytes =
          Uint8List.fromList(utf8.encode(jsonEncode(payload)));
      final backup = ref.read(backupRepositoryProvider);
      final result = await backup.uploadBackup(bytes);

      if (!context.mounted) return;
      result.fold(
        (f) => _showFailure(context, f, l10n),
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup subido correctamente')),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _downloadBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final backup = ref.read(backupRepositoryProvider);
      final result = await backup.downloadBackup();

      if (!context.mounted) return;
      await result.fold(
        (f) async => _showFailure(context, f, l10n),
        (bytes) async {
          final json =
              jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
          final entries =
              (json['library'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          final db = ref.read(databaseProvider);
          for (final e in entries) {
            await db.upsertLibraryEntry(
              LibraryEntriesCompanion.insert(
                kind: e['kind'] as int,
                externalId: e['externalId'] as String,
                title: e['title'] as String,
              ),
            );
          }

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restaurados ${entries.length} elementos')),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showFailure(
      BuildContext context, AppFailure failure, AppLocalizations l10n) {
    final message = switch (failure) {
      GoogleDriveFailure(message: final m) => m ?? l10n.errorGeneric,
      NetworkFailure() => l10n.errorNetwork,
      _ => l10n.errorGeneric,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
