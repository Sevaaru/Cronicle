import 'dart:async';

import 'package:flutter/material.dart';

/// A heart‐shaped like button with optimistic UI update, scale animation on
/// toggle, and a busy guard that prevents rapid‐fire network requests.
///
/// The caller is responsible for providing [onToggle] which performs the actual
/// network mutation and returns the server‐confirmed `isLiked` value.
/// If the server result differs from the optimistic prediction the widget
/// self‐corrects.
class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onToggle,
    this.iconSize = 16.0,
    this.fontSize = 11.0,
    this.likedColor,
    this.defaultColor,
    this.showCount = true,
  });

  final bool isLiked;
  final int likeCount;

  /// Called when the user taps the button. Must perform the server mutation and
  /// return the confirmed `isLiked` value. If it throws, the optimistic state
  /// is reverted.
  final Future<bool?> Function() onToggle;

  final double iconSize;
  final double fontSize;

  /// Colour when liked. Defaults to `Colors.red.shade400`.
  final Color? likedColor;

  /// Colour when not liked. Defaults to `ColorScheme.onSurfaceVariant`.
  final Color? defaultColor;

  /// Whether to show the count next to the heart.
  final bool showCount;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  late int _count;
  bool _busy = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _count = widget.likeCount;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with parent when not in the middle of a network call.
    if (!_busy) {
      _liked = widget.isLiked;
      _count = widget.likeCount;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_busy) return;
    _busy = true;

    // Optimistic update
    final prevLiked = _liked;
    final prevCount = _count;
    setState(() {
      _liked = !_liked;
      _count = _liked ? _count + 1 : (_count - 1).clamp(0, 999999);
    });
    _animCtrl.forward(from: 0);

    try {
      final serverLiked = await widget.onToggle();
      if (!mounted) return;
      // If the server response is available and differs, correct the state.
      if (serverLiked != null && serverLiked != _liked) {
        setState(() {
          _liked = serverLiked;
          _count = serverLiked
              ? prevCount + 1
              : (prevCount - 1).clamp(0, 999999);
        });
      }
    } catch (_) {
      // Revert on error
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
    final likedCol = widget.likedColor ?? Colors.red.shade400;
    final defaultCol = widget.defaultColor ?? cs.onSurfaceVariant;
    final color = _liked ? likedCol : defaultCol;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _onTap,
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
                  fontWeight: _liked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
