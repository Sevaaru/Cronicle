import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/achievements/domain/achievement.dart';
import 'package:cronicle/features/achievements/presentation/achievements_provider.dart';
import 'package:cronicle/features/onboarding/presentation/onboarding_notifier.dart';

/// Wraps the app body and shows a Wii-channel style slide-in banner whenever
/// achievements are unlocked. Multiple unlocks arriving close together are
/// **batched** into a single "X logros desbloqueados" card. Banners can be
/// swiped left/right to dismiss and tapping them navigates to the trophy room.
class AchievementOverlayHost extends ConsumerStatefulWidget {
  const AchievementOverlayHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AchievementOverlayHost> createState() =>
      _AchievementOverlayHostState();
}

class _AchievementOverlayHostState
    extends ConsumerState<AchievementOverlayHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 280),
  );
  StreamSubscription<Achievement>? _sub;

  /// Pending unlocks waiting to be batched into the next banner.
  final List<Achievement> _pending = [];
  /// Achievements being shown in the current banner (1 or more).
  List<Achievement>? _current;
  Timer? _batchTimer;
  Timer? _autoHide;

  static const _batchWindow = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stream = ref.read(achievementsProvider.notifier).unlockStream;
      _sub = stream.listen(_onUnlock);
    });
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    _batchTimer?.cancel();
    _sub?.cancel();
    _ac.dispose();
    super.dispose();
  }

  void _onUnlock(Achievement a) {
    final onboardingDone = ref.read(onboardingCompletedProvider);
    if (!onboardingDone) return;
    _pending.add(a);
    // Reset the batch window so a burst of unlocks coalesces into one banner.
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchWindow, _flushBatch);
  }

  void _flushBatch() {
    if (_pending.isEmpty) return;
    if (_current != null) {
      // A banner is already showing — let it dismiss naturally; the next
      // _flushBatch will run once it's gone.
      return;
    }
    final batch = List<Achievement>.from(_pending);
    _pending.clear();
    setState(() => _current = batch);
    _ac.forward(from: 0);
    _autoHide?.cancel();
    final ms = batch.length > 1 ? 5200 : 4200;
    _autoHide = Timer(Duration(milliseconds: ms), _dismiss);
  }

  Future<void> _dismiss({double velocity = 0}) async {
    _autoHide?.cancel();
    if (!mounted || _current == null) return;
    await _ac.reverse();
    if (!mounted) return;
    setState(() => _current = null);
    // If more unlocks arrived during the show, kick off another banner.
    if (_pending.isNotEmpty) _flushBatch();
  }

  void _onTapBanner() {
    // Navigate to the trophy room and dismiss.
    final nav = GoRouter.maybeOf(context);
    nav?.go('/profile/trophies');
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          IgnorePointer(
            ignoring: _ac.status == AnimationStatus.reverse,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedBuilder(
                  animation: _ac,
                  builder: (context, _) {
                    final t = Curves.easeOutBack.transform(
                      _ac.value.clamp(0.0, 1.0),
                    );
                    return Transform.translate(
                      offset: Offset(0, -90 * (1 - t)),
                      child: Opacity(
                        opacity: _ac.value.clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Dismissible(
                            key: ValueKey(
                                _current!.map((a) => a.id).join('|')),
                            direction: DismissDirection.horizontal,
                            onDismissed: (_) => _dismiss(),
                            child: _AchievementBanner(
                              achievements: _current!,
                              onTap: _onTapBanner,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AchievementBanner extends StatelessWidget {
  const _AchievementBanner({required this.achievements, required this.onTap});
  final List<Achievement> achievements;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (achievements.length == 1) {
      return _SingleAchievementBanner(
        achievement: achievements.first,
        onTap: onTap,
      );
    }
    return _GroupedAchievementBanner(
      achievements: achievements,
      onTap: onTap,
    );
  }
}

class _SingleAchievementBanner extends StatelessWidget {
  const _SingleAchievementBanner({
    required this.achievement,
    required this.onTap,
  });
  final Achievement achievement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tier = achievement.tier;
    final locale = Localizations.localeOf(context);
    final isEs = locale.languageCode == 'es';

    final bodyColor = isDark ? const Color(0xFF1F2024) : Colors.white;
    final stripeColor = tier.color;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          decoration: BoxDecoration(
            color: bodyColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: tier.color.withValues(alpha: 0.40),
                blurRadius: 22,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ChannelArt(tier: tier, icon: achievement.icon),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isEs
                                        ? 'LOGRO DESBLOQUEADO'
                                        : 'ACHIEVEMENT UNLOCKED',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '+${tier.points}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: tier.color,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                achievement.title.resolve(locale),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                achievement.description.resolve(locale),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cs.onSurfaceVariant,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  color: stripeColor,
                  child: Text(
                    _tierLabel(locale, tier),
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner shown when several achievements unlock within the batch window.
class _GroupedAchievementBanner extends StatelessWidget {
  const _GroupedAchievementBanner({
    required this.achievements,
    required this.onTap,
  });
  final List<Achievement> achievements;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final isEs = locale.languageCode == 'es';

    final totalPts = achievements.fold<int>(0, (s, a) => s + a.tier.points);
    // Highest tier present sets the accent color.
    final accent = achievements
        .map((a) => a.tier)
        .reduce((a, b) => a.points >= b.points ? a : b)
        .color;
    final bodyColor = isDark ? const Color(0xFF1F2024) : Colors.white;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          decoration: BoxDecoration(
            color: bodyColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.40),
                blurRadius: 22,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            isEs
                                ? '${achievements.length} LOGROS DESBLOQUEADOS'
                                : '${achievements.length} ACHIEVEMENTS UNLOCKED',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '+$totalPts',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stacked icons + names list (max 4 visible, +N overflow).
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _StackedIcons(achievements: achievements),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final a
                                    in achievements.take(2))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: a.tier.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            a.title.resolve(locale),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (achievements.length > 2)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      isEs
                                          ? '+${achievements.length - 2} más'
                                          : '+${achievements.length - 2} more',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  color: accent,
                  child: Text(
                    isEs ? 'TOCA PARA VER · DESLIZA PARA OCULTAR'
                        : 'TAP TO VIEW · SWIPE TO DISMISS',
                    style: const TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlapping circular trophy icons (up to 4) used in the grouped banner.
class _StackedIcons extends StatelessWidget {
  const _StackedIcons({required this.achievements});
  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    final visible = achievements.take(4).toList();
    const size = 38.0;
    const overlap = 14.0;
    final width = size + (visible.length - 1) * (size - overlap);
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: visible[i].tier.color,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  visible[i].icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Channel art" square on the left side of the tile — flat colored area
/// with a single subtle top highlight, à la Wii channel icons.
class _ChannelArt extends StatelessWidget {
  const _ChannelArt({required this.tier, required this.icon});
  final AchievementTier tier;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: tier.color),
          ),
          // Single subtle highlight band across the top half — Wii icon vibe
          // without the heavy diagonal gradient.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 34,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyBadge extends StatelessWidget {
  const _TrophyBadge({
    required this.tier,
    required this.icon,
    this.size = 48,
  });

  final AchievementTier tier;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Flat Material 3 style: solid tier color, no gradient, no glow.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tier.color,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}

String _tierLabel(Locale locale, AchievementTier tier) {
  final isEs = locale.languageCode == 'es';
  switch (tier) {
    case AchievementTier.bronze:
      return isEs ? 'BRONCE' : 'BRONZE';
    case AchievementTier.silver:
      return isEs ? 'PLATA' : 'SILVER';
    case AchievementTier.gold:
      return isEs ? 'ORO' : 'GOLD';
    case AchievementTier.platinum:
      return isEs ? 'PLATINO' : 'PLATINUM';
  }
}

/// Re-exported for trophy room tile.
class AchievementTrophyBadge extends StatelessWidget {
  const AchievementTrophyBadge({
    super.key,
    required this.tier,
    required this.icon,
    this.size = 48,
    this.locked = false,
  });

  final AchievementTier tier;
  final IconData icon;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant, width: 1),
        ),
        child: Icon(Icons.lock_outline_rounded,
            color: cs.onSurfaceVariant, size: size * 0.42),
      );
    }
    return _TrophyBadge(tier: tier, icon: icon, size: size);
  }
}

String tierLocalisedLabel(BuildContext context, AchievementTier tier) =>
    _tierLabel(Localizations.localeOf(context), tier);
