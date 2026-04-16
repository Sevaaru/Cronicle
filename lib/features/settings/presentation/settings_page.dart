import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/backup/app_backup_bundle.dart';
import 'package:cronicle/core/backup/backup_repository_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/network/google_sign_in_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/library/presentation/twitch_sync_service.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/layout_customization_pages.dart';
import 'package:cronicle/features/settings/presentation/locale_notifier.dart';
import 'package:cronicle/features/settings/presentation/device_notifications_notifier.dart';
import 'package:cronicle/features/settings/presentation/theme_mode_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/core/utils/google_web_button.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final googleSignIn = ref.watch(googleSignInProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          const _AppearanceSection(),
          const SizedBox(height: 12),

          _DefaultFilterSection(),
          const SizedBox(height: 12),

          _AppDefaultsSection(),
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

class _DeviceNotificationsSection extends ConsumerWidget {
  const _DeviceNotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onChanged: (v) => notifier.setMasterEnabled(v),
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

    final themeButton = SegmentedButton<ThemeMode>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          tooltip: l10n.themeSystem,
          icon: const Icon(Icons.brightness_auto_rounded, size: 20),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          tooltip: l10n.themeLight,
          icon: const Icon(Icons.light_mode_rounded, size: 20),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          tooltip: l10n.themeDark,
          icon: const Icon(Icons.dark_mode_rounded, size: 20),
        ),
      ],
      selected: {themeMode},
      showSelectedIcon: false,
      onSelectionChanged: (s) {
        ref.read(themeModeNotifierProvider.notifier).setTheme(s.first);
      },
    );

    final languageButton = SegmentedButton<Locale>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      segments: const [
        ButtonSegment<Locale>(
          value: Locale('es'),
          label: Text('ES'),
          tooltip: 'Español',
        ),
        ButtonSegment<Locale>(
          value: Locale('en'),
          label: Text('EN'),
          tooltip: 'English',
        ),
      ],
      selected: {locale},
      showSelectedIcon: false,
      onSelectionChanged: (s) {
        ref.read(localeNotifierProvider.notifier).setLocale(s.first);
      },
    );

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
          LayoutBuilder(
            builder: (context, c) {
              const gap = 12.0;
              const minSideBySide = 304.0;
              final sideBySide = c.maxWidth >= minSideBySide;
              final itemW = sideBySide ? (c.maxWidth - gap) / 2 : c.maxWidth;

              Widget block(String label, Widget control) => SizedBox(
                    width: itemW,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          clipBehavior: Clip.none,
                          child: control,
                        ),
                      ],
                    ),
                  );

              return Wrap(
                spacing: gap,
                runSpacing: 14,
                alignment: WrapAlignment.start,
                children: [
                  block(l10n.themeMode, themeButton),
                  block(l10n.language, languageButton),
                ],
              );
            },
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
          const _TwitchIgdbAccountSection(),
          const Divider(height: 24),
          _GoogleSection(googleSignIn: googleSignIn),
        ],
      ),
    );
  }
}

class _TwitchIgdbAccountSection extends ConsumerWidget {
  const _TwitchIgdbAccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final twitchAsync = ref.watch(twitchIgdbAccountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sports_esports_rounded, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              l10n.twitchIgdbTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.twitchIgdbSubtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        twitchAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l10n.errorVerifyingToken),
          data: (s) {
            if (s.userConnected) {
              final login = s.login;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 18, color: Colors.purpleAccent.shade100),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          login != null && login.isNotEmpty
                              ? l10n.twitchConnectedAs(login)
                              : l10n.anilistConnected,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.purpleAccent.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(l10n.twitchDisconnectAccount),
                      onPressed: () async {
                        await ref
                            .read(twitchIgdbAccountProvider.notifier)
                            .disconnectUser();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.twitchDisconnected)),
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
                label: Text(l10n.twitchConnectOAuth),
                onPressed: () async {
                  try {
                    await ref
                        .read(twitchIgdbAccountProvider.notifier)
                        .connectOAuth();
                    if (!context.mounted) return;
                    final login = ref
                            .read(twitchIgdbAccountProvider)
                            .valueOrNull
                            ?.login ??
                        '';
                    final syncRes = await showTwitchGameSyncDialog(
                      context: context,
                      ref: ref,
                      login: login,
                    );
                    if (!context.mounted) return;
                    if (syncRes == TwitchSyncDialogResult.skipped) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.twitchConnectSuccess)),
                      );
                    }
                  } on UnsupportedError {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.twitchOAuthWebUnavailable)),
                    );
                  } on StateError catch (e) {
                    if (!context.mounted) return;
                    final msg = e.message;
                    if (msg == 'no_credentials') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.twitchOAuthMissingSecrets)),
                      );
                    } else if (msg == 'no_redirect_uri' ||
                        msg == 'invalid_redirect_uri') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.twitchRedirectNotConfigured)),
                      );
                    } else if (msg == 'redirect_must_be_https') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.twitchRedirectMustBeHttps)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.errorWithMessage(e))),
                      );
                    }
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
    final currentFeedScope = ref.watch(defaultFeedActivityScopeProvider);
    final hideText = ref.watch(hideTextActivitiesProvider);
    final visibleFeedIds = ref.watch(feedFilterLayoutProvider).visibleIdSet;

    final startPages = [
      ('/feed', l10n.settingsStartFeed, Icons.rss_feed_rounded),
      ('/library', l10n.settingsStartLibrary, Icons.collections_bookmark_rounded),
    ];

    final feedTabOptions = [
      ('feed', l10n.filterFeed, Icons.dynamic_feed_rounded),
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
          if (currentFeedTab == 'feed' && visibleFeedIds.contains('feed')) ...[
            const SizedBox(height: 10),
            Text(l10n.settingsFeedActivityScope,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                (
                  'following',
                  l10n.filterFollowing,
                  Icons.people_rounded,
                ),
                (
                  'global',
                  l10n.filterGlobal,
                  Icons.public_rounded,
                ),
              ].map((o) {
                final selected = currentFeedScope == o.$1;
                return ChoiceChip(
                  selected: selected,
                  avatar: Icon(o.$3, size: 16),
                  label: Text(o.$2, style: const TextStyle(fontSize: 12)),
                  onSelected: (_) => ref
                      .read(defaultFeedActivityScopeProvider.notifier)
                      .set(o.$1),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],

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

  bool _loading = true;
  bool _signedIn = false;

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
    _refreshSignedIn();
  }

  Future<void> _refreshSignedIn() async {
    if (kIsWeb) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final client = widget.googleSignIn.authorizationClient;
    try {
      final auth = await client.authorizationForScopes(_driveScopes);
      if (mounted) {
        setState(() {
          _signedIn = auth != null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _signedIn = false;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_circle_outlined,
                size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.googleAccountTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_missingGoogleServerClientId) ...[
          Text(
            l10n.googleSignInNotConfiguredHint,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await widget.googleSignIn.signOut();
                await _refreshSignedIn();
              },
              icon: const Icon(Icons.logout),
              label: Text(l10n.googleSignOut),
            ),
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
                  await widget.googleSignIn.authenticate(
                    scopeHint: const [
                      'https://www.googleapis.com/auth/drive.appdata',
                    ],
                  );
                  await _refreshSignedIn();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.connectedWithGoogle)),
                  );
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
      final payload = await AppBackupBundle.build(
        db: db,
        prefs: prefs,
        secure: secure,
      );
      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      if (!kIsWeb && await _googleAuthorizedForDrive()) {
        final repo = ref.read(backupRepositoryProvider);
        final res = await repo.uploadBackup(bytes);
        res.fold(
          (f) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorWithMessage(f.toString()))),
            );
          },
          (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.backupUploadSuccess)),
            );
          },
        );
        return;
      }

      if (kIsWeb) {
        await SharePlus.instance.share(ShareParams(text: jsonStr));
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/cronicle_backup.json');
        await file.writeAsString(jsonStr);
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          subject: 'Cronicle Backup',
        ));
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
                  onPressed: _exporting ? null : _exportBackup,
                  icon: _exporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(l10n.backupUpload),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importing ? null : _importBackup,
                  icon: _importing
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                      : const Icon(Icons.download_rounded),
                  label: Text(l10n.backupRestore),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
