import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/settings/domain/layout_slot.dart';
import 'package:cronicle/shared/models/media_kind.dart';

part 'library_kind_layout_notifier.g.dart';

/// Ids: `all` + [MediaKind.name] (orden por defecto alineado con la lista horizontal).
const libraryKindLayoutDefaultOrder = <String>[
  'all',
  'anime',
  'movie',
  'tv',
  'game',
  'manga',
  'book',
];

Set<String> get _libraryKindValidIds => libraryKindLayoutDefaultOrder.toSet();

MediaKind? _mediaKindFromSlotId(String id) {
  if (id == 'all') return null;
  try {
    return MediaKind.values.byName(id);
  } catch (_) {
    return null;
  }
}

class LibraryKindLayoutState {
  const LibraryKindLayoutState(this.slots);

  final List<LayoutSlot> slots;

  factory LibraryKindLayoutState.initial() => LibraryKindLayoutState(
        libraryKindLayoutDefaultOrder.map((id) => LayoutSlot(id: id)).toList(),
      );

  factory LibraryKindLayoutState.decode(String? raw) => LibraryKindLayoutState(
        LayoutSlot.decodeList(
          raw,
          validIds: _libraryKindValidIds,
          defaultOrder: libraryKindLayoutDefaultOrder,
        ),
      );

  bool isVisible(String id) {
    for (final s in slots) {
      if (s.id == id) return s.visible;
    }
    return true;
  }

  int get visibleCount => slots.where((s) => s.visible).length;

  /// Primer tipo de medio visible distinto de «all».
  MediaKind? get firstVisibleKind {
    for (final s in slots) {
      if (!s.visible || s.id == 'all') continue;
      final k = _mediaKindFromSlotId(s.id);
      if (k != null) return k;
    }
    return null;
  }

  LibraryKindLayoutState reorder(int oldIndex, int newIndex) {
    final copy = List<LayoutSlot>.from(slots);
    if (oldIndex < 0 || oldIndex >= copy.length) return this;
    var n = newIndex;
    if (n > oldIndex) n--;
    final item = copy.removeAt(oldIndex);
    n = n.clamp(0, copy.length);
    copy.insert(n, item);
    return LibraryKindLayoutState(copy);
  }

  LibraryKindLayoutState withVisibility(String id, bool visible) {
    if (!visible) {
      final target = slots.where((s) => s.id == id);
      if (target.isEmpty) return this;
      if (visibleCount <= 1 && target.first.visible) return this;
    }
    return LibraryKindLayoutState(
      slots
          .map((s) => s.id == id ? s.copyWith(visible: visible) : s)
          .toList(),
    );
  }

  String encode() => LayoutSlot.encodeList(slots);
}

@Riverpod(keepAlive: true)
class LibraryKindLayout extends _$LibraryKindLayout {
  static const _key = 'library_kind_layout_v1';

  @override
  LibraryKindLayoutState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return LibraryKindLayoutState.decode(prefs.getString(_key));
  }

  Future<void> set(LibraryKindLayoutState next) async {
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
    await set(LibraryKindLayoutState.initial());
  }
}
