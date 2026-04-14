import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/backup/backup_repository_provider.dart';
import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/errors/app_failure.dart';
import 'package:cronicle/core/network/google_sign_in_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
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

          // Library default filter
          _DefaultFilterSection(),
          const SizedBox(height: 12),

          // Anilist
          _AnilistSection(),
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

class _AnilistSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsync = ref.watch(anilistTokenProvider);
    final cs = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.animation_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text('Anilist', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sincroniza tu lista de anime y manga',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          tokenAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Error al verificar token'),
            data: (token) {
              if (token != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: Colors.green.shade400),
                        const SizedBox(width: 6),
                        Text(
                          'Conectado',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Desconectar Anilist'),
                        onPressed: () async {
                          await ref.read(anilistTokenProvider.notifier).clearToken();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Desconectado de Anilist')),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }

              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Conectar Anilist'),
                  onPressed: () => _startAnilistLogin(context, ref),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _startAnilistLogin(BuildContext context, WidgetRef ref) {
    final auth = ref.read(anilistAuthProvider);
    final controller = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    // Abre Anilist inmediatamente
    launchUrl(
      Uri.parse(auth.authorizeUrl),
      mode: LaunchMode.externalApplication,
    );

    // Muestra el diálogo para pegar el token al volver
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.animation_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Conectar Anilist'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepRow(number: '1', text: 'Autoriza Cronicle en la pestaña que se abrió', cs: cs),
                  const SizedBox(height: 6),
                  _StepRow(number: '2', text: 'Copia el token que aparece en pantalla', cs: cs),
                  const SizedBox(height: 6),
                  _StepRow(number: '3', text: 'Vuelve aquí y pégalo abajo', cs: cs),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Token de Anilist',
                hintText: 'Pega el token aquí',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_go, size: 20),
                  tooltip: 'Pegar del portapapeles',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      controller.text = data!.text!;
                    }
                  },
                ),
              ),
              maxLines: 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Conectar'),
            onPressed: () async {
              final token = controller.text.trim();
              if (token.isEmpty) return;
              await ref.read(anilistTokenProvider.notifier).setToken(token);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text('¡Conectado con Anilist!'),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DefaultFilterSection extends ConsumerWidget {
  static const _options = [
    ('CURRENT', 'Viendo'),
    ('PLANNING', 'Planeado'),
    ('COMPLETED', 'Completado'),
    ('PAUSED', 'Pausado'),
    ('DROPPED', 'Abandonado'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(defaultLibraryFilterProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtro por defecto en Biblioteca',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Al abrir la biblioteca se mostrará este estado',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _options.map((o) {
              final selected = current == o.$1;
              return ChoiceChip(
                selected: selected,
                label: Text(o.$2, style: const TextStyle(fontSize: 12)),
                onSelected: (_) =>
                    ref.read(defaultLibraryFilterProvider.notifier).set(o.$1),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text, required this.cs});
  final String number;
  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: cs.primary,
          child: Text(number, style: TextStyle(fontSize: 11, color: cs.onPrimary, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: cs.onSurface))),
      ],
    );
  }
}
