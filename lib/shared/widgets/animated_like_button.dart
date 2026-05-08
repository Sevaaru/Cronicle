import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onToggle,
    this.onLongPress,
    this.iconSize = 20.0,
    this.fontSize = 13.0,
    this.likedColor,
    this.defaultColor,
    this.showCount = true,
    this.compact = false,
  });

  final bool isLiked;
  final int likeCount;

  final Future<bool?> Function() onToggle;

  /// Optional long-press handler. Used by the social feed to surface the
  /// list of users that have liked the activity.
  final VoidCallback? onLongPress;

  final double iconSize;
  final double fontSize;

  final Color? likedColor;

  final Color? defaultColor;

  final bool showCount;

  /// When true, uses the legacy small icon-only style (kept for replies/etc.).
  final bool compact;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with TickerProviderStateMixin {
  late bool _liked;
  late int _count;
  bool _busy = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final AnimationController _burstCtrl;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _count = widget.likeCount;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_busy) {
      _liked = widget.isLiked;
      _count = widget.likeCount;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_busy) return;
    _busy = true;

    final prevLiked = _liked;
    final prevCount = _count;
    final newLiked = !prevLiked;
    setState(() {
      _liked = newLiked;
      _count = newLiked ? _count + 1 : (_count - 1).clamp(0, 999999);
    });
    HapticFeedback.lightImpact();
    _animCtrl.forward(from: 0);
    if (newLiked) _burstCtrl.forward(from: 0);

    try {
      final serverLiked = await widget.onToggle();
      if (!mounted) return;
      if (serverLiked != null && serverLiked != _liked) {
        setState(() {
          _liked = serverLiked;
          _count = serverLiked
              ? prevCount + 1
              : (prevCount - 1).clamp(0, 999999);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = prevLiked;
          _count = prevCount;
        });
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final likedCol = widget.likedColor ?? const Color(0xFFE53935);
    final defaultCol = widget.defaultColor ?? cs.onSurfaceVariant;
    final color = _liked ? likedCol : defaultCol;

    if (widget.compact) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _onTap,
        onLongPress: widget.onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  size: widget.iconSize,
                  color: color,
                ),
              ),
              if (widget.showCount && _count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$_count',
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: cs.onSurfaceVariant,
                    fontWeight:
                        _liked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final bg = _liked
        ? likedCol.withValues(alpha: 0.14)
        : cs.surfaceContainerHigh;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(20),
          splashColor: likedCol.withValues(alpha: 0.18),
          highlightColor: likedCol.withValues(alpha: 0.08),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _burstCtrl,
                      builder: (context, _) {
                        if (_burstCtrl.value == 0 ||
                            _burstCtrl.status == AnimationStatus.dismissed) {
                          return const SizedBox.shrink();
                        }
                        final t = _burstCtrl.value;
                        final size = 10 + 16 * t;
                        return Opacity(
                          opacity: (1.0 - t).clamp(0.0, 1.0) * 0.5,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: likedCol.withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      },
                    ),
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        size: widget.iconSize,
                        color: color,
                      ),
                    ),
                  ],
                ),
                if (widget.showCount) ...[
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      _count > 0 ? '$_count' : 'Like',
                      key: ValueKey<String>('${_liked}_$_count'),
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        color: color,
                        fontWeight: FontWeight.w600,
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
  }
}
