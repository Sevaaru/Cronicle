import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cronicle/shared/widgets/signal_style.dart';

/// Piezas de consola NERV (Evangelion) compartidas por la lista de la
/// biblioteca y la sala de trofeos.

Color nervOrange(Brightness b) =>
    b == Brightness.dark ? const Color(0xFFFF9A1F) : const Color(0xFFC25A00);

/// Color de estado de la biblioteca (valores persistidos en mayúsculas).
Color evaStatusColor(String status, Brightness b) {
  final dark = b == Brightness.dark;
  return switch (status.toUpperCase()) {
    'CURRENT' => dark ? const Color(0xFF5CFF8A) : const Color(0xFF138A3E),
    'REPEATING' => dark ? const Color(0xFFB794FF) : const Color(0xFF6A3FC9),
    'COMPLETED' || 'PLAYED' => nervOrange(b),
    'PLANNING' => dark ? const Color(0xFF6FD3FF) : const Color(0xFF0B7FB0),
    'DROPPED' => kSignalRed,
    _ => dark ? const Color(0xFF9A9CA4) : const Color(0xFF6B6D75),
  };
}

/// Hexágono alargado (puntas a izquierda y derecha) con texto dentro.
class EvaHexBadge extends StatelessWidget {
  const EvaHexBadge({
    super.key,
    required this.text,
    required this.stroke,
    this.fill = const Color(0xB9000000),
    this.foreground = Colors.white,
  });

  final String text;
  final Color stroke;
  final Color fill;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HexPainter(stroke: stroke, fill: fill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: signalFont(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// Fondo de los botones del raíl derecho: entra desde transparente para
/// fundirse con el cuerpo de la tarjeta.
BoxDecoration evaRailFade(Color color) => BoxDecoration(
  gradient: LinearGradient(
    colors: [color.withAlpha(0), color],
    stops: const [0, 0.85],
  ),
);

/// «+» retrofuturista: cruz maciza de una sola pieza con las puntas en
/// chaflán (estilo consola NERV).
class EvaPlusIcon extends StatelessWidget {
  const EvaPlusIcon({super.key, required this.color, this.size = 30});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _PlusPainter(color)),
    );
  }
}

class _PlusPainter extends CustomPainter {
  _PlusPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = s / 2;
    final half = s * 0.11;
    final reach = s / 2 - s * 0.02;
    final chamfer = half * 1.1;

    // Right arm outline (relative to centre), rotated 90° per arm so the
    // whole cross is a single closed path.
    final arm = <Offset>[
      Offset(half, -half),
      Offset(reach - chamfer, -half),
      Offset(reach, -half + chamfer),
      Offset(reach, half),
    ];
    final path = Path();
    for (var i = 0; i < 4; i++) {
      for (final p in arm) {
        var q = p;
        for (var r = 0; r < i; r++) {
          q = Offset(-q.dy, q.dx);
        }
        final point = q + Offset(c, c);
        if (i == 0 && p == arm.first) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PlusPainter old) => old.color != color;
}

class _HexPainter extends CustomPainter {
  _HexPainter({required this.stroke, required this.fill});

  final Color stroke;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = math.min(size.height * 0.4, size.width / 2);
    final h = size.height;
    final path = Path()
      ..moveTo(inset, 0)
      ..lineTo(size.width - inset, 0)
      ..lineTo(size.width, h / 2)
      ..lineTo(size.width - inset, h)
      ..lineTo(inset, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.stroke != stroke || old.fill != fill;
}

/// Lectura de progreso: numerador grande, `/total` pequeño, medidor de
/// barras y porcentaje de tres cifras cuando hay total.
class EvaGaugeRow extends StatelessWidget {
  const EvaGaugeRow({
    super.key,
    required this.progress,
    required this.fraction,
    required this.accent,
    required this.readout,
  });

  final String? progress;
  final double? fraction;
  final Color accent;
  final Color readout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = progress;
    final slash = text?.lastIndexOf('/') ?? -1;
    return Row(
      children: [
        if (text != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: slash > 0 ? text.substring(0, slash) : text,
                  style: signalFont(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    height: 1,
                    color: readout,
                  ),
                ),
                if (slash > 0)
                  TextSpan(
                    text: text.substring(slash),
                    style: signalFont(
                      fontSize: 10.5,
                      letterSpacing: 0.4,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
          ),
        if (fraction != null) ...[
          if (text != null) const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 11,
              child: CustomPaint(
                painter: _GaugePainter(
                  fraction: fraction!,
                  fill: accent,
                  head: readout,
                  track: cs.onSurface.withAlpha(30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(fraction! * 100).round().toString().padLeft(3, '0')}%',
            style: signalFont(
              fontSize: 9.5,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.fill,
    required this.head,
    required this.track,
  });

  final double fraction;
  final Color fill;
  final Color head;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const barW = 2.0;
    const gap = 2.0;
    final count = ((size.width + gap) / (barW + gap)).floor();
    if (count <= 0) return;
    var lit = (fraction * count).round();
    if (fraction > 0 && lit == 0) lit = 1;
    final on = Paint()..color = fill;
    final off = Paint()..color = track;
    final tip = Paint()..color = head;
    for (var i = 0; i < count; i++) {
      final h = i % 5 == 0 ? size.height : size.height * 0.65;
      final paint = i < lit ? (i == lit - 1 && lit < count ? tip : on) : off;
      canvas.drawRect(
        Rect.fromLTWH(i * (barW + gap), size.height - h, barW, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.fill != fill ||
      old.head != head ||
      old.track != track;
}
