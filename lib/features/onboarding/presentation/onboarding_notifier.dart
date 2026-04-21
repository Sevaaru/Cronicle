import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/settings/domain/layout_slot.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/library_kind_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/search_filter_layout_notifier.dart';

part 'onboarding_notifier.g.dart';

/// Interest IDs matching MediaKind names.
const onboardingInterestIds = ['anime', 'manga', 'movie', 'tv', 'game', 'book'];

@Riverpod(keepAlive: true)
class OnboardingCompleted extends _$OnboardingCompleted {
  static const _key = 'onboarding_completed';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> complete(Set<String> selectedInterests) async {
    final prefs = ref.read(sharedPreferencesProvider);

    // --- Feed layout: hide unselected media types, keep 'feed' visible ---
    final feedSlots = feedFilterLayoutDefaultOrder.map((id) {
      if (id == 'feed') return LayoutSlot(id: id);
      return LayoutSlot(id: id, visible: selectedInterests.contains(id));
    }).toList();
    final feedState = FeedFilterLayoutState(feedSlots);
    await ref.read(feedFilterLayoutProvider.notifier).set(feedState);

    // --- Library layout: hide unselected, keep 'all' visible ---
    final libSlots = libraryKindLayoutDefaultOrder.map((id) {
      if (id == 'all') return LayoutSlot(id: id);
      return LayoutSlot(id: id, visible: selectedInterests.contains(id));
    }).toList();
    final libState = LibraryKindLayoutState(libSlots);
    await ref.read(libraryKindLayoutProvider.notifier).set(libState);

    // --- Search layout: hide unselected, keep 'all' visible ---
    final searchSlots = searchFilterLayoutDefaultOrder.map((id) {
      if (id == 'all') return LayoutSlot(id: id);
      return LayoutSlot(id: id, visible: selectedInterests.contains(id));
    }).toList();
    final searchState = SearchFilterLayoutState(searchSlots);
    await ref.read(searchFilterLayoutProvider.notifier).set(searchState);

    // Mark onboarding as done
    await prefs.setBool(_key, true);
    state = true;
  }

  /// Re-apply interest changes from settings (same logic as [complete]).
  Future<void> updateInterests(Set<String> selectedInterests) async {
    final feedSlots = feedFilterLayoutDefaultOrder.map((id) {
      if (id == 'feed') return LayoutSlot(id: id);
      return LayoutSlot(id: id, visible: selectedInterests.contains(id));
    }).toList();
    await ref
        .read(feedFilterLayoutProvider.notifier)
        .set(FeedFilterLayoutState(feedSlots));

    final libSlots = libraryKindLayoutDefaultOrder.map((id) {
      if (id == 'all') return LayoutSlot(id: id);
      return LayoutSlot(id: id, visible: selectedInterests.contains(id));
    }).toList();
    await ref
        .read(libraryKindLayoutProvider.notifier)
        .set(LibraryKindLayoutState(libSlots));

    final searchSlots = searchFilterLayoutDefaultOrder.map((id) {
      if (id == 'all') return LayoutSlot(id: id);
      return LayoutSlot(id: id, visible: selectedInterests.contains(id));
    }).toList();
    await ref
        .read(searchFilterLayoutProvider.notifier)
        .set(SearchFilterLayoutState(searchSlots));
  }
}
