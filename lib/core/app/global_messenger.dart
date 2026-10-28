import 'package:flutter/material.dart';

/// Global key for the root [ScaffoldMessenger]. Wired into
/// `MaterialApp.router(scaffoldMessengerKey: ...)` in `cronicle_app.dart` so
/// any layer of the app — including providers, datasources and background
/// runners — can surface a brief snack without needing a `BuildContext`.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Remembers the last time we surfaced the AniList rate-limit notice so we
/// don't spam the user when many calls fail in quick succession.
DateTime? _lastRateLimitToast;

/// Shows a brief friendly snack telling the user the AniList API is in
/// cooldown (HTTP 429 / `X-RateLimit-Remaining` exhausted). Safe to call from
/// anywhere — it no-ops if the messenger isn't mounted yet, and debounces
/// itself so we never queue more than one toast every ~8 seconds.
void notifyAnilistRateLimited({int? retryAfterSeconds}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  final now = DateTime.now();
  final last = _lastRateLimitToast;
  if (last != null && now.difference(last) < const Duration(seconds: 8)) {
    return;
  }
  _lastRateLimitToast = now;

  final waitHint = (retryAfterSeconds != null && retryAfterSeconds > 0)
      ? ' (~${retryAfterSeconds}s)'
      : '';

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(
          seconds: (retryAfterSeconds != null && retryAfterSeconds > 0)
              ? retryAfterSeconds.clamp(3, 8)
              : 4,
        ),
        content: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded,
                size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text('AniList is busy, wait a moment...$waitHint'),
            ),
          ],
        ),
      ),
    );
}
