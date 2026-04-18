import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/settings/domain/layout_slot.dart';

part 'search_filter_layout_notifier.g.dart';

const searchFilterLayoutDefaultOrder = <String>[
  'all',
  'anime',
  'manga',
  'movie',
  'tv',
  'game',
];

Set<String> get _searchFilterValidIds => searchFilterLayoutDefaultOrder.toSet();

class SearchFilterLayoutState {
  const SearchFilterLayoutState(this.slots);

  final List<LayoutSlot> slots;

  factory SearchFilterLayoutState.initial() => SearchFilterLayoutState(
        searchFilterLayoutDefaultOrder
            .map((id) => LayoutSlot(id: id))
            .toList(),
      );

  factory SearchFilterLayoutState.decode(String? raw) =>
      SearchFilterLayoutState(
        LayoutSlot.decodeList(
          raw,
          validIds: _searchFilterValidIds,
          defaultOrder: searchFilterLayoutDefaultOrder,
        ),
      );

  bool isVisible(String id) {
    for (final s in slots) {
      if (s.id == id) return s.visible;
    }
    return true;
  }

  int get visibleCount => slots.where((s) => s.visible).length;

  List<String> get visibleOrderedIds =>
      slots.where((s) => s.visible).map((s) => s.id).toList();

  SearchFilterLayoutState reorder(int oldIndex, int newIndex) {
    final copy = List<LayoutSlot>.from(slots);
    if (oldIndex < 0 || oldIndex >= copy.length) return this;
    var n = newIndex;
    if (n > oldIndex) n--;
    final item = copy.removeAt(oldIndex);
    n = n.clamp(0, copy.length);
    copy.insert(n, item);
    return SearchFilterLayoutState(copy);
  }

  SearchFilterLayoutState withVisibility(String id, bool visible) {
    if (!visible) {
      final target = slots.where((s) => s.id == id);
      if (target.isEmpty) return this;
      if (visibleCount <= 1 && target.first.visible) return this;
    }
    return SearchFilterLayoutState(
      slots
          .map((s) => s.id == id ? s.copyWith(visible: visible) : s)
          .toList(),
    );
  }

  String encode() => LayoutSlot.encodeList(slots);
}

@Riverpod(keepAlive: true)
class SearchFilterLayout extends _$SearchFilterLayout {
  static const _key = 'search_filter_layout_v1';

  @override
  SearchFilterLayoutState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SearchFilterLayoutState.decode(prefs.getString(_key));
  }

  Future<void> set(SearchFilterLayoutState next) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, next.encode());
    state = next;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    await set(state.reorder(oldIndex, newIndex));
  }

  Future<void> setVisible(String id, bool visible) async {
    await set(state.withVisibility(id, visible));
  }

  Future<void> reset() async {
    await set(SearchFilterLayoutState.initial());
  }
}
