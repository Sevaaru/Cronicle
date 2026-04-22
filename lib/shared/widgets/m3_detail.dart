import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';

/// Shared Material 3 expressive widgets for media detail pages
/// (anime, books, games, movies, shows).

/// Hero banner + poster + (marquee) title + subtitle + tag pills.
///
/// Total height: bannerHeight + posterHeight - overlap + 8.
class M3DetailHero extends StatelessWidget {
  const M3DetailHero({
    super.key,
    required this.title,
    this.subtitleLines = const [],
    required this.banner,
    required this.poster,
    this.pills = const [],
    this.bannerHeight = 180,
    this.posterHeight = 150,
    this.posterWidth = 100,
    this.overlap = 60,
  });

  final String title;
  final List<String> subtitleLines;
  final String? banner;
  final String? poster;
  final List<Widget> pills;
  final double bannerHeight;
  final double posterHeight;
  final double posterWidth;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalHeight = bannerHeight - overlap + posterHeight + 8;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: banner != null
                ? () => showFullscreenImage(context, banner!)
                : null,
            child: Container(
              height: bannerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                image: banner != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(banner!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: banner == null ? cs.surfaceContainerHighest : null,
              ),
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(30),
                    Colors.transparent,
                    Colors.black.withAlpha(120),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withAlpha(70),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: bannerHeight - overlap,
            child: poster != null
                ? GestureDetector(
                    onTap: () => showFullscreenImage(context, poster!),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cs.surface, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(70),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: poster!,
                          width: posterWidth,
                          height: posterHeight,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: posterWidth,
                    height: posterHeight,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.surface, width: 3),
                    ),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
          ),
          Positioned(
            left: 16 + posterWidth + 14,
            right: 16,
            top: bannerHeight + 4,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                M3MarqueeText(
                  text: title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.2,
                    color: cs.onSurface,
                  ),
                ),
                for (final line in subtitleLines)
                  if (line.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                if (pills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: pills),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Marquee scrolling text. Renders normally if it fits; otherwise auto-scrolls
/// horizontally and lets the user manually drag to peek.
class M3MarqueeText extends StatefulWidget {
  const M3MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.gap = 48,
    this.pixelsPerSecond = 30,
    this.startDelay = const Duration(seconds: 2),
  });

  final String text;
  final TextStyle style;
  final double gap;
  final double pixelsPerSecond;
  final Duration startDelay;

  @override
  State<M3MarqueeText> createState() => _M3MarqueeTextState();
}

class _M3MarqueeTextState extends State<M3MarqueeText>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _last = Duration.zero;
  double _offset = 0;
  bool _started = false;
  bool _dragging = false;
  Timer? _resumeTimer;
  double _cycleWidth = 0;
  double _textWidth = 0;
  double _maxWidth = 0;

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _ticker?.dispose();
    super.dispose();
  }

  void _ensureTicker() {
    _ticker ??= createTicker((elapsed) {
      if (_dragging) {
        _last = elapsed;
        return;
      }
      if (!_started) {
        if (elapsed >= widget.startDelay) {
          _started = true;
          _last = elapsed;
        }
        return;
      }
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      double next = _offset + widget.pixelsPerSecond * dt;
      if (_cycleWidth > 0) {
        next = next % _cycleWidth;
        if (next < 0) next += _cycleWidth;
      }
      if (next != _offset) {
        setState(() => _offset = next);
      }
    });
    if (!_ticker!.isActive) _ticker!.start();
  }

  double _measureText() {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return tp.size.width;
  }

  void _onDragStart(DragStartDetails _) {
    _resumeTimer?.cancel();
    _started = true;
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_cycleWidth <= 0) return;
    double next = _offset - d.delta.dx;
    next = next % _cycleWidth;
    if (next < 0) next += _cycleWidth;
    setState(() => _offset = next);
  }

  void _onDragEnd(DragEndDetails _) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _dragging = false);
      _last = Duration.zero;
      _ticker?.stop();
      _ticker?.start();
    });
  }

  void _onDragCancel() {
    _onDragEnd(DragEndDetails());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;
        _textWidth = _measureText();
        if (_textWidth <= _maxWidth + 0.5) {
          _ticker?.stop();
          _started = false;
          _offset = 0;
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        _cycleWidth = _textWidth + widget.gap;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ensureTicker();
        });

        // Render enough copies to always cover [maxWidth] starting from
        // the wrapped offset.
        final copies = (_maxWidth / _cycleWidth).ceil() + 1;
        final height =
            (widget.style.fontSize ?? 14) * (widget.style.height ?? 1.2);

        return SizedBox(
          height: height,
          width: _maxWidth,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0, 0.04, 0.96, 1],
                colors: const [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
              ).createShader(rect);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onHorizontalDragCancel: _onDragCancel,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  child: Transform.translate(
                    offset: Offset(-_offset, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < copies; i++)
                          Padding(
                            padding: EdgeInsets.only(right: widget.gap),
                            child: Text(
                              widget.text,
                              maxLines: 1,
                              softWrap: false,
                              style: widget.style,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Compact M3 pill chip used inside a hero header.
class M3HeroPill extends StatelessWidget {
  const M3HeroPill(this.text, {super.key, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Tappable expressive M3 pill chip (used for genres, tags, "show more").
class M3PillChip extends StatelessWidget {
  const M3PillChip({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 12 : 14,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Expressive section header with a colored leading bar + bold label.
class M3SectionHeader extends StatelessWidget {
  const M3SectionHeader({super.key, required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: 0.2,
            color: cs.onSurface,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

/// Standard M3 surface card used to wrap stat / info / list groups.
class M3SurfaceCard extends StatelessWidget {
  const M3SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.radius = 22,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// Morphing Material 3 favorite button (52x52). Color/radius animate on toggle.
class M3FavoriteIconButton extends StatelessWidget {
  const M3FavoriteIconButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.busy = false,
    this.tooltip,
  });

  final bool isFavorite;
  final VoidCallback? onPressed;
  final bool busy;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isFavorite
        ? cs.errorContainer.withAlpha(220)
        : cs.surfaceContainerHigh;
    final fg = isFavorite ? cs.onErrorContainer : cs.onSurfaceVariant;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isFavorite ? 18 : 14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: busy ? null : onPressed,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: c),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(isFavorite),
                        color: fg,
                        size: 24,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      content = Tooltip(message: tooltip!, child: content);
    }
    return content;
  }
}

/// Morphing M3 add/edit-to-library button. Primary look when adding,
/// tertiary calmer look when editing an existing entry.
class M3AddToLibraryButton extends StatelessWidget {
  const M3AddToLibraryButton({
    super.key,
    required this.isEdit,
    required this.label,
    required this.onPressed,
    this.height = 52,
  });

  final bool isEdit;
  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: height,
      decoration: BoxDecoration(
        color: isEdit ? cs.tertiaryContainer : cs.primary,
        borderRadius: BorderRadius.circular(isEdit ? 16 : 18),
        boxShadow: isEdit
            ? null
            : [
                BoxShadow(
                  color: cs.primary.withAlpha(60),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isEdit ? 16 : 18),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_rounded,
                  color: isEdit ? cs.onTertiaryContainer : cs.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isEdit ? cs.onTertiaryContainer : cs.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: 0.2,
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
