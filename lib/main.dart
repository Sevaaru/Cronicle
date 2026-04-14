import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/cronicle_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Sign-In en web requiere un clientId; si no hay, se salta en dev.
  try {
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Cronicle] Google Sign-In init skipped: $e');
    }
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CronicleApp(),
    ),
  );
}
