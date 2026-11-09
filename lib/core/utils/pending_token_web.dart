import 'dart:js_interop';

@JS('localStorage.getItem')
external JSString? _getItem(JSString key);

@JS('localStorage.removeItem')
external void _removeItem(JSString key);

Future<String?> getPendingAnilistToken() async {
  final result = _getItem('anilist_pending_token'.toJS);
  return result?.toDart;
}

Future<void> clearPendingAnilistToken() async {
  _removeItem('anilist_pending_token'.toJS);
}
