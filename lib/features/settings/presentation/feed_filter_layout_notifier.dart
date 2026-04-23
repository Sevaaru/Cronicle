import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/settings/domain/layout_slot.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';

part 'feed_filter_layout_notifier.g.dart';

const feedFilterLayoutDefaultOrder = <String>[
  'anime',
  'manga',
  'movie',
  'tv',
  'game',
  'book',
];

class FeedFilterLayoutState {
  const FeedFilterLayoutState(this.slots);

  final List<LayoutSlot> slots;

  factory FeedFilterLayoutState.initial() => FeedFilterLayoutState(
        feedFilterLayoutDefaultOrder.map((id) => LayoutSlot(id: id)).toList(),
      );

  factory FeedFilterLayoutState.decode(String? raw) {
    const order = feedFilterLayoutDefaultOrder;
    final valid = order.toSet();
    if (raw == null || raw.isEmpty) {
      return FeedFilterLayoutState.initial();
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = <LayoutSlot>[];

      for (final e in list) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final id = m['id'] as String?;
        final vis = m['v'] as bool? ?? true;
        if (id == null) continue;

        if (id == 'following' || id == 'all' || id == 'feed') continue;

        if (!valid.contains(id)) continue;
        if (out.any((s) => s.id == id)) continue;
        out.add(LayoutSlot(id: id, visible: vis));
      }

      for (final id in order) {
        if (!out.any((s) => s.id == id)) {
          out.add(LayoutSlot(id: id));
        }
      }
      return FeedFilterLayoutState(out);
    } catch (_) {
      return FeedFilterLayoutState.initial();
    }
  }

  List<String> get visibleOrderedIds =>
      slots.where((s) => s.visible).map((s) => s.id).toList();

  Set<String> get visibleIdSet => visibleOrderedIds.toSet();

  int get visibleCount => slots.where((s) => s.visible).length;

  String get firstVisibleId {
    for (final s in slots) {
      if (s.visible) return s.id;
    }
    return 'feed';
  }

  FeedFilterLayoutState reorder(int oldIndex, int newIndex) {
    final copy = List<LayoutSlot>.from(slots);
    if (oldIndex < 0 || oldIndex >= copy.length) return this;
    var n = newIndex;
    if (n > oldIndex) n--;
    final item = copy.removeAt(oldIndex);
    n = n.clamp(0, copy.length);
    copy.insert(n, item);
    return FeedFilterLayoutState(copy);
  }

  FeedFilterLayoutState withVisibility(String id, bool visible) {
    if (!visible) {
      final target = slots.where((s) => s.id == id);
      if (target.isEmpty) return this;
      if (visibleCount <= 1 && target.first.visible) return this;
    }
    return FeedFilterLayoutState(
      slots
          .map(
            (s) => s.id == id ? s.copyWith(visible: visible) : s,
          )
          .toList(),
    );
  }

  String encode() => LayoutSlot.encodeList(slots);
}

@Riverpod(keepAlive: true)
class FeedFilterLayout extends _$FeedFilterLayout {
  static const _key = 'feed_filter_layout_v1';

  @override
  FeedFilterLayoutState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return FeedFilterLayoutState.decode(prefs.getString(_key));
  }

  Future<void> set(FeedFilterLayoutState next) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, next.encode());
    state = next;
    final visible = next.visibleIdSet;
    final def = ref.read(defaultFeedTabProvider);
    // 'summary' (Discover) is the synthetic top tab and never appears in
    // the feed filter layout, so it's always valid and must NOT be
    // overwritten when categories change. Only fall back to the first
    // visible category when the saved default is a category that became
    // hidden.
    if (def != 'summary' && !visible.contains(def)) {
      await ref.read(defaultFeedTabProvider.notifier).set(next.firstVisibleId);
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    await set(state.reorder(oldIndex, newIndex));
  }

  Future<void> setVisible(String id, bool visible) async {
    await set(state.withVisibility(id, visible));
  }

  Future<void> reset() async {
    await set(FeedFilterLayoutState.initial());
  }
}
