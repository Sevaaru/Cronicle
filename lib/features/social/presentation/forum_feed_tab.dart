import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';

enum _ForumCategory {
  all(null, 'All', Icons.forum_rounded),
  general(7, 'General', Icons.chat_rounded),
  anime(1, 'Anime', Icons.animation_rounded),
  manga(2, 'Manga', Icons.menu_book_rounded),
  releaseDiscussion(5, 'Release Discussion', Icons.new_releases_rounded),
  siteAnnouncements(13, 'Site Announcements', Icons.campaign_rounded),
  news(8, 'News', Icons.newspaper_rounded),
  music(9, 'Music', Icons.music_note_rounded),
  gaming(10, 'Gaming', Icons.sports_esports_rounded),
  visualNovels(4, 'Visual Novels', Icons.auto_stories_rounded),
  lightNovels(3, 'Light Novels', Icons.book_rounded),
  forumGames(16, 'Forum Games', Icons.casino_rounded),
  recommendations(15, 'Recommendations', Icons.recommend_rounded),
  siteFeedback(11, 'Site Feedback', Icons.feedback_rounded),
  bugReports(12, 'Bug Reports', Icons.bug_report_rounded),
  anilistApps(18, 'AniList Apps', Icons.apps_rounded),
  misc(17, 'Misc', Icons.more_horiz_rounded);

  const _ForumCategory(this.id, this.label, this.icon);
  final int? id;
  final String label;
  final IconData icon;
}

class ForumFeedTab extends ConsumerStatefulWidget {
  const ForumFeedTab({super.key});

  @override
  ConsumerState<ForumFeedTab> createState() => _ForumFeedTabState();
}

class _ForumFeedTabState extends ConsumerState<ForumFeedTab>
    with AutomaticKeepAliveClientMixin {
  _ForumCategory _category = _ForumCategory.all;

  List<Map<String, dynamic>>? _stickyThreads;
  List<Map<String, dynamic>>? _recentlyReplied;
  List<Map<String, dynamic>>? _newlyCreated;
  List<Map<String, dynamic>>? _releaseDiscussions;
  bool _loading = true;
  String? _error;

  final _searchController = TextEditingController();
  List<Map<String, dynamic>>? _searchResults;
  bool _searching = false;
  String? _searchError;
  bool get _isSearchActive => _searchController.text.trim().isNotEmpty;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final feed = await graphql.fetchForumFeed(categoryId: _category.id);

      if (!mounted) return;
      setState(() {
        _stickyThreads = feed['sticky'];
        _recentlyReplied = feed['recent'];
        _newlyCreated = feed['newest'];
        _releaseDiscussions = feed['releases'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _onCategoryChanged(_ForumCategory cat) {
    if (cat == _category) return;
    setState(() => _category = cat);
    if (_isSearchActive) {
      _doSearch(_searchController.text.trim());
    } else {
      _loadAll();
    }
  }

  Future<void> _doSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _searchError = null;
      });
      _loadAll();
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final results = await graphql.searchForumThreads(
        search: query,
        categoryId: _category.id,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = '$e';
      });
    }
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _clearSearch();
      return;
    }
    _doSearch(trimmed);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = null;
      _searchError = null;
      _searching = false;
    });
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5 - 16,
                child: _ForumCategoryDropdown(
                  current: _category,
                  onChanged: _onCategoryChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _onSearchSubmitted,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant.withAlpha(150),
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 36, minHeight: 0),
                      suffixIcon: _isSearchActive
                          ? GestureDetector(
                              onTap: _clearSearch,
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: cs.onSurfaceVariant),
                            )
                          : null,
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 32, minHeight: 0),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      filled: true,
                      fillColor:
                          cs.surfaceContainerHighest.withValues(alpha: .5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isSearchActive
              ? _buildSearchResults(cs, l10n)
              : _buildFeedContent(cs, l10n),
        ),
      ],
    );
  }

  Widget _buildSearchResults(ColorScheme cs, AppLocalizations l10n) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: cs.onSurfaceVariant.withAlpha(120)),
            const SizedBox(height: 12),
            Text(_searchError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _doSearch(_searchController.text.trim()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.feedRetry),
            ),
          ],
        ),
      );
    }
    final results = _searchResults;
    if (results == null || results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: cs.onSurfaceVariant.withAlpha(120)),
            const SizedBox(height: 12),
            Text('No results',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(12, 0, 12, kGlassBottomNavContentHeight + 24),
        itemCount: results.length,
        itemBuilder: (_, i) => _ForumThreadTile(thread: results[i], cs: cs),
      ),
    );
  }

  Widget _buildFeedContent(ColorScheme cs, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: cs.onSurfaceVariant.withAlpha(120)),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.feedRetry),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, 0, 12, kGlassBottomNavContentHeight + 24),
        children: [
          if (_stickyThreads != null &&
              _stickyThreads!.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.push_pin_rounded,
              title: l10n.forumPinnedThreads,
              cs: cs,
            ),
            const SizedBox(height: 6),
            ..._stickyThreads!
                .map((t) => _ForumThreadTile(
                    thread: t, cs: cs, pinned: true)),
            const SizedBox(height: 16),
          ],

          if (_recentlyReplied != null &&
              _recentlyReplied!.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.forum_rounded,
              title: l10n.forumRecentlyReplied,
              cs: cs,
            ),
            const SizedBox(height: 6),
            ..._recentlyReplied!.map(
                (t) => _ForumThreadTile(thread: t, cs: cs)),
            const SizedBox(height: 16),
          ],

          if (_newlyCreated != null &&
              _newlyCreated!.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.fiber_new_rounded,
              title: l10n.forumNewlyCreated,
              cs: cs,
            ),
            const SizedBox(height: 6),
            ..._newlyCreated!.map(
                (t) => _ForumThreadTile(thread: t, cs: cs)),
            const SizedBox(height: 16),
          ],

          if (_releaseDiscussions != null &&
              _releaseDiscussions!.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.new_releases_rounded,
              title: l10n.forumReleaseDiscussions,
              cs: cs,
            ),
            const SizedBox(height: 6),
            ..._releaseDiscussions!.map(
                (t) => _ForumThreadTile(thread: t, cs: cs)),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ForumCategoryDropdown extends StatelessWidget {
  const _ForumCategoryDropdown({
    required this.current,
    required this.onChanged,
  });

  final _ForumCategory current;
  final ValueChanged<_ForumCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<_ForumCategory>(
      onSelected: onChanged,
      constraints: const BoxConstraints(maxHeight: 400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: PopupMenuPosition.under,
      itemBuilder: (_) => _ForumCategory.values.map((cat) {
        final selected = cat == current;
        return PopupMenuItem(
          value: cat,
          child: Row(
            children: [
              Icon(cat.icon, size: 18,
                  color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(cat.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? cs.primary : null,
                    )),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 16, color: cs.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(current.icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(current.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.cs,
  });

  final IconData icon;
  final String title;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

String _forumTimeAgo(int? ts) {
  if (ts == null) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 365) return '${diff.inDays ~/ 365}a';
  if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  return '${diff.inMinutes}min';
}

class _ForumThreadTile extends StatelessWidget {
  const _ForumThreadTile({
    required this.thread,
    required this.cs,
    this.pinned = false,
  });

  final Map<String, dynamic> thread;
  final ColorScheme cs;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final id = thread['id'] as int?;
    final title = thread['title'] as String? ?? '';
    final replyCount = thread['replyCount'] as int? ?? 0;
    final viewCount = thread['viewCount'] as int? ?? 0;
    final repliedAt = thread['repliedAt'] as int?;
    final createdAt = thread['createdAt'] as int?;
    final isSticky = thread['isSticky'] as bool? ?? false;
    final isLocked = thread['isLocked'] as bool? ?? false;
    final user = thread['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? '';
    final avatar = (user?['avatar'] as Map?)?['medium'] as String?;
    final categories =
        (thread['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final categoryName =
        categories.isNotEmpty ? categories.first['name'] as String? : null;

    final timeAgo = _forumTimeAgo(repliedAt ?? createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: id == null
              ? null
              : () => context.push('/forum/thread/$id', extra: thread),
          splashColor: cs.primary.withValues(alpha: 0.10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSticky && pinned)
                      Container(
                        margin: const EdgeInsets.only(right: 8, top: 1),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.push_pin_rounded,
                            size: 14, color: cs.primary),
                      ),
                    if (isLocked)
                      Container(
                        margin: const EdgeInsets.only(right: 8, top: 1),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.lock_rounded,
                            size: 14, color: cs.onSurfaceVariant),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (avatar != null)
                      ClipOval(
                        child: CachedNetworkImage(
                            imageUrl: avatar,
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_rounded,
                            size: 14, color: cs.onSurfaceVariant),
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (timeAgo.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('· $timeAgo',
                          style: TextStyle(
                              fontSize: 11.5, color: cs.onSurfaceVariant)),
                    ],
                    if (categoryName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    _ForumStatChip(
                      icon: Icons.mode_comment_outlined,
                      value: replyCount,
                      cs: cs,
                    ),
                    const SizedBox(width: 6),
                    _ForumStatChip(
                      icon: Icons.visibility_outlined,
                      value: viewCount,
                      cs: cs,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForumStatChip extends StatelessWidget {
  const _ForumStatChip({
    required this.icon,
    required this.value,
    required this.cs,
  });

  final IconData icon;
  final int value;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
