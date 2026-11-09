
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/library/presentation/library_providers.dart';

const _channelName = 'cronicle.wear.events';

final wearEventListenerProvider = Provider<void>((ref) {
  const channel = MethodChannel(_channelName);
  channel.setMethodCallHandler((call) async {
    if (call.method == 'libraryChanged') {
      ref.invalidate(paginatedLibraryProvider);
    }
    return null;
  });
  ref.onDispose(() {
    channel.setMethodCallHandler(null);
  });
});
