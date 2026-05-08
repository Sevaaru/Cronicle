import 'package:flutter/material.dart';

/// A small Steam / IGDB toggle bar shown at the top of game detail pages when
/// both views are available.
///
/// Pass [onSteam] or [onIgdb] as `null` to mark that view as active
/// (non-tappable, highlighted).
class GameViewToggle extends StatelessWidget {
  const GameViewToggle({
    super.key,
    required this.currentIsSteam,
    required this.onSteam,
    required this.onIgdb,
  });

  final bool currentIsSteam;
  final VoidCallback? onSteam;
  final VoidCallback? onIgdb;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chip(
          label: 'Steam',
          icon: Icons.sports_esports_rounded,
          selected: currentIsSteam,
          onTap: onSteam,
          cs: cs,
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'IGDB',
          icon: Icons.videogame_asset_rounded,
          selected: !currentIsSteam,
          onTap: onIgdb,
          cs: cs,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? cs.primaryContainer : cs.surfaceContainerHigh;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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
