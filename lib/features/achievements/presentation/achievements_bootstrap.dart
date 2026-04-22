import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/achievements/presentation/achievements_provider.dart';
import 'package:cronicle/features/onboarding/presentation/onboarding_notifier.dart';

/// Mounts a hidden widget that:
///  * marks the night-owl flag on app start (if it's late),
///  * re-evaluates achievements whenever the library changes (debounced),
///  * triggers an immediate evaluation on first build.
class AchievementsBootstrap extends ConsumerStatefulWidget {
  const AchievementsBootstrap({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AchievementsBootstrap> createState() =>
      _AchievementsBootstrapState();
}

class _AchievementsBootstrapState extends ConsumerState<AchievementsBootstrap>
    with WidgetsBindingObserver {
  StreamSubscription? _librarySub;
  Timer? _debounce;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only spin up the heavy work (night-owl write, library stream
      // listener, evaluation) once the user has finished onboarding.
      // Subscribing to db.watchAllLibrary() during account sync would cause
      // a full library SELECT for every inserted row.
      if (ref.read(onboardingCompletedProvider)) {
        _start();
      }
    });
  }

  Future<void> _start() async {
    if (_started || !mounted) return;
    _started = true;
    final prefs = ref.read(sharedPreferencesProvider);
    await AchievementsCounters.markUsedAtNightIfApplicable(prefs);
    if (!mounted) return;
    _scheduleEvaluation(immediate: true);
    final db = ref.read(databaseProvider);
    _librarySub = db.watchAllLibrary().listen((_) {
      _scheduleEvaluation();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _started) {
      // On resume, sync flag (wear may have run while backgrounded) and re-eval.
      final prefs = ref.read(sharedPreferencesProvider);
      AchievementsCounters.markUsedAtNightIfApplicable(prefs);
      _scheduleEvaluation();
    }
  }

  void _scheduleEvaluation({bool immediate = false}) {
    if (!_started) return;
    _debounce?.cancel();
    _debounce = Timer(
      Duration(milliseconds: immediate ? 0 : 600),
      () {
        if (!mounted) return;
        ref.read(achievementsEvaluatorProvider).evaluateNow();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _librarySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start the engine the moment onboarding completes.
    ref.listen<bool>(onboardingCompletedProvider, (prev, next) {
      if (next == true && !_started) {
        _start();
      }
    });
    return widget.child;
  }
}
