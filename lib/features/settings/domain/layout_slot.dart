import 'dart:convert';

class LayoutSlot {
  const LayoutSlot({required this.id, this.visible = true});

  final String id;
  final bool visible;

  LayoutSlot copyWith({bool? visible}) =>
      LayoutSlot(id: id, visible: visible ?? this.visible);

  Map<String, dynamic> toJson() => {'id': id, 'v': visible};

  static LayoutSlot fromJson(Map<String, dynamic> m) => LayoutSlot(
        id: m['id'] as String,
        visible: m['v'] as bool? ?? true,
      );

  static String encodeList(List<LayoutSlot> slots) =>
      jsonEncode(slots.map((e) => e.toJson()).toList());

  static List<LayoutSlot> decodeList(
    String? raw, {
    required Set<String> validIds,
    required List<String> defaultOrder,
  }) {
    if (raw == null || raw.isEmpty) {
      return defaultOrder.map((id) => LayoutSlot(id: id)).toList();
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final seen = <String>{};
      final out = <LayoutSlot>[];
      for (final e in list) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final id = m['id'] as String?;
        if (id == null || seen.contains(id) || !validIds.contains(id)) {
          continue;
        }
        seen.add(id);
        out.add(LayoutSlot.fromJson(m));
      }
      for (final id in defaultOrder) {
        if (!seen.contains(id)) {
          out.add(LayoutSlot(id: id));
        }
      }
      return out;
    } catch (_) {
      return defaultOrder.map((id) => LayoutSlot(id: id)).toList();
    }
  }
}
