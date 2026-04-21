// Listens for native broadcasts from the Wear OS companion service
// (`MainActivity.ACTION_LIBRARY_CHANGED`) and invalidates the in-memory
// library providers so the foreground UI reflects the database mutation
// performed by the native `WearLibraryListenerService`.
//
// Drift's reactive streams only fire for writes that go through Drift in
// the same isolate. Watch-originated edits go through raw SQL on the
// platform side, so the foreground app must be told explicitly to refetch.

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
