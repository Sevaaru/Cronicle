import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Miniatura para la fila de previsualización del bloque de favoritos en el perfil.
class ProfileFavPreviewThumb {
  const ProfileFavPreviewThumb({this.imageUrl, required this.fallbackIcon});

  final String? imageUrl;
  final IconData fallbackIcon;
}

/// Chip del número de favoritos: tamaño fijo para que no varíe con las cifras.
class _FavoritesCountChip extends StatelessWidget {
  const _FavoritesCountChip({required this.count, required this.accent});

  final int count;
  final Color accent;

  static double get _side => ProfileFavoritesPreviewRow.thumbHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _side,
      height: _side,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '$count',
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 1,
                  color: accent.withValues(alpha: 0.95),
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila tappable: título arriba; debajo contador a la izquierda y tantas miniaturas como quepan en el ancho.
class ProfileFavoritesPreviewRow extends StatelessWidget {
  const ProfileFavoritesPreviewRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.thumbs,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final List<ProfileFavPreviewThumb> thumbs;
  final VoidCallback onTap;

  static const double thumbWidth = 38;
  static const double thumbHeight = 56;
  static const double _thumbGap = 5;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 24),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _FavoritesCountChip(count: count, accent: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        if (thumbs.isEmpty) {
                          return const SizedBox(height: thumbHeight);
                        }
                        final w = c.maxWidth;
                        final slot = thumbWidth + _thumbGap;
                        var maxSlots = w > 0 ? ((w + _thumbGap) / slot).floor() : 1;
                        if (maxSlots < 1) maxSlots = 1;
                        final n = maxSlots.clamp(1, thumbs.length);
                        final hidden = thumbs.length - n;
                        final cellW = n > 0 ? (w - (n - 1) * _thumbGap) / n : thumbWidth;
                        return SizedBox(
                          height: thumbHeight,
                          child: Row(
                            children: [
                              for (var i = 0; i < n; i++) ...[
                                if (i > 0) const SizedBox(width: _thumbGap),
                                SizedBox(
                                  width: cellW,
                                  height: thumbHeight,
                                  child: _ThumbCell(
                                    thumb: thumbs[i],
                                    colorScheme: cs,
                                    showMoreBadge: i == n - 1 && hidden > 0,
                                    moreCount: hidden,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbCell extends StatelessWidget {
  const _ThumbCell({
    required this.thumb,
    required this.colorScheme,
    this.showMoreBadge = false,
    this.moreCount = 0,
  });

  final ProfileFavPreviewThumb thumb;
  final ColorScheme colorScheme;
  final bool showMoreBadge;
  final int moreCount;

  @override
  Widget build(BuildContext context) {
    final t = thumb;
    final child = (t.imageUrl != null && t.imageUrl!.isNotEmpty)
        ? CachedNetworkImage(
            imageUrl: t.imageUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) =>
                _fallbackBox(colorScheme, t.fallbackIcon),
          )
        : _fallbackBox(colorScheme, t.fallbackIcon);

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.expand(child: child),
    );

    if (!showMoreBadge || moreCount <= 0) {
      return image;
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: image),
        Positioned(
          right: 2,
          bottom: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Text(
                '+$moreCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackBox(ColorScheme cs, IconData i) {
    return SizedBox.expand(
      child: ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(child: Icon(i, size: 20, color: cs.onSurfaceVariant)),
      ),
    );
  }
}
