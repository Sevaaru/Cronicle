import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/features/profile/presentation/profile_page.dart';

/// Radio mínimo para que el reveal arranque “desde el avatar” (evita punto invisible).
double _beginRevealRadius(Rect? rect, Size screen) {
  if (rect != null) {
    return math.max(rect.width, rect.height) * 0.55;
  }
  return screen.shortestSide * 0.06;
}

double _endRevealRadius(Offset center, Size size) {
  const pad = 12.0;
  final corners = <Offset>[
    Offset.zero,
    Offset(size.width, 0),
    Offset(0, size.height),
    Offset(size.width, size.height),
  ];
  var maxD = 0.0;
  for (final c in corners) {
    maxD = math.max(maxD, (c - center).distance);
  }
  return maxD + pad;
}

Offset _revealCenter(Rect? rect, Size size) {
  if (rect != null) {
    return rect.center;
  }
  // Fallback: zona del leading del AppBar (~arriba a la izquierda).
  return Offset(size.width * 0.1, size.height * 0.08);
}

/// Apertura/cierre tipo “circular reveal” (contenido del perfil dentro del círculo que crece o mengua).
CustomTransitionPage<void> buildProfileTransitionPage(GoRouterState state) {
  final originRect = state.extra is Rect ? state.extra as Rect : null;

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: const ProfilePage(),
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final size = MediaQuery.sizeOf(context);
      final center = _revealCenter(originRect, size);
      final beginR = _beginRevealRadius(originRect, size);
      final endR = _endRevealRadius(center, size);

      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final t = curved.value;
          final radius = beginR + (endR - beginR) * t;
          return ClipPath(
            clipper: _CircleRevealClipper(center: center, radius: radius),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );
    },
  );
}

class _CircleRevealClipper extends CustomClipper<Path> {
  _CircleRevealClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _CircleRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}
