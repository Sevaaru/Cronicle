String anilistMediaDisplayTitle(Map<String, dynamic> media) {
  final t = media['title'] as Map<String, dynamic>? ?? {};
  String? pick(String key) {
    final s = t[key] as String?;
    if (s == null) return null;
    final v = s.trim();
    return v.isEmpty ? null : v;
  }

  return pick('english') ?? pick('romaji') ?? pick('native') ?? 'Media';
}
