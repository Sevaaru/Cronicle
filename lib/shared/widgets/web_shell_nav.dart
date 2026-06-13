import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/features/identity/presentation/cronicle_auth_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/layout/shell_layout.dart';
import 'package:cronicle/shared/profile/profile_avatar_provider.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';

/// Fixed left rail for wide web viewports (X / Twitter–style).
class WebSideNavigation extends ConsumerWidget {
  const WebSideNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cs.surface,
      child: Container(
        width: kWebSideNavWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
            ),
          ),
        ),
        child: SafeArea(
          right: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WebBrandMark(onTap: () => onTap(0)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _XNavTile(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () => onTap(i),
                          compact: false,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const _WebShellProfileFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar for medium-width web viewports.
class WebTopNavigation extends StatelessWidget {
  const WebTopNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cs.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _WebBrandMark(onTap: () => onTap(0), compact: true),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          _XNavTile(
                            item: items[i],
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const _WebShellProfileFooter(compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebBrandMark extends StatefulWidget {
  const _WebBrandMark({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  State<_WebBrandMark> createState() => _WebBrandMarkState();
}

class _WebBrandMarkState extends State<_WebBrandMark> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          hoverColor: Colors.transparent,
          splashColor: cs.primary.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: widget.compact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: _hover
                  ? cs.onSurface.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: widget.compact ? 26 : 32,
                  color: cs.primary,
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Cronicle',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _XNavTile extends StatefulWidget {
  const _XNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_XNavTile> createState() => _XNavTileState();
}

class _XNavTileState extends State<_XNavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final fg = selected ? cs.onSurface : cs.onSurfaceVariant;

    final content = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          hoverColor: Colors.transparent,
          splashColor: cs.primary.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            margin: widget.compact
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(vertical: 2),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 12 : 16,
              vertical: widget.compact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: (_hover || selected)
                  ? cs.onSurface.withValues(alpha: selected ? 0.1 : 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(
                  selected ? widget.item.activeIcon : widget.item.icon,
                  size: widget.compact ? 22 : 26,
                  color: fg,
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: -0.3,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.item.itemKey != null) {
      return KeyedSubtree(key: widget.item.itemKey, child: content);
    }
    return content;
  }
}

class _WebShellProfileFooter extends ConsumerStatefulWidget {
  const _WebShellProfileFooter({this.compact = false});

  final bool compact;

  @override
  ConsumerState<_WebShellProfileFooter> createState() =>
      _WebShellProfileFooterState();
}

class _WebShellProfileFooterState extends ConsumerState<_WebShellProfileFooter> {
  bool _hover = false;

  void _openProfile() {
    context.push('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final resolvedAvatar = ref.watch(resolvedProfileAvatarProvider);
    final cronicleProfile = EnvConfig.hasSupabase
        ? ref.watch(cronicleMyProfileProvider).valueOrNull
        : null;
    final cronicleSession = EnvConfig.hasSupabase
        ? ref.watch(cronicleAuthSessionProvider).valueOrNull
        : null;

    final username = cronicleProfile?.username.trim() ?? '';
    final displayName = cronicleProfile?.displayName.trim() ?? '';
    final email = cronicleSession?.user.email?.trim() ?? '';

    final title = displayName.isNotEmpty
        ? displayName
        : (username.isNotEmpty
            ? '@$username'
            : (email.isNotEmpty ? email : l10n.profileTitle));

    final subtitle = username.isNotEmpty && displayName.isNotEmpty
        ? '@$username'
        : l10n.profileTitle;

    final avatarUrl = cronicleProfile?.avatarUrl?.trim().isNotEmpty == true
        ? cronicleProfile!.avatarUrl
        : resolvedAvatar.networkUrl;
    final avatarBytes = resolvedAvatar.memoryBytes;

    final avatar = ClipOval(
      child: ColoredBox(
        color: cs.surfaceContainerHighest,
        child: avatarBytes != null
            ? Image.memory(
                avatarBytes,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              )
            : (avatarUrl != null && avatarUrl.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )
                : SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.person, color: cs.onSurfaceVariant),
                  ),
      ),
    );

    if (widget.compact) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openProfile,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _hover
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: avatar,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openProfile,
          borderRadius: BorderRadius.circular(999),
          hoverColor: Colors.transparent,
          splashColor: cs.primary.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _hover
                  ? cs.onSurface.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
