import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cronicle/features/achievements/domain/achievement.dart';
import 'package:cronicle/features/achievements/presentation/achievement_overlay.dart';
import 'package:cronicle/features/achievements/presentation/achievements_provider.dart';

class TrophyRoomPage extends ConsumerStatefulWidget {
  const TrophyRoomPage({super.key});

  @override
  ConsumerState<TrophyRoomPage> createState() => _TrophyRoomPageState();
}

class _TrophyRoomPageState extends ConsumerState<TrophyRoomPage> {
  AchievementTier? _filter;

  @override
  void initState() {
    super.initState();
    // Re-evaluate when entering so latest progress is reflected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementsEvaluatorProvider).evaluateNow();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final isEs = locale.languageCode == 'es';
    final state = ref.watch(achievementsProvider);
    final all = AchievementCatalog.all;
    final unlockedCount = state.values.where((s) => s.isUnlocked).length;
    final totalPoints = AchievementCatalog.totalPoints;
    final earnedPoints = all.fold<int>(0, (sum, a) {
      final s = state[a.id];
      return sum + (s?.isUnlocked == true ? a.tier.points : 0);
    });

    final tierStats = {
      for (final t in AchievementTier.values)
        t: _TierStat(
          total: all.where((a) => a.tier == t).length,
          earned: all
              .where((a) => a.tier == t && state[a.id]?.isUnlocked == true)
              .length,
        ),
    };

    final visible = _filter == null
        ? all
        : all.where((a) => a.tier == _filter).toList();

    final levelData = _ChroniclerLevel.fromPoints(earnedPoints);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: Text(isEs ? 'Sala de Trofeos' : 'Trophy Room'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32 + MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          _DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _LevelBadge(level: levelData.level),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEs
                                ? 'Cronista Nivel ${levelData.level}'
                                : 'Chronicler Lv. ${levelData.level}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$earnedPoints / $totalPoints '
                            '${isEs ? "puntos" : "points"}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: levelData.fraction,
                              minHeight: 8,
                              backgroundColor:
                                  cs.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                  cs.primary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEs
                                ? '${levelData.toNext} pts hasta nivel ${levelData.level + 1}'
                                : '${levelData.toNext} pts to Lv. ${levelData.level + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final t in AchievementTier.values)
                      _TierMiniStat(tier: t, stat: tierStats[t]!),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    isEs
                        ? '$unlockedCount / ${all.length} logros desbloqueados'
                        : '$unlockedCount / ${all.length} achievements unlocked',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: isEs ? 'Todos' : 'All',
                  color: cs.primary,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                for (final t in AchievementTier.values) ...[
                  _FilterChip(
                    label: tierLocalisedLabel(context, t),
                    color: t.color,
                    selected: _filter == t,
                    onTap: () => setState(() => _filter = t),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(visible.length, (i) {
            final a = visible[i];
            final s = state[a.id] ?? const AchievementState();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AchievementTile(achievement: a, state: s),
            );
          }),
        ],
      ),
    );
  }
}

class _TierStat {
  const _TierStat({required this.total, required this.earned});
  final int total;
  final int earned;
}

class _TierMiniStat extends StatelessWidget {
  const _TierMiniStat({required this.tier, required this.stat});
  final AchievementTier tier;
  final _TierStat stat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        AchievementTrophyBadge(
          tier: tier,
          icon: _tierIcon(tier),
          size: 36,
          locked: stat.earned == 0,
        ),
        const SizedBox(height: 4),
        Text(
          '${stat.earned}/${stat.total}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

IconData _tierIcon(AchievementTier t) => switch (t) {
      AchievementTier.bronze => Icons.emoji_events_rounded,
      AchievementTier.silver => Icons.workspace_premium_rounded,
      AchievementTier.gold => Icons.military_tech_rounded,
      AchievementTier.platinum => Icons.diamond_rounded,
    };

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Material 3 FilterChip — uses the theme's chip styling for proper M3 look.
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: selected
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.state});
  final Achievement achievement;
  final AchievementState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final isEs = locale.languageCode == 'es';
    final unlocked = state.isUnlocked;
    final progress = unlocked ? achievement.target : state.progress;
    final fraction = (progress / achievement.target).clamp(0.0, 1.0);
    final tier = achievement.tier;

    final bodyColor = isDark ? const Color(0xFF1F2024) : Colors.white;
    final stripeColor =
        unlocked ? tier.color : cs.outlineVariant.withAlpha(140);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: tier.color.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: -6,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: bodyColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Channel art: large flat colored square with gloss + icon.
                    _ChannelArtSquare(
                      tier: tier,
                      icon: achievement.icon,
                      locked: !unlocked,
                      width: 88,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    achievement.title.resolve(locale),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: unlocked
                                          ? cs.onSurface
                                          : cs.onSurfaceVariant,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tier.color.withValues(
                                        alpha: unlocked ? 0.20 : 0.10),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: tier.color.withValues(
                                          alpha: unlocked ? 0.55 : 0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${tier.points}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: tier.color,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: fraction,
                                      minHeight: 6,
                                      backgroundColor:
                                          cs.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation(
                                        unlocked ? tier.color : cs.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$progress/${achievement.target}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (unlocked && state.unlockedAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                isEs
                                    ? 'Desbloqueado · ${DateFormat.yMMMd(locale.toLanguageTag()).format(state.unlockedAt!)}'
                                    : 'Unlocked · ${DateFormat.yMMMd(locale.toLanguageTag()).format(state.unlockedAt!)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: tier.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Channel name strip: solid tier color (or grey when locked).
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                color: stripeColor,
                child: Row(
                  children: [
                    Text(
                      tierLocalisedLabel(context, tier),
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w900,
                        color: unlocked ? Colors.white : Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    if (!unlocked)
                      Text(
                        isEs ? 'BLOQUEADO' : 'LOCKED',
                        style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                        ),
                      )
                    else
                      Text(
                        isEs ? 'COMPLETO' : 'COMPLETE',
                        style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wii channel-art square: flat tier color with a single subtle top
/// highlight band. Greyed out when [locked].
class _ChannelArtSquare extends StatelessWidget {
  const _ChannelArtSquare({
    required this.tier,
    required this.icon,
    required this.locked,
    this.width = 80,
  });

  final AchievementTier tier;
  final IconData icon;
  final bool locked;
  final double width;

  @override
  Widget build(BuildContext context) {
    final base = locked ? const Color(0xFF6B6F76) : tier.color;
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: base)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: locked ? 0.10 : 0.20),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              locked ? Icons.lock_rounded : icon,
              color: Colors.white,
              size: 36,
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

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer,
      ),
      child: Text(
        '$level',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ChroniclerLevel {
  const _ChroniclerLevel({
    required this.level,
    required this.fraction,
    required this.toNext,
  });

  final int level;
  final double fraction;
  final int toNext;

  /// Quadratic level curve: each level needs `100 * level` points more than
  /// the previous, so total = 50 * level * (level + 1).
  factory _ChroniclerLevel.fromPoints(int pts) {
    var lvl = 1;
    while (50 * lvl * (lvl + 1) <= pts) {
      lvl++;
    }
    final prevTotal = 50 * (lvl - 1) * lvl;
    final nextTotal = 50 * lvl * (lvl + 1);
    final span = nextTotal - prevTotal;
    final into = pts - prevTotal;
    return _ChroniclerLevel(
      level: lvl,
      fraction: span > 0 ? (into / span).clamp(0.0, 1.0) : 0,
      toNext: (nextTotal - pts).clamp(0, 1 << 30),
    );
  }
}

/// Dashboard panel: plain Material 3 surface card. No top stripe, no glow.
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: child,
      ),
    );
  }
}
