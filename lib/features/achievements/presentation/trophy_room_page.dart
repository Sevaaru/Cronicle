import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cronicle/features/achievements/domain/achievement.dart';
import 'package:cronicle/features/achievements/presentation/achievement_overlay.dart';
import 'package:cronicle/features/achievements/presentation/achievements_provider.dart';
import 'package:cronicle/shared/widgets/eva_style.dart';
import 'package:cronicle/shared/widgets/signal_style.dart';

enum _StatusFilter { all, unlocked, locked }

class TrophyRoomPage extends ConsumerStatefulWidget {
  const TrophyRoomPage({super.key});

  @override
  ConsumerState<TrophyRoomPage> createState() => _TrophyRoomPageState();
}

class _TrophyRoomPageState extends ConsumerState<TrophyRoomPage> {
  AchievementTier? _filter;
  _StatusFilter _statusFilter = _StatusFilter.all;
  final _revealed = <String>{};

  void _setStatus(_StatusFilter next) {
    setState(() {
      _statusFilter = next;
      _revealed.clear();
    });
  }

  void _setTier(AchievementTier? next) {
    setState(() {
      _filter = next;
      _revealed.clear();
    });
  }

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

    final visible = (() {
      var list = _filter == null
          ? all
          : all.where((a) => a.tier == _filter).toList();
      return switch (_statusFilter) {
        _StatusFilter.all => list,
        _StatusFilter.unlocked =>
          list.where((a) => state[a.id]?.isUnlocked == true).toList(),
        _StatusFilter.locked =>
          list.where((a) => state[a.id]?.isUnlocked != true).toList(),
      };
    })();

    final levelData = _ChroniclerLevel.fromPoints(earnedPoints);

    final accent = kSignalRed;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: Text(
          (isEs ? 'Sala de Trofeos' : 'Trophy Room').toUpperCase(),
          style: signalFont(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: cs.onSurface,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SignalGridBackdrop(color: accent.withAlpha(22)),
          ),
          ListView(
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
                        _LevelBadge(level: levelData.level, accent: accent),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (isEs
                                        ? 'Cronista Nivel ${levelData.level}'
                                        : 'Chronicler Lv. ${levelData.level}')
                                    .toUpperCase(),
                                style: signalFont(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$earnedPoints / $totalPoints '
                                '${isEs ? "puntos" : "points"}',
                                style: signalFont(
                                  fontSize: 12,
                                  letterSpacing: 0.6,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SignalSegmentBar(
                                fraction: levelData.fraction,
                                accent: accent,
                                segments: 16,
                                height: 8,
                              ),
                              const SizedBox(height: 6),
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
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _SignalFilter(
                      index: 1,
                      label: isEs ? 'Todos' : 'All',
                      icon: Icons.list_alt_rounded,
                      accent: accent,
                      selected: _statusFilter == _StatusFilter.all,
                      onTap: () => _setStatus(_StatusFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _SignalFilter(
                      index: 2,
                      label: isEs ? 'Desbloqueados' : 'Unlocked',
                      icon: Icons.lock_open_rounded,
                      accent: accent,
                      selected: _statusFilter == _StatusFilter.unlocked,
                      onTap: () => _setStatus(_StatusFilter.unlocked),
                    ),
                    const SizedBox(width: 8),
                    _SignalFilter(
                      index: 3,
                      label: isEs ? 'Bloqueados' : 'Locked',
                      icon: Icons.lock_outline_rounded,
                      accent: accent,
                      selected: _statusFilter == _StatusFilter.locked,
                      onTap: () => _setStatus(_StatusFilter.locked),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _SignalFilter(
                      index: 0,
                      label: isEs ? 'Todos' : 'All',
                      icon: Icons.grid_view_rounded,
                      accent: accent,
                      selected: _filter == null,
                      onTap: () => _setTier(null),
                    ),
                    const SizedBox(width: 8),
                    for (var i = 0; i < AchievementTier.values.length; i++) ...[
                      _SignalFilter(
                        index: i + 1,
                        label: tierLocalisedLabel(
                          context,
                          AchievementTier.values[i],
                        ),
                        icon: _tierIcon(AchievementTier.values[i]),
                        accent: tierMono(context, AchievementTier.values[i]),
                        selected: _filter == AchievementTier.values[i],
                        onTap: () => _setTier(AchievementTier.values[i]),
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
                final first = _revealed.add(a.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SignalAutoReveal(
                    play: first && i < 8,
                    delay: Duration(milliseconds: i * 40),
                    color: tierMono(context, a.tier),
                    shape: signalChamfer(16, radius: 8, bevelBottomLeft: false),
                    child: _AchievementTile(
                      index: i + 1,
                      achievement: a,
                      state: s,
                    ),
                  ),
                );
              }),
            ],
          ),
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

class _SignalFilter extends StatelessWidget {
  const _SignalFilter({
    required this.index,
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SignalSelectable(
      selected: selected,
      accent: accent,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      builder: (fg) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (index > 0) ...[
            Text(
              signalIndex(index),
              style: signalFont(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: fg.withAlpha(170),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: signalFont(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// NERV console row (same language as the library list): tier art with the
/// points hexagon, heavy serif title, plain status readout and gauge.
class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.index,
    required this.achievement,
    required this.state,
  });

  final int index;
  final Achievement achievement;
  final AchievementState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final isEs = locale.languageCode == 'es';
    final unlocked = state.isUnlocked;
    final progress = unlocked ? achievement.target : state.progress;
    final fraction = (progress / achievement.target).clamp(0.0, 1.0);
    final tier = achievement.tier;
    final mono = tierMono(context, tier);
    final orange = nervOrange(theme.brightness);
    final dimStyle = signalFont(
      fontSize: 9.5,
      letterSpacing: 1.2,
      color: cs.onSurfaceVariant,
    );

    return Material(
      color: isDark ? cs.surfaceContainerLow : cs.surface,
      shape: signalChamfer(16, radius: 8, bevelBottomLeft: false),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EvaTrophyArt(
                tier: tier,
                icon: achievement.icon,
                locked: !unlocked,
                bracket: orange,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            signalIndex(index),
                            style: signalFont(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: orange,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '// ${tierLocalisedLabel(context, tier).toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dimStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        achievement.title.resolve(locale).toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: evaTitleFont(
                          fontSize: 15,
                          color: unlocked ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            unlocked
                                ? (isEs ? 'COMPLETO' : 'COMPLETE')
                                : (isEs ? 'BLOQUEADO' : 'LOCKED'),
                            style: signalFont(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: unlocked ? orange : cs.onSurfaceVariant,
                            ),
                          ),
                          if (unlocked && state.unlockedAt != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                DateFormat.yMMMd(
                                  locale.toLanguageTag(),
                                ).format(state.unlockedAt!).toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: dimStyle,
                              ),
                            ),
                          ],
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
                      const Spacer(),
                      const SizedBox(height: 8),
                      EvaGaugeRow(
                        progress: '$progress/${achievement.target}',
                        fraction: fraction,
                        accent: unlocked ? mono : cs.outline,
                        readout: orange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tier art: flat monochrome shade (neutral when locked) with the icon and
/// the points hexagon.
class _EvaTrophyArt extends StatelessWidget {
  const _EvaTrophyArt({
    required this.tier,
    required this.icon,
    required this.locked,
    required this.bracket,
  });

  final AchievementTier tier;
  final IconData icon;
  final bool locked;
  final Color bracket;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = locked ? cs.surfaceContainerHighest : tierMono(context, tier);
    return SizedBox(
      width: 84,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: base),
          Center(
            child: Icon(
              locked ? Icons.lock_rounded : icon,
              size: 34,
              color: locked ? cs.onSurfaceVariant : signalOnColor(base),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: EvaHexBadge(text: '${tier.points}', stroke: bracket),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.accent});
  final int level;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 64,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: accent.withAlpha(28),
        shape: signalChamfer(
          12,
          radius: 5,
          side: BorderSide(color: accent, width: 1.4),
        ),
      ),
      child: SignalOutlineText(
        signalIndex(level),
        fontSize: 28,
        color: accent,
        letterSpacing: 1,
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
      shape: signalChamfer(18, radius: 10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: child,
      ),
    );
  }
}
