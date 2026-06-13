import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cronicle/core/config/env_config.dart';

Future<void> initializeSupabaseIfConfigured() async {
  if (!EnvConfig.hasSupabase) {
    if (kDebugMode) {
      debugPrint(
        '[Cronicle] Supabase not configured (SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY).',
      );
    }
    return;
  }

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl.trim(),
    publishableKey: EnvConfig.supabasePublishableKey.trim(),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  if (kDebugMode) {
    debugPrint('[Cronicle] Supabase initialized.');
  }
}

SupabaseClient? get cronicleSupabaseClient {
  if (!EnvConfig.hasSupabase) return null;
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}
