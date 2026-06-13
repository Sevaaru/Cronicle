import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cronicle/core/connected_accounts/connected_account_kind.dart';

class ConnectedAccountsRemoteDataSource {
  ConnectedAccountsRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const _table = 'connected_account_secrets';

  String? get _userId => _client.auth.currentUser?.id;

  Future<Map<String, String>?> fetchSecrets(ConnectedAccountKind kind) async {
    final userId = _userId;
    if (userId == null) return null;

    final row = await _client
        .from(_table)
        .select('secrets')
        .eq('user_id', userId)
        .eq('provider', kind.id)
        .maybeSingle();
    if (row == null) return null;

    final secrets = row['secrets'];
    if (secrets is! Map) return null;

    final out = <String, String>{};
    for (final e in secrets.entries) {
      final val = e.value;
      if (val is String && val.isNotEmpty) {
        out[e.key.toString()] = val;
      }
    }
    return out.isEmpty ? null : out;
  }

  Future<void> upsertSecrets(
    ConnectedAccountKind kind,
    Map<String, String> secrets,
  ) async {
    final userId = _userId;
    if (userId == null || secrets.isEmpty) return;

    await _client.from(_table).upsert({
      'user_id': userId,
      'provider': kind.id,
      'secrets': secrets,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> deleteSecrets(ConnectedAccountKind kind) async {
    final userId = _userId;
    if (userId == null) return;

    await _client
        .from(_table)
        .delete()
        .eq('user_id', userId)
        .eq('provider', kind.id);
  }
}
