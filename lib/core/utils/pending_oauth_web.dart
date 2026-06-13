import 'dart:convert';
import 'dart:js_interop';

@JS('localStorage.getItem')
external JSString? _getItem(JSString key);

@JS('localStorage.removeItem')
external void _removeItem(JSString key);

class PendingTraktOAuth {
  const PendingTraktOAuth({required this.code, required this.state});

  final String code;
  final String state;
}

const _traktKey = 'trakt_pending_oauth';
const _steamKey = 'steam_pending_oauth';

Future<PendingTraktOAuth?> getPendingTraktOAuth() async {
  final raw = _getItem(_traktKey.toJS)?.toDart;
  if (raw == null || raw.isEmpty) return null;
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final code = map['code'] as String?;
    final state = map['state'] as String?;
    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      return null;
    }
    return PendingTraktOAuth(code: code, state: state);
  } catch (_) {
    return null;
  }
}

Future<void> clearPendingTraktOAuth() async {
  _removeItem(_traktKey.toJS);
}

Future<String?> getPendingSteamOAuthQuery() async {
  final raw = _getItem(_steamKey.toJS)?.toDart;
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

Future<void> clearPendingSteamOAuth() async {
  _removeItem(_steamKey.toJS);
}
