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
