/// Anilist stores [contexts] as ordered fragments ([String], sometimes nested
/// [List]s). Joining only the top level with spaces breaks templates (e.g.
/// missing episode numbers). Walk the structure and concatenate in order;
/// fragments already include spacing where Anilist expects it.
String anilistFlattenContexts(dynamic raw) {
  if (raw == null) return '';
  final out = StringBuffer();

  void walk(dynamic x) {
    if (x == null) return;
    if (x is String) {
      out.write(x);
    } else if (x is num || x is bool) {
      out.write(x.toString());
    } else if (x is List) {
      for (final e in x) {
        walk(e);
      }
    } else {
      out.write(x.toString());
    }
  }

  walk(raw);
  return out.toString();
}
