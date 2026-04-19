import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/backup/app_backup_bundle.dart';
import 'package:cronicle/core/backup/backup_repository_provider.dart';
import 'package:cronicle/core/backup/data/drive_backup_repository.dart';
import 'package:cronicle/core/errors/app_failure.dart';
import 'package:cronicle/core/backup/google_drive_backup_prefs.dart';
import 'package:cronicle/core/backup/google_drive_backup_scheduler.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/network/google_sign_in_provider.dart';
import 'package:cronicle/features/anime/presentation/anilist_connect_flow.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/library/presentation/anilist_sync_service.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/library/presentation/trakt_sync_service.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/books/data/openlibrary_sync_service.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/layout_customization_pages.dart';
import 'package:cronicle/features/settings/presentation/locale_notifier.dart';
import 'package:cronicle/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:cronicle/features/settings/presentation/device_notifications_notifier.dart';
import 'package:cronicle/features/settings/presentation/theme_mode_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/core/utils/google_web_button.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final googleSignIn = ref.watch(googleSignInProvider);
    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.none,
        leading: const ProfileAvatarButton(),
        leadingWidth: kProfileLeadingWidth,
        titleSpacing: 0,
        title: Text(l10n.settingsTitle, style: pageTitleStyle()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          const _AppearanceSection(),
          const SizedBox(height: 12),

          _DefaultFilterSection(),
          const SizedBox(height: 12),

          _AppDefaultsSection(),
          const SizedBox(height: 12),

          const _ScoringSection(),
          const SizedBox(height: 12),

          if (kIsWeb)
            GlassCard(
              child: Text(
                l10n.settingsNotificationsUnavailableWeb,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            const _DeviceNotificationsSection(),
          const SizedBox(height: 12),

          _AccountsSection(googleSignIn: googleSignIn),
          const SizedBox(height: 12),

          _BackupSection(googleSignIn: googleSignIn),
        ],
      ),
    );
  }

}

class _DeviceNotificationsSection extends ConsumerStatefulWidget {
  const _DeviceNotificationsSection();

  @override
  ConsumerState<_DeviceNotificationsSection> createState() =>
      _DeviceNotificationsSectionState();
}

class _DeviceNotificationsSectionState
    extends ConsumerState<_DeviceNotificationsSection> {
  Future<void> _onMasterChanged(bool v) async {
    final notifier = ref.read(deviceNotificationSettingsProvider.notifier);
    if (v) {
      final status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        // System won't show the dialog again — open app settings.
        await openAppSettings();
        // Re-check after returning from settings.
        final after = await Permission.notification.status;
        if (!after.isGranted) return;
      } else if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.notifPermissionDeniedHint)),
            );
          }
          return;
        }
      }
    }
    await notifier.setMasterEnabled(v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final n = ref.watch(deviceNotificationSettingsProvider);
    final notifier = ref.read(deviceNotificationSettingsProvider.notifier);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  size: 22, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.settingsNotificationsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsNotificationsSubtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const Divider(height: 22),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsNotifMaster),
            value: n.masterEnabled,
            onChanged: (v) => _onMasterChanged(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsNotifAiring),
            value: n.airingEnabled,
            onChanged: n.masterEnabled
                ? (v) => notifier.setAiringEnabled(v)
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsNotifAnilistInbox),
            value: n.anilistInboxEnabled,
            onChanged: n.masterEnabled
                ? (v) => notifier.setAnilistInboxEnabled(v)
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsNotifAnilistSocial),
            subtitle: Text(
              l10n.settingsNotifAnilistSocialDesc,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            value: n.anilistSocialEnabled,
            onChanged: (n.masterEnabled && n.anilistInboxEnabled)
                ? (v) => notifier.setAnilistSocialEnabled(v)
                : null,
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    Widget themeToggles(double maxWidth) {
      const modes = [
        ThemeMode.system,
        ThemeMode.light,
        ThemeMode.dark,
      ];
      const icons = [
        Icons.brightness_auto_rounded,
        Icons.light_mode_rounded,
        Icons.dark_mode_rounded,
      ];
      const gap = 6.0;

      Widget segIcon(int i) {
        final mode = modes[i];
        final selected = themeMode == mode;
        final bg = selected
            ? cs.primaryContainer
            : cs.surfaceContainerHighest.withValues(alpha: 0.65);
        final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
        final tip = switch (i) {
          0 => l10n.themeSystem,
          1 => l10n.themeLight,
          _ => l10n.themeDark,
        };
        return Expanded(
          child: Tooltip(
            message: tip,
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => ref
                    .read(themeModeNotifierProvider.notifier)
                    .setTheme(mode),
                child: SizedBox(
                  height: 42,
                  child: Center(
                    child: Icon(icons[i], size: 20, color: fg),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: maxWidth,
        child: Row(
          children: [
            segIcon(0),
            const SizedBox(width: gap),
            segIcon(1),
            const SizedBox(width: gap),
            segIcon(2),
          ],
        ),
      );
    }

    Widget languageToggles(double maxWidth) {
      const locales = [Locale('es'), Locale('en')];
      const labels = ['ES', 'EN'];
      const tips = ['Español', 'English'];
      const gap = 6.0;

      Widget segLang(int i) {
        final selected = locale == locales[i];
        final bg = selected
            ? cs.primaryContainer
            : cs.surfaceContainerHighest.withValues(alpha: 0.65);
        final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
        return Expanded(
          child: Tooltip(
            message: tips[i],
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => ref
                    .read(localeNotifierProvider.notifier)
                    .setLocale(locales[i]),
                child: SizedBox(
                  height: 42,
                  child: Center(
                    child: Text(
                      labels[i],
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: maxWidth,
        child: Row(
          children: [
            segLang(0),
            const SizedBox(width: gap),
            segLang(1),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsAppearanceTitle,
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsAppearanceSubtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.themeMode,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, c) => themeToggles(c.maxWidth),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.language,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, c) => languageToggles(c.maxWidth),
              ),
            ],
          ),
          const Divider(height: 28),
          Text(
            l10n.settingsLayoutCustomizationTitle,
            style: textTheme.titleSmall?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.tune_rounded, color: cs.primary),
            title: Text(l10n.settingsCustomizeFeedFilters),
            subtitle: Text(
              l10n.settingsCustomizeFeedFiltersDesc,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                fullscreenDialog: false,
                builder: (_) => const FeedFilterLayoutEditorPage(),
              ),
            ),
          ),
          const Divider(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.view_list_rounded, color: cs.primary),
            title: Text(l10n.settingsCustomizeLibraryKinds),
            subtitle: Text(
              l10n.settingsCustomizeLibraryKindsDesc,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                fullscreenDialog: false,
                builder: (_) => const LibraryKindLayoutEditorPage(),
              ),
            ),
          ),
          const Divider(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.manage_search_rounded, color: cs.primary),
            title: Text(l10n.settingsCustomizeSearchFilters),
            subtitle: Text(
              l10n.settingsCustomizeSearchFiltersDesc,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                fullscreenDialog: false,
                builder: (_) => const SearchFilterLayoutEditorPage(),
              ),
            ),
          ),
          const Divider(height: 20),
          const _InterestsQuickEditor(),
        ],
      ),
    );
  }
}

class _AccountsSection extends ConsumerWidget {
  const _AccountsSection({required this.googleSignIn});

  final GoogleSignIn googleSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsAccountsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsAccountsSubtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const Divider(height: 24),
          const _AnilistSection(),
          const Divider(height: 24),
          const _TraktSection(),
          const Divider(height: 24),
          const _OpenLibrarySection(),
          const Divider(height: 24),
          _GoogleSection(googleSignIn: googleSignIn),
        ],
      ),
    );
  }
}

class _AnilistSection extends ConsumerWidget {
  const _AnilistSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokenAsync = ref.watch(anilistTokenProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
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
                onPressed: () => _AnilistSection._startAnilistLogin(context, ref),
              ),
            );
          },
        ),
      ],
    );
  }

  static void _startAnilistLogin(BuildContext context, WidgetRef ref) {
    showAnilistConnectFlow(context, ref);
  }
}

class _TraktSection extends ConsumerWidget {
  const _TraktSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final sessionAsync = ref.watch(traktSessionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.movie_filter_rounded, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(l10n.traktTitle, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.traktSubtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        sessionAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l10n.errorVerifyingToken),
          data: (s) {
            if (s.connected) {
              final label = s.userSlug ?? s.userName ?? '—';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 18, color: Colors.green.shade400),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.traktConnectedAs(label),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_download_outlined, size: 18),
                      label: Text(l10n.traktImportTitle),
                      onPressed: () async {
                        final token =
                            await ref.read(traktAuthProvider).getValidAccessToken();
                        if (token == null || !context.mounted) return;
                        await showTraktImportDialog(
                          context: context,
                          api: ref.read(traktApiProvider),
                          db: ref.read(databaseProvider),
                          accessToken: token,
                        );
                        ref.invalidate(paginatedLibraryProvider);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(l10n.traktDisconnect),
                      onPressed: () async {
                        await ref.read(traktSessionProvider.notifier).clear();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.traktDisconnected)),
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
                label: Text(l10n.traktConnect),
                onPressed: () async {
                  if (kIsWeb) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.traktOAuthWebUnavailable)),
                    );
                    return;
                  }
                  if (EnvConfig.traktClientId.isEmpty ||
                      EnvConfig.traktClientSecret.isEmpty ||
                      EnvConfig.traktRedirectUri.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(l10n.traktOAuthMissingCredentials)),
                    );
                    return;
                  }
                  try {
                    await ref.read(traktSessionProvider.notifier).connectOAuth();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.traktConnectSuccess)),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.errorWithMessage(e))),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OpenLibrarySection extends ConsumerStatefulWidget {
  const _OpenLibrarySection();

  @override
  ConsumerState<_OpenLibrarySection> createState() => _OpenLibrarySectionState();
}

class _OpenLibrarySectionState extends ConsumerState<_OpenLibrarySection> {
  final _controller = TextEditingController();
  bool _syncing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final username = ref.watch(openLibraryUsernameProvider);
    final connected = username != null && username.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_stories_rounded, size: 20, color: const Color(0xFFAB47BC)),
            const SizedBox(width: 8),
            Text(l10n.settingsOpenLibraryTitle,
                style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.settingsOpenLibrarySubtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (connected) ...[
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: Colors.green.shade400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.settingsOpenLibraryConnectedAs(username),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: _syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_download_outlined, size: 18),
              label: Text(l10n.settingsOpenLibrarySync),
              onPressed: _syncing
                  ? null
                  : () async {
                      setState(() => _syncing = true);
                      try {
                        final count = await syncOpenLibraryReadingLog(ref);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  l10n.settingsOpenLibrarySyncResult(count))),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      } finally {
                        if (mounted) setState(() => _syncing = false);
                      }
                    },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l10n.settingsOpenLibraryDisconnect),
              onPressed: () {
                ref.read(openLibraryUsernameProvider.notifier).set(null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.settingsOpenLibraryDisconnected)),
                );
              },
            ),
          ),
        ] else ...[
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.settingsOpenLibraryUsernameHint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.login, size: 18),
              label: Text(l10n.settingsOpenLibraryConnect),
              onPressed: () async {
                final input = _controller.text.trim();
                if (input.isEmpty) return;
                try {
                  final exists =
                      await ref.read(openLibraryApiProvider).usernameExists(input);
                  if (!mounted) return;
                  if (!exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(l10n.settingsOpenLibraryUsernameNotFound)),
                    );
                    return;
                  }
                  ref.read(openLibraryUsernameProvider.notifier).set(input);
                  _controller.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(l10n.settingsOpenLibraryConnectSuccess)),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              },
            ),
          ),
        ],
      ],
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

class _ScoringSection extends ConsumerWidget {
  const _ScoringSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final current = ref.watch(scoringSystemSettingProvider);
    final advEnabled = ref.watch(anilistAdvancedScoringEnabledProvider);

    final options = [
      (ScoringSystem.point100, l10n.scoringPoint100),
      (ScoringSystem.point10Decimal, l10n.scoringPoint10Decimal),
      (ScoringSystem.point10, l10n.scoringPoint10),
      (ScoringSystem.point5, l10n.scoringPoint5),
      (ScoringSystem.point3, l10n.scoringPoint3),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsScoringTitle,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(l10n.settingsScoringDesc,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((o) {
              final selected = current == o.$1;
              return ChoiceChip(
                selected: selected,
                label: Text(o.$2, style: const TextStyle(fontSize: 12)),
                onSelected: (_) =>
                    ref.read(scoringSystemSettingProvider.notifier).set(o.$1),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),

          const Divider(height: 24),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsAdvancedScoring,
                style: const TextStyle(fontSize: 13)),
            subtitle: Text(l10n.settingsAdvancedScoringDesc,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            value: advEnabled,
            onChanged: (_) =>
                ref.read(anilistAdvancedScoringEnabledProvider.notifier).toggle(),
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
    final hideText = ref.watch(hideTextActivitiesProvider);
    final visibleFeedIds = ref.watch(feedFilterLayoutProvider).visibleIdSet;

    final startPages = [
      ('/feed', l10n.settingsStartFeed, Icons.rss_feed_rounded),
      ('/library', l10n.settingsStartLibrary, Icons.collections_bookmark_rounded),
    ];

    final feedTabOptions = [
      ('anime', l10n.filterAnime, Icons.animation_rounded),
      ('manga', l10n.filterManga, Icons.menu_book_rounded),
      ('movie', l10n.filterMovies, Icons.movie_rounded),
      ('tv', l10n.filterTv, Icons.tv_rounded),
      ('game', l10n.filterGames, Icons.sports_esports_rounded),
    ];
    final feedTabs = feedTabOptions
        .where((o) => visibleFeedIds.contains(o.$1))
        .toList();

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

          const Divider(height: 24),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsHideTextActivities,
                style: const TextStyle(fontSize: 13)),
            subtitle: Text(l10n.settingsHideTextActivitiesDesc,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            value: hideText,
            onChanged: (_) =>
                ref.read(hideTextActivitiesProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }
}

class _GoogleSection extends ConsumerStatefulWidget {
  const _GoogleSection({required this.googleSignIn});

  final GoogleSignIn googleSignIn;

  @override
  ConsumerState<_GoogleSection> createState() => _GoogleSectionState();
}

class _GoogleSectionState extends ConsumerState<_GoogleSection> {
  static const _driveScopes = [
    'https://www.googleapis.com/auth/drive.appdata',
  ];
  static const _kPrefsGoogleDisplayEmail = 'google_sign_in_display_email';

  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventsSub;

  bool _loading = true;
  bool _signedIn = false;
  String? _accountEmail;
  bool _syncing = false;

  String _lastSyncWhen(AppLocalizations l10n) {
    final ms =
        ref.read(sharedPreferencesProvider).getInt(GoogleDriveBackupPrefs.lastRunMs);
    if (ms == null || ms <= 0) return l10n.never;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(dt));
  }

  bool get _needsGoogleServerClientId {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  bool get _missingGoogleServerClientId =>
      _needsGoogleServerClientId &&
      EnvConfig.googleServerClientId.trim().isEmpty;

  Future<void> _showGoogleNotConfiguredDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.googleSignInNotConfiguredTitle),
        content: SingleChildScrollView(
          child: Text(l10n.googleSignInNotConfiguredBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _authEventsSub = widget.googleSignIn.authenticationEvents.listen(
      (event) {
        if (!mounted) return;
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final e = event.user.email;
          if (e.isNotEmpty) {
            unawaited(
              ref
                  .read(sharedPreferencesProvider)
                  .setString(_kPrefsGoogleDisplayEmail, e),
            );
          }
          setState(() => _accountEmail = e.isEmpty ? null : e);
          unawaited(_refreshSignedIn());
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          unawaited(
            ref.read(sharedPreferencesProvider).remove(_kPrefsGoogleDisplayEmail),
          );
          setState(() => _accountEmail = null);
          unawaited(_refreshSignedIn());
        }
      },
      onError: (_) {},
    );
    _refreshSignedIn();
  }

  @override
  void dispose() {
    _authEventsSub?.cancel();
    super.dispose();
  }

  /// Devuelve si hay autorización de Drive (sesión útil para copias en la nube).
  Future<bool> _refreshSignedIn([GoogleSignInAccount? authenticatedAccount]) async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _loading = false;
          _signedIn = false;
          _accountEmail = null;
        });
      }
      return false;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    try {
      final account = authenticatedAccount;

      GoogleSignInAuthorizationClient authClientForUser() =>
          account?.authorizationClient ?? widget.googleSignIn.authorizationClient;

      var auth = await authClientForUser().authorizationForScopes(_driveScopes);

      // Tras [authenticate], los scopes de Drive deben pedirse con el cliente
      // de [GoogleSignInAccount]; el cliente global suele devolver null.
      if (auth == null && account != null) {
        try {
          auth =
              await account.authorizationClient.authorizeScopes(_driveScopes);
        } on GoogleSignInException catch (e) {
          if (e.code != GoogleSignInExceptionCode.canceled) rethrow;
        }
      }

      final signedIn = auth != null;
      String? email;
      if (signedIn) {
        if (account != null && account.email.isNotEmpty) {
          email = account.email;
          await prefs.setString(_kPrefsGoogleDisplayEmail, email);
        } else {
          email = prefs.getString(_kPrefsGoogleDisplayEmail);
        }
      } else {
        if (account == null) {
          await prefs.remove(_kPrefsGoogleDisplayEmail);
        }
      }

      if (mounted) {
        setState(() {
          _signedIn = signedIn;
          _accountEmail =
              signedIn && (email != null && email.isNotEmpty) ? email : null;
          _loading = false;
        });
      }
      await prefs.setBool(GoogleDriveBackupPrefs.autoEnabled, signedIn);
      await GoogleDriveBackupScheduler.applyFromPrefs(prefs);
      return signedIn;
    } catch (_) {
      if (mounted) {
        setState(() {
          _signedIn = false;
          _accountEmail = null;
          _loading = false;
        });
      }
      return false;
    }
  }

  Future<void> _syncNowToGoogle() async {
    if (_syncing || !_signedIn || kIsWeb) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _syncing = true);
    try {
      final db = ref.read(databaseProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      const secure = FlutterSecureStorage();
      try {
        await mergeAnilistLibraryIntoLocalIfSignedIn(
          graphql: ref.read(anilistGraphqlProvider),
          db: db,
          auth: ref.read(anilistAuthProvider),
        );
        ref.invalidate(paginatedLibraryProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.backupAnilistMergeFailed(l10n.errorWithMessage(e)),
              ),
            ),
          );
        }
      }
      final payload = await AppBackupBundle.build(
        db: db,
        prefs: prefs,
        secure: secure,
      );
      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      final repo = ref.read(backupRepositoryProvider);
      final res = await repo.uploadBackup(bytes);
      if (!mounted) return;
      res.fold(
        (f) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(f.toString()))),
          );
        },
        (_) {
          final prefs = ref.read(sharedPreferencesProvider);
          final now = DateTime.now().millisecondsSinceEpoch;
          unawaited(prefs.setInt(GoogleDriveBackupPrefs.lastRunMs, now));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupUploadSuccess)),
          );
          setState(() {});
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// Tras conectar Google con permiso de Drive: descarga la copia en la nube y fusiona en local.
  Future<void> _restoreFromDriveAfterSignIn() async {
    if (!mounted || kIsWeb) return;
    if (_syncing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _syncing = true);
    try {
      final repo = ref.read(backupRepositoryProvider);
      final res = await repo.downloadBackup();
      if (!mounted) return;
      final bytes = res.fold(
        (f) {
          if (f is GoogleDriveFailure &&
              f.message == DriveBackupRepository.noDriveBackupFailureMessage) {
            return null;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(f.toString()))),
          );
          return null;
        },
        (b) => b,
      );
      if (bytes == null || bytes.isEmpty) return;

      final jsonStr = utf8.decode(bytes);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final db = ref.read(databaseProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      const secure = FlutterSecureStorage();
      final imported = await AppBackupBundle.restoreFromJson(
        json: json,
        db: db,
        prefs: prefs,
        secure: secure,
        ref: ref,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupRestoredCount(imported))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_circle_outlined,
                size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              l10n.googleAccountTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.googleAccountSubtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (_missingGoogleServerClientId) ...[
          Text(
            l10n.googleSignInNotConfiguredHint,
            style: TextStyle(
              fontSize: 12,
              color: cs.error,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (kIsWeb)
          buildGoogleWebButton(context)
        else if (_loading)
          const LinearProgressIndicator(minHeight: 2)
        else if (_signedIn)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle,
                      size: 18, color: Colors.green.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.anilistConnected,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade400,
                          ),
                        ),
                        if (_accountEmail != null &&
                            _accountEmail!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _accountEmail!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.googleLastSyncLine(_lastSyncWhen(l10n)),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _syncing ? null : _syncNowToGoogle,
                  icon: _syncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: Text(l10n.googleSyncNow),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _syncing
                      ? null
                      : () async {
                          await widget.googleSignIn.signOut();
                          await ref
                              .read(sharedPreferencesProvider)
                              .remove(_kPrefsGoogleDisplayEmail);
                          await _refreshSignedIn();
                        },
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(l10n.googleSignOut),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                if (_missingGoogleServerClientId) {
                  await _showGoogleNotConfiguredDialog();
                  return;
                }
                try {
                  final account =
                      await widget.googleSignIn.authenticate(
                    scopeHint: const [
                      'https://www.googleapis.com/auth/drive.appdata',
                    ],
                  );
                  final driveOk = await _refreshSignedIn(account);
                  if (!context.mounted) return;
                  if (driveOk) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.connectedWithGoogle)),
                    );
                    unawaited(_restoreFromDriveAfterSignIn());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.googleDrivePermissionMissing),
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  if (e is GoogleSignInException &&
                      e.code == GoogleSignInExceptionCode.canceled) {
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.googleSignInCanceledTitle),
                        content: SingleChildScrollView(
                          child: Text(l10n.googleSignInCanceledBody),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(
                              MaterialLocalizations.of(ctx).okButtonLabel,
                            ),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.errorWithMessage(e))),
                  );
                }
              },
              icon: const Icon(Icons.login),
              label: Text(l10n.googleSignIn),
            ),
          ),
      ],
    );
  }
}

class _BackupSection extends ConsumerStatefulWidget {
  const _BackupSection({required this.googleSignIn});

  final GoogleSignIn googleSignIn;

  @override
  ConsumerState<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<_BackupSection> {
  bool _exporting = false;
  bool _importing = false;

  static const _driveScope = 'https://www.googleapis.com/auth/drive.appdata';

  Future<bool> _googleAuthorizedForDrive() async {
    if (kIsWeb) return false;
    try {
      final client = widget.googleSignIn.authorizationClient;
      final a = await client.authorizationForScopes([_driveScope]);
      return a != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _exportBackup() async {
    if (_exporting) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _exporting = true);
    try {
      final db = ref.read(databaseProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      const secure = FlutterSecureStorage();
      try {
        await mergeAnilistLibraryIntoLocalIfSignedIn(
          graphql: ref.read(anilistGraphqlProvider),
          db: db,
          auth: ref.read(anilistAuthProvider),
        );
        ref.invalidate(paginatedLibraryProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.backupAnilistMergeFailed(l10n.errorWithMessage(e)),
              ),
            ),
          );
        }
      }
      final payload = await AppBackupBundle.build(
        db: db,
        prefs: prefs,
        secure: secure,
      );
      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      if (kIsWeb) {
        await SharePlus.instance.share(ShareParams(text: jsonStr));
      } else {
        final savePath = await FilePicker.saveFile(
          dialogTitle: l10n.backupSaveFileDialogTitle,
          fileName: 'cronicle_backup.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );

        if (savePath == null || savePath.isEmpty) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/cronicle_backup.json');
          await file.writeAsString(jsonStr);
          await SharePlus.instance.share(ShareParams(
            files: [XFile(file.path)],
            subject: 'Cronicle Backup',
          ));
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupExportReady)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importBackup() async {
    if (_importing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _importing = true);
    try {
      Uint8List? bytes;

      if (!kIsWeb && await _googleAuthorizedForDrive()) {
        if (!mounted) return;
        final source = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.backupRestoreChooseSourceTitle),
            content: Text(l10n.backupRestoreChooseSourceBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'file'),
                child: Text(l10n.backupRestoreFromFile),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'drive'),
                child: Text(l10n.backupRestoreFromDrive),
              ),
            ],
          ),
        );
        if (source == null) {
          if (mounted) setState(() => _importing = false);
          return;
        }
        if (source == 'drive') {
          final repo = ref.read(backupRepositoryProvider);
          final res = await repo.downloadBackup();
          bytes = res.fold(
            (f) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.errorWithMessage(f.toString()))),
                );
              }
              return null;
            },
            (b) => b,
          );
          if (bytes == null) {
            if (mounted) setState(() => _importing = false);
            return;
          }
        }
      }

      if (bytes == null) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          withData: true,
        );
        if (result == null || result.files.isEmpty) {
          if (mounted) setState(() => _importing = false);
          return;
        }
        bytes = result.files.first.bytes ??
            (kIsWeb ? null : await File(result.files.first.path!).readAsBytes());
      }

      if (bytes == null) throw Exception(l10n.errorWithMessage('read file'));

      final jsonStr = utf8.decode(bytes);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final entries = (json['library'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.backupRestoreConfirmTitle),
          content: Text(l10n.backupRestoreConfirmBody(entries.length)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.backupRestore)),
          ],
        ),
      );

      if (confirmed != true) {
        if (mounted) setState(() => _importing = false);
        return;
      }

      final db = ref.read(databaseProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      const secure = FlutterSecureStorage();
      final imported = await AppBackupBundle.restoreFromJson(
        json: json,
        db: db,
        prefs: prefs,
        secure: secure,
        ref: ref,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupRestoredCount(imported))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.backup_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(l10n.backupTitle, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.backupSectionSubtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onPressed: _exporting ? null : _exportBackup,
                  icon: _exporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(
                    l10n.backupExportButton,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onPressed: _importing ? null : _importBackup,
                  icon: _importing
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    l10n.backupRestore,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InterestsQuickEditor extends ConsumerWidget {
  const _InterestsQuickEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // Derive currently selected interests from the feed layout.
    final feedLayout = ref.watch(feedFilterLayoutProvider);
    final selected = <String>{
      for (final s in feedLayout.slots)
        if (s.visible && onboardingInterestIds.contains(s.id)) s.id,
    };

    final items = <(String, String, IconData, Color)>[
      ('anime', l10n.onboardingInterestAnime, Icons.animation_rounded, const Color(0xFF5C6BC0)),
      ('manga', l10n.onboardingInterestManga, Icons.menu_book_rounded, const Color(0xFFEC407A)),
      ('movie', l10n.onboardingInterestMovies, Icons.movie_rounded, const Color(0xFFFF7043)),
      ('tv', l10n.onboardingInterestTv, Icons.tv_rounded, const Color(0xFF26A69A)),
      ('game', l10n.onboardingInterestGames, Icons.sports_esports_rounded, const Color(0xFF42A5F5)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.interests_rounded, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.settingsInterests,
                  style: Theme.of(context).textTheme.titleSmall),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.settingsInterestsDesc,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final active = selected.contains(item.$1);
            final bg = active
                ? item.$4.withValues(alpha: 0.18)
                : cs.surfaceContainerHighest.withValues(alpha: 0.55);
            final border =
                active ? item.$4 : cs.outlineVariant.withValues(alpha: 0.3);
            final fg = active ? item.$4 : cs.onSurfaceVariant;

            return FilterChip(
              selected: active,
              showCheckmark: false,
              avatar: Icon(item.$3, size: 18, color: fg),
              label: Text(item.$2, style: TextStyle(color: fg)),
              backgroundColor: bg,
              selectedColor: bg,
              shape: StadiumBorder(
                side: BorderSide(color: border, width: active ? 2 : 1),
              ),
              onSelected: (_) async {
                final next = Set<String>.from(selected);
                if (active) {
                  if (next.length <= 1) return; // min 1
                  next.remove(item.$1);
                } else {
                  next.add(item.$1);
                }
                await ref
                    .read(onboardingCompletedProvider.notifier)
                    .updateInterests(next);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.settingsInterestsChanged),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
