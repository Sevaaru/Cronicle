import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:cronicle/core/notifications/notification_sync_runner.dart';

/// - Al pasar a segundo plano: una comprobación (WorkManager en Android se retrasa).
/// - Con la app en primer plano: comprobación periódica para que nuevas entradas
///   de Anilist / airing también disparen notificaciones del sistema en Android.
class NotificationLifecycleSync extends StatefulWidget {
  const NotificationLifecycleSync({required this.child, super.key});

  final Widget child;

  @override
  State<NotificationLifecycleSync> createState() =>
      _NotificationLifecycleSyncState();
}

class _NotificationLifecycleSyncState extends State<NotificationLifecycleSync>
    with WidgetsBindingObserver {
  static DateTime? _lastPauseSync;

  Timer? _foregroundPeriodic;
  Timer? _foregroundInitial;
  static DateTime? _lastForegroundPoll;

  bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _startForegroundPolling();
      }
    });
  }

  @override
  void dispose() {
    _stopForegroundPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startForegroundPolling() {
    if (!_mobile) return;
    _stopForegroundPolling();

    _foregroundInitial = Timer(const Duration(seconds: 25), () {
      if (!mounted) return;
      _runForegroundPoll();
    });

    _foregroundPeriodic = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _runForegroundPoll(),
    );
  }

  void _stopForegroundPolling() {
    _foregroundPeriodic?.cancel();
    _foregroundInitial?.cancel();
    _foregroundPeriodic = null;
    _foregroundInitial = null;
  }

  void _runForegroundPoll() {
    if (!_mobile) return;
    final now = DateTime.now();
    if (_lastForegroundPoll != null &&
        now.difference(_lastForegroundPoll!) < const Duration(minutes: 4)) {
      return;
    }
    _lastForegroundPoll = now;

    Future(() async {
      try {
        await runNotificationSyncTask();
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_mobile) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _startForegroundPolling();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _stopForegroundPolling();
        _runPauseSync();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _runPauseSync() {
    final now = DateTime.now();
    if (_lastPauseSync != null &&
        now.difference(_lastPauseSync!) < const Duration(seconds: 45)) {
      return;
    }
    _lastPauseSync = now;

    Future(() async {
      try {
        await runNotificationSyncTask();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
