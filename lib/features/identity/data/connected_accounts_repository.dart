import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cronicle/core/connected_accounts/connected_account_kind.dart';
import 'package:cronicle/core/supabase/supabase_bootstrap.dart';
import 'package:cronicle/features/identity/data/connected_accounts_remote_datasource.dart';

class ConnectedAccountsRepository {
  ConnectedAccountsRepository(this._remote, this._secure);

  final ConnectedAccountsRemoteDataSource _remote;
  final FlutterSecureStorage _secure;

  /// Set after PostgREST reports the migration table is missing.
  static bool schemaUnavailable = false;

  static bool _migrationHintLogged = false;

  static ConnectedAccountsRepository? tryCreate() {
    if (schemaUnavailable) return null;
    final client = cronicleSupabaseClient;
    if (client == null || client.auth.currentSession == null) return null;
    return ConnectedAccountsRepository(
      ConnectedAccountsRemoteDataSource(client),
      const FlutterSecureStorage(),
    );
  }

  static bool _isMissingTableError(Object e) {
    final s = e.toString();
    return s.contains('PGRST205') ||
        s.contains('connected_account_secrets') ||
        s.contains('schema cache');
  }

  static void _logMigrationHintOnce() {
    if (!kDebugMode || _migrationHintLogged) return;
    _migrationHintLogged = true;
    debugPrint(
      '[Cronicle] Supabase: falta la tabla connected_account_secrets. '
      'Ejecuta supabase/migrations/003_connected_account_secrets.sql '
      'en el SQL Editor de tu proyecto (Dashboard → SQL).',
    );
  }

  bool _handleRemoteError(Object e, {String? context}) {
    if (_isMissingTableError(e)) {
      schemaUnavailable = true;
      _logMigrationHintOnce();
      return true;
    }
    if (kDebugMode && context != null) {
      debugPrint('[Cronicle] $context: $e');
    }
    return false;
  }

  Future<bool> isLocallyConnected(ConnectedAccountKind kind) async {
    final key = connectedAccountPrimarySecretKey[kind];
    if (key == null) return false;
    final v = await _secure.read(key: key);
    return v != null && v.isNotEmpty;
  }

  Future<Map<String, String>> _readLocalSecrets(ConnectedAccountKind kind) async {
    final keys = connectedAccountSecretKeys[kind] ?? const [];
    final out = <String, String>{};
    for (final key in keys) {
      final v = await _secure.read(key: key);
      if (v != null && v.isNotEmpty) out[key] = v;
    }
    return out;
  }

  Future<void> _writeLocalSecrets(Map<String, String> secrets) async {
    for (final e in secrets.entries) {
      await _secure.write(key: e.key, value: e.value);
    }
  }

  /// Upload current local session to Supabase (no-op if not signed in or empty).
  Future<void> push(ConnectedAccountKind kind) async {
    if (schemaUnavailable) return;
    if (!await isLocallyConnected(kind)) {
      await clearRemote(kind);
      return;
    }
    final secrets = await _readLocalSecrets(kind);
    if (secrets.isEmpty) return;
    try {
      await _remote.upsertSecrets(kind, secrets);
      if (kDebugMode) {
        debugPrint('[Cronicle] Synced ${kind.id} session to Supabase.');
      }
    } catch (e) {
      _handleRemoteError(e, context: 'Failed to sync ${kind.id} to Supabase');
    }
  }

  Future<void> clearRemote(ConnectedAccountKind kind) async {
    if (schemaUnavailable) return;
    try {
      await _remote.deleteSecrets(kind);
    } catch (e) {
      _handleRemoteError(e, context: 'Failed to clear ${kind.id} on Supabase');
    }
  }

  /// Pull secrets from Supabase when local session is missing.
  Future<Set<ConnectedAccountKind>> restoreMissingLocally() async {
    if (schemaUnavailable) return {};
    final restored = <ConnectedAccountKind>{};
    for (final kind in ConnectedAccountKind.values) {
      if (schemaUnavailable) break;
      if (await isLocallyConnected(kind)) continue;
      try {
        final remote = await _remote.fetchSecrets(kind);
        if (remote == null || remote.isEmpty) continue;
        final primary = connectedAccountPrimarySecretKey[kind];
        if (primary == null || (remote[primary]?.isEmpty ?? true)) continue;
        await _writeLocalSecrets(remote);
        restored.add(kind);
        if (kDebugMode) {
          debugPrint('[Cronicle] Restored ${kind.id} session from Supabase.');
        }
      } catch (e) {
        if (_handleRemoteError(e, context: 'Failed to restore ${kind.id}')) {
          break;
        }
      }
    }
    return restored;
  }

  /// Push all locally connected accounts (e.g. after linking on this device).
  Future<void> pushAllConnected() async {
    for (final kind in ConnectedAccountKind.values) {
      if (await isLocallyConnected(kind)) {
        await push(kind);
      }
    }
  }
}
