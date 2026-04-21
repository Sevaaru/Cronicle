// Queries the native side for the current Wear OS pairing/installation status
// so the settings screen can show whether the watch companion is reachable.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _channel = MethodChannel('cronicle.wear.status');

@immutable
class WearConnectionStatus {
  const WearConnectionStatus({
    required this.anyNodeConnected,
    required this.companionInstalled,
  });

  final bool anyNodeConnected;
  final bool companionInstalled;

  static const unknown = WearConnectionStatus(
    anyNodeConnected: false,
    companionInstalled: false,
  );
}

final wearConnectionStatusProvider =
    FutureProvider.autoDispose<WearConnectionStatus>((ref) async {
  if (!(defaultTargetPlatform == TargetPlatform.android)) {
    return WearConnectionStatus.unknown;
  }
  try {
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>('getStatus');
    if (raw == null) return WearConnectionStatus.unknown;
    return WearConnectionStatus(
      anyNodeConnected: raw['anyNodeConnected'] == true,
      companionInstalled: raw['companionInstalled'] == true,
    );
  } catch (_) {
    return WearConnectionStatus.unknown;
  }
});
