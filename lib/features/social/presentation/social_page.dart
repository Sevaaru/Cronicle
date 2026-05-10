import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/feed/presentation/activity_feed_widgets.dart';
import 'package:cronicle/features/social/presentation/forum_feed_tab.dart';
import 'package:cronicle/features/social/presentation/social_steam_providers.dart';
import 'package:cronicle/features/social/presentation/social_unified_feed.dart';
import 'package:cronicle/features/steam/presentation/steam_providers.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

enum _SocialActivityType {
  all,
  status,
  anime,
  manga;

  String? get apiValue => switch (this) {
        _SocialActivityType.all => null,
        _SocialActivityType.status => 'TEXT',
        _SocialActivityType.anime => 'ANIME_LIST',
        _SocialActivityType.manga => 'MANGA_LIST',
      };
}

/// Modo del feed Social: separa fuente AniList vs Steam.
///  - [anilist] -> AniList (con sub-toggle Siguiendo/Global)
///  - [steam]   -> Actividad de amigos de Steam (requiere sesión Steam)
enum _SocialMode { anilist, steam }

class _SocialPageState extends ConsumerState<SocialPage>
    with SingleTickerProviderStateMixin {
  _SocialMode _mode = _SocialMode.anilist;
  bool _anilistGlobal = false;
  bool _scopeInitialized = false;
  _SocialActivityType _activityType = _SocialActivityType.all;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setMode(_SocialMode next) {
    setState(() => _mode = next);
  }

  void _setAnilistGlobal(bool global) {
    setState(() => _anilistGlobal = global);
    ref.read(defaultFeedActivityScopeProvider.notifier).set(
          global ? 'global' : 'following',
        );
  }

  Future<void> _invalidate() async {
    try {
      // Si el notifier sigue vivo, refrescamos directo. Pasamos force=true
      // para que un pull-to-refresh manual no quede silenciado por el
      // bug-guard que conserva la lista previa cuando AniList responde 0
      // ítems de forma transitoria.
      await ref
          .read(
            anilistSocialFeedProvider(_activityType.apiValue, _isFollowing)
                .notifier,
          )
          .refresh(force: true);
    } catch (_) {
      // Fallback: invalidamos provider para forzar recarga limpia.
      ref.invalidate(
        anilistSocialFeedProvider(_activityType.apiValue, _isFollowing),
      );
    }
  }

  void _loadMore() {
    ref
        .read(
          anilistSocialFeedProvider(_activityType.apiValue, _isFollowing)
              .notifier,
        )
        .loadMore();
  }

  bool get _isFollowing =>
      _mode == _SocialMode.steam ? true : !_anilistGlobal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final gamesInterest = ref.watch(socialGamesInterestProvider);
    final steamSession = ref.watch(steamSessionProvider).valueOrNull;
    final steamConnected = steamSession?.connected ?? false;
    final steamModeAvailable = gamesInterest && steamConnected;

    if (!_scopeInitialized) {
      // Lo leemos una vez para no resetear el filtro en cada rebuild.
      final scopeStr = ref.read(defaultFeedActivityScopeProvider);
      _anilistGlobal = scopeStr == 'global';
      _scopeInitialized = true;
    }
    // Si el usuario perdió Steam y estaba en modo Steam, lo reubicamos en
    // AniList para no quedar en blanco.
    if (_mode == _SocialMode.steam && !steamModeAvailable) {
      _mode = _SocialMode.anilist;
    }

    final cs = Theme.of(context).colorScheme;

    final feedProvider =
        anilistSocialFeedProvider(_activityType.apiValue, _isFollowing);

    // Cada modo activa exactamente una fuente.
    final includeAnilist = _mode == _SocialMode.anilist;
    final includeSteamFriends = _mode == _SocialMode.steam && steamModeAvailable;
    // Las noticias Steam se inyectan junto a AniList Global (único sitio donde
    // "Global" tiene sentido fuera de los amigos).
    final includeSteamNews =
        _mode == _SocialMode.anilist && _anilistGlobal && gamesInterest;

    final scopeBar = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _CompactScopeChip(
            selected: _mode == _SocialMode.anilist,
            icon: Icons.movie_filter_rounded,
            label: l10n.socialSourceAnilist,
            onTap: () => _setMode(_SocialMode.anilist),
          ),
          if (steamModeAvailable) ...[
            const SizedBox(width: 6),
            _CompactScopeChip(
              selected: _mode == _SocialMode.steam,
              icon: Icons.sports_esports_rounded,
              label: l10n.socialSourceSteam,
              onTap: () => _setMode(_SocialMode.steam),
            ),
          ],
          const Spacer(),
          if (_mode == _SocialMode.anilist) ...[
            _ScopeDropdown(
              isGlobal: _anilistGlobal,
              cs: cs,
              l10n: l10n,
              onChanged: _setAnilistGlobal,
            ),
            const SizedBox(width: 6),
            _ActivityTypeDropdown(
              value: _activityType,
              cs: cs,
              l10n: l10n,
              onChanged: (t) => setState(() => _activityType = t),
              compact: true,
            ),
          ],
        ],
      ),
    );

    Widget buildBody() {
      return SocialUnifiedFeed(
        header: scopeBar,
        isFollowing: _isFollowing,
        includeAnilist: includeAnilist,
        includeSteamFriends: includeSteamFriends,
        includeSteamNews: includeSteamNews,
        activityTypeApi: _activityType.apiValue,
        onRefresh: _invalidate,
        onLoadMore: _loadMore,
        hasMore: () {
          try {
            return ref.read(feedProvider.notifier).hasMore;
          } catch (_) {
            return false;
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.none,
        leading: const ProfileAvatarButton(),
        leadingWidth: kProfileLeadingWidth,
        titleSpacing: 0,
        title: Text(l10n.socialTitle, style: pageTitleStyle()),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: SizedBox(
              width: 200,
              child: _SocialSegmentedTabs(
                controller: _tabController,
                labels: [l10n.socialFeedTab, l10n.socialForumTab],
                icons: const [
                  Icons.dynamic_feed_rounded,
                  Icons.forum_rounded,
                ],
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          buildBody(),
          const ForumFeedTab(),
        ],
      ),
    );
  }
}

class _ActivityTypeDropdown extends StatelessWidget {
  const _ActivityTypeDropdown({
    required this.value,
    required this.cs,
    required this.l10n,
    required this.onChanged,
    this.compact = false,
  });

  final _SocialActivityType value;
  final ColorScheme cs;
  final AppLocalizations l10n;
  final ValueChanged<_SocialActivityType> onChanged;

  /// When true, hide the textual label and only show the icon + chevron
  /// so the control fits next to other filters in a single row.
  final bool compact;

  String _label(_SocialActivityType t) => switch (t) {
        _SocialActivityType.all => l10n.filterAll,
        _SocialActivityType.status => l10n.filterStatus,
        _SocialActivityType.anime => l10n.filterAnime,
        _SocialActivityType.manga => l10n.filterManga,
      };

  IconData _icon(_SocialActivityType t) => switch (t) {
        _SocialActivityType.all => Icons.dynamic_feed_rounded,
        _SocialActivityType.status => Icons.chat_bubble_outline_rounded,
        _SocialActivityType.anime => Icons.animation_rounded,
        _SocialActivityType.manga => Icons.menu_book_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SocialActivityType>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: compact ? _label(value) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: PopupMenuPosition.under,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(value), size: 16, color: cs.primary),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(
                _label(value),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded,
                size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
      itemBuilder: (_) => _SocialActivityType.values.map((t) {
        final isSelected = t == value;
        return PopupMenuItem<_SocialActivityType>(
          value: t,
          child: Row(
            children: [
              Icon(_icon(t),
                  size: 18,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(
                _label(t),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_rounded, size: 18, color: cs.primary),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Compact pill toggle for the Following / Global scope chips. Smaller
/// than a Material `FilterChip` so both chips + the source filter +
/// activity dropdown all fit in a single row even on narrow phones.
class _CompactScopeChip extends StatelessWidget {
  const _CompactScopeChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primary : cs.surfaceContainerHigh;
    final fg = selected ? cs.onPrimary : cs.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown compacto Siguiendo / Global para el scope de AniList.
class _ScopeDropdown extends StatelessWidget {
  const _ScopeDropdown({
    required this.isGlobal,
    required this.cs,
    required this.l10n,
    required this.onChanged,
  });

  final bool isGlobal;
  final ColorScheme cs;
  final AppLocalizations l10n;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final icon = isGlobal ? Icons.public_rounded : Icons.people_rounded;
    final label = isGlobal ? l10n.filterGlobal : l10n.filterFollowing;
    return PopupMenuButton<bool>(
      initialValue: isGlobal,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: PopupMenuPosition.under,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded,
                size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem<bool>(
          value: false,
          child: Row(children: [
            Icon(Icons.people_rounded,
                size: 18,
                color: !isGlobal ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(l10n.filterFollowing,
                style: TextStyle(
                    fontWeight:
                        !isGlobal ? FontWeight.w600 : FontWeight.w400,
                    color: !isGlobal ? cs.primary : cs.onSurface)),
            const Spacer(),
            if (!isGlobal) Icon(Icons.check_rounded, size: 16, color: cs.primary),
          ]),
        ),
        PopupMenuItem<bool>(
          value: true,
          child: Row(children: [
            Icon(Icons.public_rounded,
                size: 18,
                color: isGlobal ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(l10n.filterGlobal,
                style: TextStyle(
                    fontWeight:
                        isGlobal ? FontWeight.w600 : FontWeight.w400,
                    color: isGlobal ? cs.primary : cs.onSurface)),
            const Spacer(),
            if (isGlobal) Icon(Icons.check_rounded, size: 16, color: cs.primary),
          ]),
        ),
      ],
    );
  }
}

/// Material 3 expressive segmented control for the Feed/Forum switcher.
/// Uses an animated sliding pill instead of the default TabBar underline,
/// and only changes tab on tap (swipe is disabled at the TabBarView level).
class _SocialSegmentedTabs extends StatefulWidget {
  const _SocialSegmentedTabs({
    required this.controller,
    required this.labels,
    required this.icons,
  });

  final TabController controller;
  final List<String> labels;
  final List<IconData> icons;

  @override
  State<_SocialSegmentedTabs> createState() => _SocialSegmentedTabsState();
}

class _SocialSegmentedTabsState extends State<_SocialSegmentedTabs> {
  @override
  void initState() {
    super.initState();
    widget.controller.animation?.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.animation?.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = widget.controller.animation?.value ?? 0.0;

    return LayoutBuilder(builder: (context, constraints) {
      final segWidth = constraints.maxWidth / widget.labels.length;
      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              left: value.clamp(0.0, widget.labels.length - 1.0) * segWidth + 3,
              top: 3,
              bottom: 3,
              width: segWidth - 6,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
            Row(
              children: List.generate(widget.labels.length, (i) {
                final t = (1.0 - (value - i).abs()).clamp(0.0, 1.0);
                final fg = Color.lerp(cs.onSurfaceVariant, cs.onPrimary, t)!;
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: () => widget.controller.animateTo(i),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icons[i], size: 16, color: fg),
                            const SizedBox(width: 6),
                            Text(
                              widget.labels[i],
                              style: TextStyle(
                                color: fg,
                                fontSize: 12,
                                fontWeight: t > 0.5
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}
