import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/backup/backup_repository_provider.dart';
import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/errors/app_failure.dart';
import 'package:cronicle/core/network/google_sign_in_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/settings/presentation/locale_notifier.dart';
import 'package:cronicle/features/settings/presentation/theme_mode_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/core/utils/google_web_button.dart';
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

          _DefaultFilterSection(),
          const SizedBox(height: 12),

          _AppDefaultsSection(),
          const SizedBox(height: 12),

          _AnilistSection(),
          const SizedBox(height: 12),

          _GoogleSection(googleSignIn: googleSignIn),
          const SizedBox(height: 12),

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
                        label: Text(l10n.backupUpload),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadBackup(context, ref),
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: Text(l10n.backupRestore),
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
          SnackBar(content: Text(l10n.backupUploadSuccess)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e))),
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
            SnackBar(content: Text(l10n.backupRestoredCount(entries.length))),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e))),
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.anilistTitle, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.anilistSubtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          tokenAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l10n.errorVerifyingToken),
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
                          l10n.anilistConnected,
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
                        label: Text(l10n.anilistDisconnect),
                        onPressed: () async {
                          await ref.read(anilistTokenProvider.notifier).clearToken();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.anilistDisconnected)),
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
                  label: Text(l10n.anilistConnect),
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
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(anilistAuthProvider);
    final controller = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    launchUrl(
      Uri.parse(auth.authorizeUrl),
      mode: LaunchMode.externalApplication,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.animation_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text(l10n.anilistConnectTitle),
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
                  _StepRow(number: '1', text: l10n.anilistStep1, cs: cs),
                  const SizedBox(height: 6),
                  _StepRow(number: '2', text: l10n.anilistStep2, cs: cs),
                  const SizedBox(height: 6),
                  _StepRow(number: '3', text: l10n.anilistStep3, cs: cs),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l10n.anilistTokenLabel,
                hintText: l10n.anilistTokenHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_go, size: 20),
                  tooltip: l10n.anilistPasteTooltip,
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
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: Text(l10n.connect),
            onPressed: () async {
              final token = controller.text.trim();
              if (token.isEmpty) return;
              await ref.read(anilistTokenProvider.notifier).setToken(token);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(l10n.anilistConnectSuccess),
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(defaultLibraryFilterProvider);

    final options = [
      ('CURRENT', l10n.statusCurrentAnime),
      ('PLANNING', l10n.statusPlanning),
      ('COMPLETED', l10n.statusCompleted),
      ('PAUSED', l10n.statusPaused),
      ('DROPPED', l10n.statusDropped),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsDefaultFilter,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            l10n.settingsDefaultFilterDesc,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((o) {
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

class _AppDefaultsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final currentPage = ref.watch(defaultStartPageProvider);
    final currentFeedTab = ref.watch(defaultFeedTabProvider);

    final startPages = [
      ('/feed', l10n.settingsStartFeed, Icons.rss_feed_rounded),
      ('/library', l10n.settingsStartLibrary, Icons.collections_bookmark_rounded),
    ];

    final feedTabs = [
      ('following', l10n.filterFollowing, Icons.people_rounded),
      ('all', l10n.filterGlobal, Icons.public_rounded),
      ('anime', l10n.filterAnime, Icons.animation_rounded),
      ('manga', l10n.filterManga, Icons.menu_book_rounded),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsDefaultsTitle,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(l10n.settingsDefaultsDesc,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),

          Text(l10n.settingsStartPage, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: startPages.map((o) {
              final selected = currentPage == o.$1;
              return ChoiceChip(
                selected: selected,
                avatar: Icon(o.$3, size: 16),
                label: Text(o.$2, style: const TextStyle(fontSize: 12)),
                onSelected: (_) =>
                    ref.read(defaultStartPageProvider.notifier).set(o.$1),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          Text(l10n.settingsFeedTab, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: feedTabs.map((o) {
              final selected = currentFeedTab == o.$1;
              return ChoiceChip(
                selected: selected,
                avatar: Icon(o.$3, size: 16),
                label: Text(o.$2, style: const TextStyle(fontSize: 12)),
                onSelected: (_) =>
                    ref.read(defaultFeedTabProvider.notifier).set(o.$1),
                showCheckmark: false,
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

class _GoogleSection extends StatelessWidget {
  const _GoogleSection({required this.googleSignIn});
  final GoogleSignIn googleSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.navAuth, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          if (kIsWeb)
            _GoogleWebButton()
          else
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
                    SnackBar(content: Text(l10n.connectedWithGoogle)),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.errorWithMessage(e))),
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
    );
  }
}

class _GoogleWebButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildGoogleWebButton(context);
  }
}
