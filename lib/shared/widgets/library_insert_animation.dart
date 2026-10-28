import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// GlobalKey attached to the Library tab inside [GlassBottomNav]. Used as the
/// landing target for the "insert cartridge" animation that plays after the
/// user adds an item to their library from a detail page.
final GlobalKey libraryNavTabKey = GlobalKey(debugLabel: 'libraryNavTabKey');

/// Plays a 3DS / Wii U style cartridge-insert animation: takes the [imageUrl]
/// (cover/poster of the item just added) and flies it from [sourceContext]'s
/// bounding rect toward the Library tab in the bottom navigation bar, with a
/// satisfying "click" sound and haptic on arrival.
///
/// Safe to call without awaiting. No-op if either anchor cannot be measured.
void playLibraryInsertAnimation({
  required BuildContext sourceContext,
  required String? imageUrl,
  double startWidth = 96,
  double startHeight = 130,
}) {
  if (imageUrl == null || imageUrl.isEmpty) return;
  final overlay = Overlay.maybeOf(sourceContext, rootOverlay: true);
  if (overlay == null) return;

  final sourceBox = sourceContext.findRenderObject() as RenderBox?;
  final targetCtx = libraryNavTabKey.currentContext;
  final targetBox = targetCtx?.findRenderObject() as RenderBox?;
  if (sourceBox == null || !sourceBox.hasSize) return;
  if (targetBox == null || !targetBox.hasSize) return;

  final sourceTopLeft = sourceBox.localToGlobal(Offset.zero);
  final sourceCenter = sourceTopLeft + sourceBox.size.center(Offset.zero);
  final targetTopLeft = targetBox.localToGlobal(Offset.zero);
  final targetCenter = targetTopLeft + targetBox.size.center(Offset.zero);

  // Start the cartridge a little above the source so it visually "lifts off"
  // the button before flying away.
  final startCenter = Offset(sourceCenter.dx, sourceCenter.dy - 12);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _CartridgeFlight(
      imageUrl: imageUrl,
      startCenter: startCenter,
      endCenter: targetCenter,
      startWidth: startWidth,
      startHeight: startHeight,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _CartridgeFlight extends StatefulWidget {
  const _CartridgeFlight({
    required this.imageUrl,
    required this.startCenter,
    required this.endCenter,
    required this.startWidth,
    required this.startHeight,
    required this.onCompleted,
  });

  final String imageUrl;
  final Offset startCenter;
  final Offset endCenter;
  final double startWidth;
  final double startHeight;
  final VoidCallback onCompleted;

  @override
  State<_CartridgeFlight> createState() => _CartridgeFlightState();
}

class _CartridgeFlightState extends State<_CartridgeFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _clicked = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
    _c.addListener(_onTick);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });
    _c.forward();
  }

  void _onTick() {
    // Trigger click + haptic at the moment the cartridge "snaps" into the slot
    // (matches the impact frame in the animation timeline below).
    if (!_clicked && _c.value >= 0.82) {
      _clicked = true;
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => _buildFrame(context),
      ),
    );
  }

  Widget _buildFrame(BuildContext context) {
    // 0.00 - 0.12 : pop-in scale at source
    // 0.12 - 0.82 : fly along curved path toward target, shrink + tilt
    // 0.82 - 0.92 : "snap" punch (overshoot down)
    // 0.92 - 1.00 : fade out
    final t = _c.value;

    // Pop-in scale.
    final popT = ((t - 0.0) / 0.12).clamp(0.0, 1.0);
    final popScale = Curves.easeOutBack.transform(popT);

    // Flight progress from start to end.
    final flightT = ((t - 0.12) / 0.70).clamp(0.0, 1.0);
    final flightCurve = Curves.easeInCubic.transform(flightT);

    // Quadratic Bezier control point: pulled outward + slightly upward so the
    // cartridge arcs toward the navbar instead of moving in a straight line.
    final dx = widget.endCenter.dx - widget.startCenter.dx;
    final controlPoint = Offset(
      widget.startCenter.dx + dx * 0.55,
      math.min(widget.startCenter.dy, widget.endCenter.dy) - 80,
    );
    final pos = _quadraticBezier(
      widget.startCenter,
      controlPoint,
      widget.endCenter,
      flightCurve,
    );

    // Size shrinks from start size down to ~28px target size during flight.
    final shrink = 1.0 - flightCurve;
    double width = widget.startWidth * (0.30 + 0.70 * shrink);
    double height = widget.startHeight * (0.30 + 0.70 * shrink);

    // 3D tilt: rotates around X to feel like the cartridge is being slotted
    // forward into the navbar. Reaches max tilt mid-flight, returns to 0 at
    // the end so it lands flat.
    final tiltT = math.sin(flightCurve * math.pi);
    final rotX = tiltT * 0.45; // radians (~26deg)
    // Light Z rotation for a playful tumble.
    final rotZ = (flightCurve - 0.5) * 0.35;

    // Snap punch on arrival: scale dips for a moment to sell the click.
    final snapT = ((t - 0.82) / 0.10).clamp(0.0, 1.0);
    final snap = math.sin(snapT * math.pi) * 0.18;
    final snapScale = 1.0 - snap;

    // Fade out at the very end.
    final fadeT = ((t - 0.92) / 0.08).clamp(0.0, 1.0);
    final opacity = (1.0 - fadeT) * popScale.clamp(0.0, 1.0);

    final scale = popScale * snapScale;

    return Stack(
      children: [
        // Flash ring on the target nav tab at the moment of impact.
        if (snapT > 0)
          Positioned(
            left: widget.endCenter.dx - 28,
            top: widget.endCenter.dy - 28,
            child: IgnorePointer(
              child: Opacity(
                opacity: (1.0 - snapT) * 0.8,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(0),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withAlpha(220),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(140),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Flying cartridge.
        Positioned(
          left: pos.dx - width / 2,
          top: pos.dy - height / 2,
          width: width,
          height: height,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015) // perspective
                ..rotateX(rotX)
                ..rotateZ(rotZ)
                ..scale(scale),
              child: _Cartridge(imageUrl: widget.imageUrl),
            ),
          ),
        ),
      ],
    );
  }

  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1.0 - t;
    final x = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final y = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }
}

class _Cartridge extends StatelessWidget {
  const _Cartridge({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
            // Glossy highlight to sell the "cartridge" look.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(80),
                      Colors.white.withAlpha(0),
                      Colors.black.withAlpha(60),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // White rim border.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withAlpha(180),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
