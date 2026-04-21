import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/l10n/app_localizations.dart';

/// Contadores de seguidores / seguidos Anilist; al pulsar abre la lista correspondiente.
class AnilistProfileFollowRow extends StatelessWidget {
  const AnilistProfileFollowRow({
    super.key,
    required this.userId,
    required this.followersCount,
    required this.followingCount,
  });

  final int userId;
  final int followersCount;
  final int followingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _CountButton(
            label: l10n.anilistProfileFollowers,
            count: followersCount,
            onTap: () => context.push('/user/$userId/followers'),
            colorScheme: cs,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CountButton(
            label: l10n.anilistProfileFollowing,
            count: followingCount,
            onTap: () => context.push('/user/$userId/following'),
            colorScheme: cs,
          ),
        ),
      ],
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.label,
    required this.count,
    required this.onTap,
    required this.colorScheme,
  });
  final String label;
  final int count;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest.withAlpha(120),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
