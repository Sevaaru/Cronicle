import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/backup/app_backup_bundle.dart';
import 'package:cronicle/core/backup/backup_repository_provider.dart';
import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/network/google_sign_in_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/anime/presentation/anilist_connect_flow.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/library/presentation/anilist_sync_service.dart';
import 'package:cronicle/features/library/presentation/trakt_sync_service.dart';
import 'package:cronicle/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';


class _Interest {
  const _Interest({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });

  final String id;
  final IconData icon;
  final String Function(AppLocalizations) label;
  final Color color;
}

final _interests = [
  _Interest(
    id: 'anime',
    icon: Icons.animation_rounded,
    label: (l) => l.onboardingInterestAnime,
    color: const Color(0xFF5C6BC0),
  ),
  _Interest(
    id: 'manga',
    icon: Icons.menu_book_rounded,
    label: (l) => l.onboardingInterestManga,
    color: const Color(0xFFEC407A),
  ),
  _Interest(
    id: 'movie',
    icon: Icons.movie_rounded,
    label: (l) => l.onboardingInterestMovies,
    color: const Color(0xFFFF7043),
  ),
  _Interest(
    id: 'tv',
    icon: Icons.tv_rounded,
    label: (l) => l.onboardingInterestTv,
    color: const Color(0xFF26A69A),
  ),
  _Interest(
    id: 'game',
    icon: Icons.sports_esports_rounded,
    label: (l) => l.onboardingInterestGames,
    color: const Color(0xFF42A5F5),
  ),
  _Interest(
    id: 'book',
    icon: Icons.auto_stories_rounded,
    label: (l) => l.onboardingInterestBooks,
    color: const Color(0xFFAB47BC),
  ),
];


class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  final _selected = <String>{};
  int _currentPage = 0;
  bool _googleConnected = false;
  bool _driveRestored = false;
  bool _syncing = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishSetup() async {
    final hasAnyAccount = _googleConnected ||
        (ref.read(anilistTokenProvider).valueOrNull != null) ||
        (ref.read(traktSessionProvider).valueOrNull?.connected ?? false);

    if (hasAnyAccount) {
      setState(() => _syncing = true);
    }

    await ref
        .read(onboardingCompletedProvider.notifier)
        .complete(_selected);
    if (!mounted) return;

    await _syncConnectedAccounts();

    if (!mounted) return;
    context.go('/feed');
  }

  Future<void> _syncConnectedAccounts() async {
    final db = ref.read(databaseProvider);

    final anilistToken = await ref.read(anilistTokenProvider.future);
    if (anilistToken != null && anilistToken.isNotEmpty) {
      try {
        final auth = ref.read(anilistAuthProvider);
        var userName = await auth.getUserName();
        if (userName == null || userName.isEmpty) {
          final graphql = ref.read(anilistGraphqlProvider);
          final viewer = await graphql.fetchViewer(anilistToken);
          userName = viewer?['name'] as String?;
          if (userName != null) await auth.saveUserName(userName);
        }
        if (userName != null && userName.isNotEmpty) {
          await importAnilistToLocal(
            graphql: ref.read(anilistGraphqlProvider),
            db: db,
            token: anilistToken,
            userName: userName,
          );
          await db.setKeyValue('anilist_library_synced', 'true');
        }
      } catch (_) {}
    }

    final traktState = ref.read(traktSessionProvider).valueOrNull;
    if (traktState != null && traktState.connected) {
      try {
        final token =
            await ref.read(traktAuthProvider).getValidAccessToken();
        if (token != null && token.isNotEmpty) {
          await importTraktWatchedToLocal(
            api: ref.read(traktApiProvider),
            db: db,
            accessToken: token,
          );
        }
      } catch (_) {}
    }

    if (_googleConnected && !_driveRestored) {
      try {
        final repo = ref.read(backupRepositoryProvider);
        final res = await repo.downloadBackup();
        final bytes = res.fold((_) => null, (b) => b);
        if (bytes != null && bytes.isNotEmpty) {
          final json =
              jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
          await AppBackupBundle.restoreFromJson(
            json: json,
            db: db,
            prefs: ref.read(sharedPreferencesProvider),
            secure: const FlutterSecureStorage(),
            ref: ref,
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_currentPage > 0)
                        Positioned(
                          left: 8,
                          child: IconButton(
                            onPressed: () => _goToPage(_currentPage - 1),
                            icon: const Icon(Icons.arrow_back_rounded),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _WelcomePage(onNext: () => _goToPage(1)),
                    _InterestsPage(
                      selected: _selected,
                      onToggle: (id) {
                        setState(() {
                          if (_selected.contains(id)) {
                            _selected.remove(id);
                          } else {
                            _selected.add(id);
                          }
                        });
                      },
                      onBack: () => _goToPage(0),
                      onNext: () => _goToPage(2),
                    ),
                    _AccountsPage(
                      onFinish: _finishSetup,
                      onBack: () => _goToPage(1),
                      syncing: _syncing,
                      onGoogleChanged: (v) =>
                          setState(() => _googleConnected = v),
                      onDriveRestored: () =>
                          setState(() => _driveRestored = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Icon(
            Icons.auto_stories_rounded,
            size: 72,
            color: cs.primary,
          ),
          const SizedBox(height: 28),
          Text(
            l10n.onboardingWelcomeTitle,
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingWelcomeBody,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.onboardingNext,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


class _InterestsPage extends StatelessWidget {
  const _InterestsPage({
    required this.selected,
    required this.onToggle,
    required this.onNext,
    required this.onBack,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;
  final VoidCallback onBack;

  bool get _canContinue => selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Icon(
            Icons.interests_rounded,
            size: 56,
            color: cs.primary,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboardingTitle,
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onboardingSubtitle,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _interests.map((interest) {
              final active = selected.contains(interest.id);
              return _InterestBubble(
                label: interest.label(l10n),
                icon: interest.icon,
                color: interest.color,
                selected: active,
                onTap: () => onToggle(interest.id),
              );
            }).toList(),
          ),
          const Spacer(flex: 3),
          AnimatedOpacity(
            opacity: _canContinue ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 250),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _canContinue ? onNext : null,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.onboardingContinue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


class _AccountsPage extends ConsumerStatefulWidget {
  const _AccountsPage({
    required this.onFinish,
    required this.onBack,
    required this.syncing,
    required this.onGoogleChanged,
    required this.onDriveRestored,
  });

  final VoidCallback onFinish;
  final VoidCallback onBack;
  final bool syncing;
  final ValueChanged<bool> onGoogleChanged;
  final VoidCallback onDriveRestored;

  @override
  ConsumerState<_AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<_AccountsPage> {
  bool _googleConnected = false;
  bool _connectingGoogle = false;
  bool _restoringFromDrive = false;
  bool _anilistSyncing = false;
  bool _traktSyncing = false;
  bool _anilistSynced = false;
  bool _traktSynced = false;

  bool get _isSyncing => _anilistSyncing || _traktSyncing;

  Future<void> _connectGoogle() async {
    setState(() => _connectingGoogle = true);
    try {
      final googleSignIn = ref.read(googleSignInProvider);
      final account = await googleSignIn.authenticate(
        scopeHint: const ['https://www.googleapis.com/auth/drive.appdata'],
      );
      if (account != null) {
        final auth = await account.authorizationClient
            .authorizationForScopes(
                ['https://www.googleapis.com/auth/drive.appdata']);
        final connected = auth != null;
        if (mounted) {
          setState(() => _googleConnected = connected);
          widget.onGoogleChanged(connected);
          if (connected) {
            await _restoreFromDriveAndSync();
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _connectingGoogle = false);
    }
  }

  Future<void> _restoreFromDriveAndSync() async {
    if (!mounted) return;
    setState(() => _restoringFromDrive = true);
    try {
      final repo = ref.read(backupRepositoryProvider);
      final res = await repo.downloadBackup();
      final bytes = res.fold((_) => null, (b) => b);
      if (bytes != null && bytes.isNotEmpty) {
        final json =
            jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        await AppBackupBundle.restoreFromJson(
          json: json,
          db: ref.read(databaseProvider),
          prefs: ref.read(sharedPreferencesProvider),
          secure: const FlutterSecureStorage(),
          ref: ref,
        );
      }
      if (mounted) widget.onDriveRestored();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _restoringFromDrive = false);
    }
    if (mounted) unawaited(_syncOtherAccounts());
  }

  Future<void> _connectAnilist() async {
    if (!mounted) return;
    showAnilistConnectFlow(context, ref);
  }

  Future<void> _connectTrakt() async {
    if (kIsWeb) return;
    if (EnvConfig.traktClientId.isEmpty ||
        EnvConfig.traktClientSecret.isEmpty ||
        EnvConfig.traktRedirectUri.isEmpty) return;
    try {
      await ref.read(traktSessionProvider.notifier).connectOAuth();
    } catch (_) {
    }
  }

  Future<void> _syncOtherAccounts() async {
    final db = ref.read(databaseProvider);

    final anilistToken = await ref.read(anilistTokenProvider.future);
    if (anilistToken != null && anilistToken.isNotEmpty) {
      if (mounted) setState(() => _anilistSyncing = true);
      try {
        final auth = ref.read(anilistAuthProvider);
        var userName = await auth.getUserName();
        if (userName == null || userName.isEmpty) {
          final graphql = ref.read(anilistGraphqlProvider);
          final viewer = await graphql.fetchViewer(anilistToken);
          userName = viewer?['name'] as String?;
          if (userName != null) await auth.saveUserName(userName);
        }
        if (userName != null && userName.isNotEmpty) {
          await importAnilistToLocal(
            graphql: ref.read(anilistGraphqlProvider),
            db: db,
            token: anilistToken,
            userName: userName,
          );
          await db.setKeyValue('anilist_library_synced', 'true');
        }
        if (mounted) setState(() { _anilistSyncing = false; _anilistSynced = true; });
      } catch (_) {
        if (mounted) setState(() => _anilistSyncing = false);
      }
    }

    final traktState = ref.read(traktSessionProvider).valueOrNull;
    if (traktState != null && traktState.connected) {
      if (mounted) setState(() => _traktSyncing = true);
      try {
        final token =
            await ref.read(traktAuthProvider).getValidAccessToken();
        if (token != null && token.isNotEmpty) {
          await importTraktWatchedToLocal(
            api: ref.read(traktApiProvider),
            db: db,
            accessToken: token,
          );
        }
        if (mounted) setState(() { _traktSyncing = false; _traktSynced = true; });
      } catch (_) {
        if (mounted) setState(() => _traktSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final anilistToken = ref.watch(anilistTokenProvider);
    final anilistConnected = anilistToken.valueOrNull != null;

    final traktSession = ref.watch(traktSessionProvider);
    final traktConnected =
        traktSession.valueOrNull?.connected ?? false;

    final anyConnected =
        anilistConnected || traktConnected || _googleConnected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Icon(
            Icons.cloud_sync_rounded,
            size: 56,
            color: cs.primary,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboardingAccountsTitle,
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onboardingAccountsSubtitle,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _AccountTile(
            icon: Icons.animation_rounded,
            color: const Color(0xFF5C6BC0),
            title: l10n.onboardingConnectAnilist,
            subtitle: l10n.onboardingConnectAnilistDesc,
            connected: anilistConnected,
            syncLoading: _anilistSyncing,
            connectedLabel: _anilistSynced
                ? l10n.onboardingAccountSynced
                : l10n.onboardingConnected,
            onConnect: _connectAnilist,
          ),
          const SizedBox(height: 12),

          _AccountTile(
            icon: Icons.movie_filter_rounded,
            color: const Color(0xFFED1C24),
            title: l10n.onboardingConnectTrakt,
            subtitle: l10n.onboardingConnectTraktDesc,
            connected: traktConnected,
            syncLoading: _traktSyncing,
            connectedLabel: _traktSynced
                ? l10n.onboardingAccountSynced
                : l10n.onboardingConnected,
            onConnect: _connectTrakt,
          ),
          const SizedBox(height: 12),

          _AccountTile(
            icon: Icons.cloud_rounded,
            color: const Color(0xFF4285F4),
            title: l10n.onboardingConnectGoogle,
            subtitle: l10n.onboardingConnectGoogleDesc,
            connected: _googleConnected,
            loading: _connectingGoogle || _restoringFromDrive,
            connectedLabel: l10n.onboardingConnected,
            onConnect: _connectGoogle,
          ),
          const SizedBox(height: 12),

          const Spacer(flex: 3),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: (widget.syncing || _isSyncing) ? null : widget.onFinish,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: (widget.syncing || _isSyncing)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.onboardingSyncing,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      anyConnected
                          ? l10n.onboardingFinish
                          : l10n.onboardingSkip,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.connected,
    required this.connectedLabel,
    required this.onConnect,
    this.loading = false,
    this.syncLoading = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool connected;
  final bool loading;
  final bool syncLoading;
  final String connectedLabel;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: connected || loading || syncLoading ? null : onConnect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              else if (syncLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green.shade400,
                  ),
                )
              else if (connected)
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade400,
                  size: 24,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _InterestBubble extends StatelessWidget {
  const _InterestBubble({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected
        ? color.withValues(alpha: 0.18)
        : cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final border = selected ? color : cs.outlineVariant.withValues(alpha: 0.3);
    final fg = selected ? color : cs.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: border, width: selected ? 2 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
