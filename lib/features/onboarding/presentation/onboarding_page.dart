import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
  double _syncProgress = 0;

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
    // Solo mostramos estado de sync si hay algo que realmente sincronizar.
    final hasAnyAccount = _googleConnected ||
        (ref.read(anilistTokenProvider).valueOrNull != null) ||
        (ref.read(traktSessionProvider).valueOrNull?.connected ?? false);

    if (hasAnyAccount) {
      setState(() {
        _syncing = true;
        _syncProgress = 0;
      });
    }

    await ref
        .read(onboardingCompletedProvider.notifier)
        .complete(_selected);
    if (!mounted) return;

    await _syncConnectedAccounts();

    if (hasAnyAccount && mounted) {
      setState(() => _syncProgress = 1);
    }

    if (!mounted) return;
    context.go('/feed');
  }

  Future<void> _syncConnectedAccounts() async {
    // Esta pasada trae datos de cuentas conectadas y los deja en local.
    final db = ref.read(databaseProvider);
    final tasks = <Future<void> Function()>[];

    final anilistToken = await ref.read(anilistTokenProvider.future);
    if (anilistToken != null && anilistToken.isNotEmpty) {
      tasks.add(() async {
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
            await ref.read(sharedPreferencesProvider).setInt(
                  anilistLibraryLastSyncSecondsKey,
                  DateTime.now().millisecondsSinceEpoch ~/ 1000,
                );
          }
        } catch (_) {}
      });
    }

    final traktState = ref.read(traktSessionProvider).valueOrNull;
    if (traktState != null && traktState.connected) {
      tasks.add(() async {
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
      });
    }

    if (_googleConnected && !_driveRestored) {
      tasks.add(() async {
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
      });
    }

    if (tasks.isEmpty) return;

    for (var i = 0; i < tasks.length; i++) {
      await tasks[i]();
      if (mounted) {
        setState(() => _syncProgress = (i + 1) / tasks.length);
      }
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
                      syncProgress: _syncProgress,
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
    required this.syncProgress,
    required this.onGoogleChanged,
    required this.onDriveRestored,
  });

  final VoidCallback onFinish;
  final VoidCallback onBack;
  final bool syncing;
  final double syncProgress;
  final ValueChanged<bool> onGoogleChanged;
  final VoidCallback onDriveRestored;

  @override
  ConsumerState<_AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<_AccountsPage> {
  bool _googleConnected = false;
  bool _connectingGoogle = false;
  bool _restoringFromDrive = false;
  // True from the moment the user signs into Google with an account that
  // has cloud data: we mark the local accounts as connected (because the
  // backup restore brings their tokens back) and show the syncing bar at
  // the bottom immediately, with the â€œsyncing all your accountsâ€ label.
  bool _restoringAll = false;
  bool _anilistSyncing = false;
  bool _traktSyncing = false;
  bool _anilistSynced = false;
  bool _traktSynced = false;

  bool get _isSyncing =>
      _anilistSyncing || _traktSyncing || _restoringFromDrive || _restoringAll;

  Future<void> _connectGoogle() async {
    setState(() => _connectingGoogle = true);
    try {
      final googleSignIn = ref.read(googleSignInProvider);
      final account = await googleSignIn.authenticate(
        scopeHint: const ['https://www.googleapis.com/auth/drive.appdata'],
      );
      await account.authorizationClient.authorizationForScopes(
        ['https://www.googleapis.com/auth/drive.appdata'],
      );
      const connected = true;
      if (mounted) {
        setState(() => _googleConnected = connected);
        widget.onGoogleChanged(connected);
        if (connected) {
          await _restoreFromDriveAndSync();
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _connectingGoogle = false);
    }
  }

  Future<void> _restoreFromDriveAndSync() async {
    if (!mounted) return;
    // Flip the global â€œrestoring allâ€ flag immediately so the bottom
    // sync bar appears the moment the user finishes the Google sign-in
    // dialog, even before the backup download finishes.
    setState(() {
      _restoringFromDrive = true;
      _restoringAll = true;
    });
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
    if (mounted) {
      try {
        await _syncOtherAccounts();
      } finally {
        if (mounted) setState(() => _restoringAll = false);
      }
    }
  }

  Future<void> _connectAnilist() async {
    if (!mounted) return;
    showAnilistConnectFlow(context, ref);
  }

  Future<void> _connectTrakt() async {
    if (kIsWeb) return;
    if (EnvConfig.traktClientId.isEmpty ||
        EnvConfig.traktClientSecret.isEmpty ||
        EnvConfig.traktRedirectUri.isEmpty) {
      return;
    }
    try {
      await ref.read(traktSessionProvider.notifier).connectOAuth();
    } catch (_) {
    }
  }

  Future<void> _syncOtherAccounts() async {
    final db = ref.read(databaseProvider);

    final anilistToken = await ref.read(anilistTokenProvider.future);
    if (anilistToken != null && anilistToken.isNotEmpty) {
      if (mounted) {
        setState(() => _anilistSyncing = true);
      }
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
          await ref.read(sharedPreferencesProvider).setInt(
                anilistLibraryLastSyncSecondsKey,
                DateTime.now().millisecondsSinceEpoch ~/ 1000,
              );
        }
        if (mounted) setState(() { _anilistSyncing = false; _anilistSynced = true; });
      } catch (_) {
        if (mounted) setState(() => _anilistSyncing = false);
      }
    }

    final traktState = ref.read(traktSessionProvider).valueOrNull;
    if (traktState != null && traktState.connected) {
      if (mounted) {
        setState(() => _traktSyncing = true);
      }
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
            height: (widget.syncing || _isSyncing) ? 72 : 52,
            child: FilledButton(
              onPressed: (widget.syncing || _isSyncing) ? null : widget.onFinish,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                // FilledButton fades both background and content when
                // disabled. While syncing we keep the button visually
                // active so the progress bar and label remain legible
                // (especially in dark mode).
                disabledBackgroundColor: (widget.syncing || _isSyncing)
                    ? cs.primary
                    : null,
                disabledForegroundColor: (widget.syncing || _isSyncing)
                    ? cs.onPrimary
                    : null,
              ),
              child: (widget.syncing || _isSyncing)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _restoringAll
                              ? (Localizations.localeOf(context)
                                          .languageCode ==
                                      'es'
                                  ? 'Sincronizando todas tus cuentas\u2026'
                                  : 'Syncing all your accounts\u2026')
                              : l10n.onboardingSyncing,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: cs.onPrimary.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Material 3 progress track: rounded, generous
                        // height, soft on-primary backdrop with a vivid
                        // sky-blue indicator that stays expressive on
                        // any primary color across light/dark themes.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            height: 8,
                            child: _M3SyncProgressBar(
                              value: widget.syncProgress,
                              trackColor:
                                  cs.onPrimary.withValues(alpha: 0.22),
                              indicatorColor: const Color(0xFF82B1FF),
                            ),
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

class _WavySyncProgressBar extends StatefulWidget {
  const _WavySyncProgressBar({
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  State<_WavySyncProgressBar> createState() => _WavySyncProgressBarState();
}

class _WavySyncProgressBarState extends State<_WavySyncProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  // Fake asymptotic progress: real sync tasks only report between discrete
  // steps, so a single long task would leave the bar stuck at 0 until it
  // finishes. We animate a synthetic value that eases toward 0.95, and
  // whatever the real `value` reports acts as a lower bound. The final
  // jump to 1.0 still comes from the parent when everything is done.
  late final AnimationController _fakeCtrl;
  double _fake = 0.0;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _fakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );
    // Drive the fake progress on every frame. Using `addListener` with an
    // always-repeating controller keeps the pump cheap (one setState per
    // frame while syncing is active).
    _fakeCtrl.addListener(_tickFake);
    _fakeCtrl.repeat();
  }

  @override
  void dispose() {
    _fakeCtrl.removeListener(_tickFake);
    _fakeCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  void _tickFake() {
    // Ease toward 0.95 asymptotically. Coefficient tuned so that the bar
    // reaches ~40% in ~1s, ~70% in ~3s and creeps into the 90s over ~10s
    // regardless of how long the real sync takes.
    const ceiling = 0.95;
    final remaining = ceiling - _fake;
    if (remaining > 0.0005) {
      setState(() => _fake = _fake + remaining * 0.012);
    } else if (_fake != ceiling) {
      setState(() => _fake = ceiling);
    }
  }

  @override
  Widget build(BuildContext context) {
    final real = widget.value.clamp(0.0, 1.0);
    // Real progress wins when it's greater than the fake floor, and when the
    // parent reports completion (1.0) we snap to it immediately.
    final display = real >= 1.0 ? 1.0 : math.max(real, _fake);
    return SizedBox(
      width: double.infinity,
      height: 10,
      child: AnimatedBuilder(
        animation: _waveCtrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavySyncProgressPainter(
              value: display,
              phase: _waveCtrl.value * 2 * math.pi,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _WavySyncProgressPainter extends CustomPainter {
  _WavySyncProgressPainter({
    required this.value,
    required this.phase,
    required this.color,
  });

  final double value;
  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(999);
    final fullRect = Offset.zero & size;
    final fullRRect = RRect.fromRectAndRadius(fullRect, radius);

    // Much higher-contrast track so the bar reads clearly on both the
    // primary-filled button background (dark and light themes).
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(fullRRect, trackPaint);

    final filledWidth = size.width * value;
    if (filledWidth <= 0) return;

    final fillRect = Rect.fromLTWH(0, 0, filledWidth, size.height);
    final fillRRect = RRect.fromRectAndRadius(fillRect, radius);
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(fillRRect, fillPaint);

    // Material 3 "wavy" accent drawn only inside the filled portion.
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final amp = size.height * 0.22;
    final baseline = size.height * 0.5;

    path.moveTo(0, baseline);
    for (double x = 0; x <= filledWidth; x += 1) {
      final y = baseline + math.sin((x / 9.0) + phase) * amp;
      path.lineTo(x, y);
    }

    canvas.save();
    canvas.clipRRect(fillRRect);
    canvas.drawPath(path, wavePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WavySyncProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color;
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



class _M3SyncProgressBar extends StatefulWidget {
  const _M3SyncProgressBar({
    required this.value,
    required this.trackColor,
    required this.indicatorColor,
  });

  final double value;
  final Color trackColor;
  final Color indicatorColor;

  @override
  State<_M3SyncProgressBar> createState() => _M3SyncProgressBarState();
}

class _M3SyncProgressBarState extends State<_M3SyncProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _displayed = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_tick);
    _ctrl.repeat();
  }

  void _tick() {
    final target = widget.value.clamp(0.0, 1.0).toDouble();
    // Smooth easing toward target so the bar always looks alive even
    // when upstream progress only updates between coarse steps.
    final next = _displayed + (target - _displayed) * 0.06 + 0.0015;
    final clamped = next.clamp(0.0, target == 1.0 ? 1.0 : 0.97);
    if ((clamped - _displayed).abs() > 0.0005) {
      setState(() => _displayed = clamped);
    }
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: _displayed,
      minHeight: 8,
      backgroundColor: widget.trackColor,
      valueColor: AlwaysStoppedAnimation<Color>(widget.indicatorColor),
    );
  }
}
