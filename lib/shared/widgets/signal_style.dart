import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estilo "señal" (inspirado en sss.applibot.co.jp): rojo señal + pizarra,
/// tipografía ancha, esquinas biseladas, contornos y barridos de color.
const kSignalRed = Color(0xFFFF3B1F);
const kSignalSlate = Color(0xFF3A3D4E);
const kSignalInk = Color(0xFF0B0B10);

TextStyle signalFont({
  double fontSize = 12,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double letterSpacing = 1.2,
  double? height,
  Paint? foreground,
  List<Shadow>? shadows,
}) => GoogleFonts.chakraPetch(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: foreground == null ? color : null,
  letterSpacing: letterSpacing,
  height: height,
  foreground: foreground,
  shadows: shadows,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// Serif de la misma familia que el rótulo Evangelion, en el corte de texto
/// (Noto Serif) para que se lea a tamaño de lista.
TextStyle evaTitleFont({
  double fontSize = 15,
  Color? color,
  double height = 1.22,
  double letterSpacing = 0.3,
}) => GoogleFonts.notoSerif(
  fontSize: fontSize,
  fontWeight: FontWeight.w700,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

/// Esquinas superior derecha e inferior izquierda cortadas en bisel.
/// Con [radius] > 0 todos los vértices (también los del bisel) se suavizan.
/// [bevelBottomLeft] = false deja esa esquina como las demás (sin bisel).
ShapeBorder signalChamfer(
  double cut, {
  BorderSide side = BorderSide.none,
  double radius = 0,
  bool bevelBottomLeft = true,
}) => radius > 0 || !bevelBottomLeft
    ? SignalChamferBorder(
        cut: cut,
        radius: radius,
        side: side,
        bevelBottomLeft: bevelBottomLeft,
      )
    : BeveledRectangleBorder(
        side: side,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(cut),
          bottomLeft: Radius.circular(cut),
        ),
      );

/// Bisel señal con vértices redondeados (lista de biblioteca, trofeos).
class SignalChamferBorder extends OutlinedBorder {
  const SignalChamferBorder({
    required this.cut,
    required this.radius,
    this.bevelBottomLeft = true,
    super.side,
  });

  final double cut;
  final double radius;
  final bool bevelBottomLeft;

  Path _path(Rect rect) {
    final c = cut.clamp(0.0, rect.shortestSide / 2);
    if (c <= 0.5) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    }
    final pts = [
      rect.topLeft,
      Offset(rect.right - c, rect.top),
      Offset(rect.right, rect.top + c),
      rect.bottomRight,
      if (bevelBottomLeft) ...[
        Offset(rect.left + c, rect.bottom),
        Offset(rect.left, rect.bottom - c),
      ] else
        rect.bottomLeft,
    ];
    // Each vertex is replaced by a curve that starts and ends `d` away from
    // it along both edges (half an edge at most so curves never overlap).
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final v = pts[i];
      final toPrev = pts[(i + pts.length - 1) % pts.length] - v;
      final toNext = pts[(i + 1) % pts.length] - v;
      final d = [
        radius,
        toPrev.distance / 2,
        toNext.distance / 2,
      ].reduce((a, b) => a < b ? a : b);
      final a = v + toPrev / toPrev.distance * d;
      final b = v + toNext / toNext.distance * d;
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(v.dx, v.dy, b.dx, b.dy);
    }
    return path..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(_path(rect.deflate(side.strokeInset / 2)), side.toPaint());
  }

  @override
  SignalChamferBorder copyWith({BorderSide? side}) => SignalChamferBorder(
    cut: cut,
    radius: radius,
    bevelBottomLeft: bevelBottomLeft,
    side: side ?? this.side,
  );

  @override
  ShapeBorder scale(double t) => SignalChamferBorder(
    cut: cut * t,
    radius: radius * t,
    bevelBottomLeft: bevelBottomLeft,
    side: side.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SignalChamferBorder) {
      return SignalChamferBorder(
        cut: lerpDouble(a.cut, cut, t)!,
        radius: lerpDouble(a.radius, radius, t)!,
        bevelBottomLeft: bevelBottomLeft,
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SignalChamferBorder) {
      return SignalChamferBorder(
        cut: lerpDouble(cut, b.cut, t)!,
        radius: lerpDouble(radius, b.radius, t)!,
        bevelBottomLeft: b.bevelBottomLeft,
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is SignalChamferBorder &&
      other.cut == cut &&
      other.radius == radius &&
      other.bevelBottomLeft == bevelBottomLeft &&
      other.side == side;

  @override
  int get hashCode => Object.hash(cut, radius, bevelBottomLeft, side);
}

String signalIndex(int n) => n.toString().padLeft(2, '0');

Color signalOnColor(Color c) =>
    ThemeData.estimateBrightnessForColor(c) == Brightness.dark
    ? Colors.white
    : Colors.black87;

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Texto solo con contorno (los títulos huecos de la web de referencia).
class SignalOutlineText extends StatelessWidget {
  const SignalOutlineText(
    this.text, {
    super.key,
    required this.fontSize,
    required this.color,
    this.strokeWidth = 1.2,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing = 1.5,
    this.maxLines = 1,
  });

  final String text;
  final double fontSize;
  final Color color;
  final double strokeWidth;
  final FontWeight fontWeight;
  final double letterSpacing;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.clip,
      softWrap: false,
      style: signalFont(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: 1,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = color,
      ),
    );
  }
}

/// Líneas verticales finas de fondo. Se pinta una vez en su propia capa.
class SignalGridBackdrop extends StatelessWidget {
  const SignalGridBackdrop({super.key, required this.color, this.columns = 6});

  final Color color;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(color, columns),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color, this.columns);

  final Color color;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 1; i < columns; i++) {
      final x = (size.width * i / columns).roundToDouble() + 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color || old.columns != columns;
}

/// Barrido de revelado: un bloque de [color] cubre el hueco de izquierda a
/// derecha, el contenido aparece debajo y el bloque se retira hacia la
/// derecha. Solo repinta la capa del bloque mientras [animation] avanza.
class SignalReveal extends StatelessWidget {
  const SignalReveal({
    super.key,
    required this.animation,
    required this.color,
    required this.child,
    this.shape,
    this.slide = 12,
  });

  final Animation<double> animation;
  final Color color;
  final Widget child;
  final ShapeBorder? shape;
  final double slide;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return child;
    final content = RepaintBoundary(child: child);
    return Stack(
      children: [
        AnimatedBuilder(
          animation: animation,
          child: content,
          builder: (context, c) {
            final t = animation.value;
            final shown = t >= 0.5;
            final dx = shown
                ? -slide * (1 - Curves.easeOutCubic.transform((t - 0.5) * 2))
                : 0.0;
            return Opacity(
              opacity: shown ? 1 : 0,
              child: Transform.translate(offset: Offset(dx, 0), child: c),
            );
          },
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _WipePainter(animation, color, shape)),
          ),
        ),
      ],
    );
  }
}

class _WipePainter extends CustomPainter {
  _WipePainter(this.animation, this.color, this.shape)
    : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final ShapeBorder? shape;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0 || t >= 1) return;
    final double left;
    final double right;
    if (t < 0.5) {
      left = 0;
      right = Curves.easeOutCubic.transform(t * 2);
    } else {
      left = Curves.easeInCubic.transform((t - 0.5) * 2);
      right = 1;
    }
    final bounds = Offset.zero & size;
    if (shape != null) canvas.clipPath(shape!.getOuterPath(bounds));
    canvas.drawRect(
      Rect.fromLTRB(size.width * left, 0, size.width * right, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_WipePainter old) =>
      old.color != color || old.shape != shape;
}

/// [SignalReveal] con su propio controlador: se reproduce una vez si [play].
/// Sin [play] no crea controlador ni ticker.
class SignalAutoReveal extends StatefulWidget {
  const SignalAutoReveal({
    super.key,
    required this.child,
    required this.color,
    required this.play,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 440),
    this.shape,
  });

  final Widget child;
  final Color color;
  final bool play;
  final Duration delay;
  final Duration duration;
  final ShapeBorder? shape;

  @override
  State<SignalAutoReveal> createState() => _SignalAutoRevealState();
}

class _SignalAutoRevealState extends State<SignalAutoReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.play) return;
    final c = AnimationController(vsync: this, duration: widget.duration);
    _controller = c;
    if (widget.delay == Duration.zero) {
      c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalReveal(
      animation: _controller ?? kAlwaysCompleteAnimation,
      color: widget.color,
      shape: widget.shape,
      child: widget.child,
    );
  }
}

/// Superficie biselada seleccionable: al activarse, el color de acento entra
/// en barrido desde la izquierda.
class SignalSelectable extends StatelessWidget {
  const SignalSelectable({
    super.key,
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.builder,
    this.cut = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.background,
    this.idleForeground,
  });

  final bool selected;
  final Color accent;
  final VoidCallback? onTap;
  final Widget Function(Color foreground) builder;
  final double cut;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final Color? idleForeground;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shape = signalChamfer(cut);
    final idleFg = idleForeground ?? cs.onSurfaceVariant;
    final onAccent = signalOnColor(accent);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 1 : 0),
      duration: _reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Material(
          color: background ?? cs.surfaceContainerHigh,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: CustomPaint(
              painter: _FillPainter(t, accent),
              child: Padding(
                padding: padding,
                child: builder(Color.lerp(idleFg, onAccent, t)!),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FillPainter extends CustomPainter {
  _FillPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * t, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_FillPainter old) => old.t != t || old.color != color;
}

/// Barra de progreso de segmentos inclinados.
class SignalSegmentBar extends StatelessWidget {
  const SignalSegmentBar({
    super.key,
    required this.fraction,
    required this.accent,
    this.segments = 20,
    this.height = 10,
  });

  final double fraction;
  final Color accent;
  final int segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction),
      duration: _reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, f, _) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SegmentPainter(f, accent, track, segments),
        ),
      ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  _SegmentPainter(this.fraction, this.accent, this.track, this.segments);

  final double fraction;
  final Color accent;
  final Color track;
  final int segments;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 3.0;
    final skew = size.height * 0.6;
    final segW = (size.width - skew - gap * (segments - 1)) / segments;
    var filled = (fraction * segments).round();
    if (fraction > 0 && filled == 0) filled = 1;
    final on = Paint()..color = accent;
    final off = Paint()..color = track;
    for (var i = 0; i < segments; i++) {
      final x = i * (segW + gap);
      final path = Path()
        ..moveTo(x + skew, 0)
        ..lineTo(x + skew + segW, 0)
        ..lineTo(x + segW, size.height)
        ..lineTo(x, size.height)
        ..close();
      canvas.drawPath(path, i < filled ? on : off);
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      old.fraction != fraction ||
      old.accent != accent ||
      old.track != track ||
      old.segments != segments;
}

/// Tres chevrons decrecientes, como los "NEXT MEMBER" de la referencia.
class SignalChevrons extends StatelessWidget {
  const SignalChevrons({super.key, required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Align(
            widthFactor: 0.55,
            child: Icon(
              Icons.chevron_right_rounded,
              size: size,
              color: color.withAlpha(255 - i * 80),
            ),
          ),
      ],
    );
  }
}
