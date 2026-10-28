import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/settings/domain/layout_slot.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/library_kind_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/search_filter_layout_notifier.dart';

part 'onboarding_notifier.g.dart';

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

    final feedSlots = feedFilterLayoutDefaultOrder.map((id) {
      if (id == 'feed') return LayoutSlot(id: id);
      return LayoutSlot(id: id, visible: selectedInterests.contains(id));
    }).toList();
    final feedState = FeedFilterLayoutState(feedSlots);
    await ref.read(feedFilterLayoutProvider.notifier).set(feedState);

    final libSlots = libraryKindLayoutDefaultOrder.map((id) {
      if (id == 'all') return LayoutSlot(id: id);
      return LayoutSlot(id: id, visible: selectedInterests.contains(id));
    }).toList();
    final libState = LibraryKindLayoutState(libSlots);
    await ref.read(libraryKindLayoutProvider.notifier).set(libState);

    final searchSlots = searchFilterLayoutDefaultOrder.map((id) {
      if (id == 'all') return LayoutSlot(id: id);
      return LayoutSlot(id: id, visible: selectedInterests.contains(id));
    }).toList();
    final searchState = SearchFilterLayoutState(searchSlots);
    await ref.read(searchFilterLayoutProvider.notifier).set(searchState);

    // Force the landing tab to Discover after onboarding regardless of any
    // implicit defaults written elsewhere. The user can still change it
    // afterwards from Settings; this guarantees first-launch lands on
    // Discover even if the layout notifier or a backup restore touched the
    // default tab key.
    await ref.read(defaultFeedTabProvider.notifier).set('summary');

    // Signal a one-shot “cartridge” intro the next time the app shell
    // mounts (post-setup transition). The shell consumes & clears it.
    await prefs.setBool('pending_post_setup_intro_v1', true);

    await prefs.setBool(_key, true);
    state = true;
  }

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
