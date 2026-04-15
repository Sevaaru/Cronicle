import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/library_kind_layout_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

String _feedFilterTitle(String id, AppLocalizations l10n) => switch (id) {
      'following' => l10n.filterFollowing,
      'all' => l10n.filterGlobal,
      'anime' => l10n.filterAnime,
      'manga' => l10n.filterManga,
      'movie' => l10n.filterMovies,
      'tv' => l10n.filterTv,
      'game' => l10n.filterGames,
      _ => id,
    };

class FeedFilterLayoutEditorPage extends ConsumerWidget {
  const FeedFilterLayoutEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final layout = ref.watch(feedFilterLayoutProvider);
    final slots = layout.slots;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsCustomizeFeedFilters),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(feedFilterLayoutProvider.notifier).reset();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.settingsLayoutResetDone)),
                );
              }
            },
            child: Text(l10n.settingsLayoutReset),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            l10n.settingsCustomizeFeedFiltersDesc,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.settingsLayoutDragHint,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withAlpha(200)),
          ),
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: slots.length,
            onReorder: (oldI, newI) =>
                ref.read(feedFilterLayoutProvider.notifier).reorder(oldI, newI),
            itemBuilder: (context, i) {
              final s = slots[i];
              return Card(
                key: ValueKey(s.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: i,
                    child: Icon(Icons.drag_handle_rounded, color: cs.onSurfaceVariant),
                  ),
                  title: Text(_feedFilterTitle(s.id, l10n)),
                  subtitle: Text(
                    l10n.settingsLayoutShowInFeed,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  trailing: Switch.adaptive(
                    value: s.visible,
                    onChanged: layout.visibleCount <= 1 && s.visible
                        ? null
                        : (v) => ref
                            .read(feedFilterLayoutProvider.notifier)
                            .setVisible(s.id, v),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LibraryKindLayoutEditorPage extends ConsumerWidget {
  const LibraryKindLayoutEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final layout = ref.watch(libraryKindLayoutProvider);
    final slots = layout.slots;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsCustomizeLibraryKinds),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(libraryKindLayoutProvider.notifier).reset();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.settingsLayoutResetDone)),
                );
              }
            },
            child: Text(l10n.settingsLayoutReset),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            l10n.settingsCustomizeLibraryKindsDesc,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.settingsLayoutDragHint,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withAlpha(200)),
          ),
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: slots.length,
            onReorder: (oldI, newI) =>
                ref.read(libraryKindLayoutProvider.notifier).reorder(oldI, newI),
            itemBuilder: (context, i) {
              final s = slots[i];
              final title = s.id == 'all'
                  ? l10n.filterAll
                  : mediaKindLabel(_mediaKindFromId(s.id)!, l10n);
              return Card(
                key: ValueKey(s.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: i,
                    child: Icon(Icons.drag_handle_rounded, color: cs.onSurfaceVariant),
                  ),
                  title: Text(title),
                  subtitle: Text(
                    l10n.settingsLayoutShowInLibrary,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  trailing: Switch.adaptive(
                    value: s.visible,
                    onChanged: layout.visibleCount <= 1 && s.visible
                        ? null
                        : (v) => ref
                            .read(libraryKindLayoutProvider.notifier)
                            .setVisible(s.id, v),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

MediaKind? _mediaKindFromId(String id) {
  try {
    return MediaKind.values.byName(id);
  } catch (_) {
    return null;
  }
}
