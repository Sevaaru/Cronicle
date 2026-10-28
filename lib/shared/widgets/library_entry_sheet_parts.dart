import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/remote_network_image.dart';

/// Color de acento por tipo (mismo que las tarjetas de la biblioteca).
Color entryKindAccent(MediaKind kind) => switch (kind) {
      MediaKind.anime => const Color(0xFF7C4DFF),
      MediaKind.manga => const Color(0xFFEC407A),
      MediaKind.movie => const Color(0xFFFF7043),
      MediaKind.tv => const Color(0xFF26A69A),
      MediaKind.game => const Color(0xFF42A5F5),
      MediaKind.book => const Color(0xFFAB47BC),
    };

Color _edgeOf(Color c) => Color.lerp(c, Colors.black, 0.38)!;

Color _onColor(Color c) =>
    ThemeData.estimateBrightnessForColor(c) == Brightness.dark
        ? Colors.white
        : Colors.black87;

const _tabular = [ui.FontFeature.tabularFigures()];

/// Carátula del editor: póster como etiqueta de cartucho sobre su propio
/// fondo difuminado.
class CartridgeHeader extends StatelessWidget {
  const CartridgeHeader({
    super.key,
    required this.title,
    required this.kindLabel,
    required this.kindIcon,
    required this.accent,
    required this.badge,
    this.posterUrl,
  });

  final String title;
  final String kindLabel;
  final IconData kindIcon;
  final Color accent;
  final String badge;
  final String? posterUrl;

  @override
  Widget build(BuildContext context) {
    final hasPoster = posterUrl != null && posterUrl!.isNotEmpty;
    final placeholder = ColoredBox(
      color: accent.withAlpha(90),
      child: Center(child: Icon(kindIcon, color: Colors.white, size: 30)),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPoster)
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: RemoteNetworkImage(
                  imageUrl: posterUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 120,
                  placeholder: ColoredBox(color: accent.withAlpha(60)),
                  error: ColoredBox(color: accent.withAlpha(60)),
                ),
              )
            else
              ColoredBox(color: accent.withAlpha(70)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withAlpha(210),
                    Color.lerp(Colors.black, accent, 0.45)!.withAlpha(170),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 16,
              child: Row(
                children: List.generate(
                  5,
                  (_) => Container(
                    width: 4,
                    height: 18,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(55),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Row(
                children: [
                  Transform.rotate(
                    angle: -0.06,
                    child: Container(
                      width: 82,
                      height: 114,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(130),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.5),
                        child: hasPoster
                            ? RemoteNetworkImage(
                                imageUrl: posterUrl!,
                                width: 82,
                                height: 114,
                                fit: BoxFit.cover,
                                placeholder: placeholder,
                                error: placeholder,
                              )
                            : placeholder,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(kindIcon,
                                      size: 13, color: _onColor(accent)),
                                  const SizedBox(width: 4),
                                  Text(
                                    kindLabel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      color: _onColor(accent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.rotate(
                              angle: -0.07,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(220),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón "físico": borde inferior sólido que se hunde al pulsar.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    this.foreground,
    this.depth = 4,
    this.radius = 14,
    this.padding = const EdgeInsets.all(12),
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? foreground;
  final double depth;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? tooltip;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.onTap != null;
    final face = enabled ? widget.color : cs.surfaceContainerHighest;
    final fg = enabled
        ? (widget.foreground ?? _onColor(face))
        : cs.onSurface.withAlpha(80);
    final sink = _pressed ? widget.depth - 1 : 0.0;

    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.depth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, sink, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: enabled ? _edgeOf(face) : cs.surfaceContainerHigh,
                offset: Offset(0, widget.depth - sink),
              ),
            ],
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: 22),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
              child: Center(widthFactor: 1, heightFactor: 1, child: widget.child),
            ),
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return Semantics(button: true, enabled: enabled, child: button);
  }
}

/// Bloque del editor: superficie tonal con icono y título sencillos.
class CartridgeSection extends StatelessWidget {
  const CartridgeSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Número cuyos dígitos ruedan hacia arriba o abajo al cambiar.
class OdometerText extends StatefulWidget {
  const OdometerText({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  State<OdometerText> createState() => _OdometerTextState();
}

class _OdometerTextState extends State<OdometerText> {
  bool _up = true;

  @override
  void didUpdateWidget(covariant OdometerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _up = widget.value > oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    final digits = '${widget.value}'.split('');
    final style = widget.style.copyWith(fontFeatures: _tabular);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < digits.length; i++)
          ClipRect(
            key: ValueKey(digits.length - i),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final incoming = child.key == ValueKey(digits[i]);
                final dir = _up ? 1.0 : -1.0;
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, incoming ? dir : -dir),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: Text(digits[i], key: ValueKey(digits[i]), style: style),
            ),
          ),
      ],
    );
  }
}

/// Barra de "vida" por segmentos para el progreso.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.fraction, required this.accent});

  final double fraction;
  final Color accent;

  static const _segments = 20;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    var filled = (fraction * _segments).round();
    if (fraction > 0 && filled == 0) filled = 1;
    return Row(
      children: [
        for (var i = 0; i < _segments; i++)
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 160 + i * 12),
              curve: Curves.easeOut,
              height: 9,
              margin: EdgeInsets.only(right: i == _segments - 1 ? 0 : 3),
              decoration: BoxDecoration(
                color: i < filled ? accent : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

Future<int?> _askNumber(
  BuildContext context, {
  required String title,
  required String initial,
  int? max,
}) {
  final ctrl = TextEditingController(text: initial);
  final material = MaterialLocalizations.of(context);
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        decoration: InputDecoration(suffixText: max != null ? '/ $max' : null),
        onSubmitted: (t) => Navigator.of(ctx).pop(int.tryParse(t)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(int.tryParse(ctrl.text)),
          child: Text(material.okButtonLabel),
        ),
      ],
    ),
  );
}

/// Contador grande con botones físicos, dígitos que ruedan y barra de
/// segmentos. Tocar el número abre el teclado.
class CartridgeCounter extends StatelessWidget {
  const CartridgeCounter({
    super.key,
    required this.controller,
    required this.accent,
    required this.title,
    required this.tapHint,
    this.max,
    this.maxLabel,
    this.onMax,
    this.footer,
  });

  final TextEditingController controller;
  final Color accent;
  final String title;
  final String tapHint;
  final int? max;
  final String? maxLabel;
  final VoidCallback? onMax;
  final Widget Function(int value)? footer;

  void _set(int value) => controller.text = '$value';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final current = int.tryParse(value.text) ?? 0;
        final canAdd = max == null || current < max!;
        final fraction =
            max != null && max! > 0 ? (current / max!).clamp(0.0, 1.0) : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ChunkyButton(
                  color: cs.surfaceContainerHighest,
                  foreground: cs.onSurface,
                  onTap: current > 0 ? () => _set(current - 1) : null,
                  child: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Tooltip(
                    message: tapHint,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final v = await _askNumber(
                          context,
                          title: title,
                          initial: value.text,
                          max: max,
                        );
                        if (v != null) _set(max != null ? v.clamp(0, max!) : v);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            OdometerText(
                              value: current,
                              style: TextStyle(
                                fontSize: 40,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                            if (max != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  ' /$max',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurfaceVariant,
                                    fontFeatures: _tabular,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ChunkyButton(
                  color: accent,
                  onTap: canAdd ? () => _set(current + 1) : null,
                  child: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            if (fraction != null) ...[
              const SizedBox(height: 10),
              _SegmentBar(fraction: fraction, accent: accent),
            ],
            if (onMax != null || footer != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: footer?.call(current) ?? const SizedBox()),
                  if (onMax != null)
                    ChunkyButton(
                      color: accent.withAlpha(50),
                      foreground: accent,
                      depth: 3,
                      radius: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      onTap: canAdd ? onMax : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(maxLabel ?? '', style: const TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

typedef CartridgeStatusOption = ({String key, IconData icon, String label});

/// Rejilla de estados como teclas gruesas; la elegida rebota.
class CartridgeStatusGrid extends StatelessWidget {
  const CartridgeStatusGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  final List<CartridgeStatusOption> options;
  final String selected;
  final Color accent;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final cols = constraints.maxWidth > 440 ? 4 : 3;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final o in options)
              SizedBox(
                width: width,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('${o.key}-${o.key == selected}'),
                  tween: Tween(begin: o.key == selected ? 0.82 : 1, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.elasticOut,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: ChunkyButton(
                    color: o.key == selected
                        ? accent
                        : cs.surfaceContainerHighest,
                    foreground: o.key == selected
                        ? _onColor(accent)
                        : cs.onSurfaceVariant,
                    depth: o.key == selected ? 4 : 3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    onTap: () => onSelect(o.key),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(o.icon, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          o.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: o.key == selected
                                ? FontWeight.w900
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Repeticiones como sellos de tarjeta de fidelidad; el nuevo cae "estampado".
class CartridgeRepeatStamps extends StatelessWidget {
  const CartridgeRepeatStamps({
    super.key,
    required this.count,
    required this.accent,
    required this.summary,
    required this.hint,
    required this.onChanged,
  });

  final int count;
  final Color accent;
  final String summary;
  final String hint;
  final ValueChanged<int> onChanged;

  static const _size = 42.0;
  static const _step = 34.0;
  static const _angles = [-0.22, 0.14, -0.08, 0.2, -0.16];

  Widget _stamp(Color color, Widget content, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: _size,
        height: _size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha(40),
          border: Border.all(color: color, width: 2.5),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(130)),
          ),
          child: Center(child: content),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _size + 6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fit = ((constraints.maxWidth - _size) / _step)
                            .floor() +
                        1;
                    final overflow = count > fit;
                    final shown = overflow ? fit - 1 : count;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (count == 0)
                          Positioned(
                            left: 0,
                            top: 3,
                            child: _stamp(
                              cs.outlineVariant,
                              Icon(Icons.replay_rounded,
                                  size: 16, color: cs.outlineVariant),
                              _angles[0],
                            ),
                          ),
                        for (var i = 0; i < shown; i++)
                          Positioned(
                            key: ValueKey('stamp-$i'),
                            left: i * _step,
                            top: 3,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutBack,
                              builder: (_, t, child) => Opacity(
                                opacity: t.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 1.8 - 0.8 * t,
                                  child: child,
                                ),
                              ),
                              child: _stamp(
                                accent,
                                Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  ),
                                ),
                                _angles[i % _angles.length],
                              ),
                            ),
                          ),
                        if (overflow)
                          Positioned(
                            left: shown * _step,
                            top: 3,
                            child: _stamp(
                              accent,
                              Text(
                                '+${count - shown}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: accent,
                                ),
                              ),
                              0.1,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            ChunkyButton(
              color: cs.surfaceContainerHighest,
              foreground: cs.onSurface,
              padding: const EdgeInsets.all(10),
              onTap: count > 0 ? () => onChanged(count - 1) : null,
              child: const Icon(Icons.remove_rounded, size: 20),
            ),
            const SizedBox(width: 8),
            ChunkyButton(
              color: accent,
              padding: const EdgeInsets.all(10),
              onTap: () => onChanged(count + 1),
              child: const Icon(Icons.add_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          summary,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hint,
          style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Estrellas (o caras en POINT_3) que se iluminan con rebote. Media estrella
/// tocando la mitad izquierda; tocar el valor actual lo borra.
class CartridgeScoreStars extends StatefulWidget {
  const CartridgeScoreStars({
    super.key,
    required this.value,
    required this.scoring,
    required this.emptyLabel,
    required this.onChanged,
    required this.onTapNumber,
  });

  final double value;
  final ScoringSystem scoring;
  final String emptyLabel;
  final ValueChanged<double> onChanged;
  final VoidCallback onTapNumber;

  @override
  State<CartridgeScoreStars> createState() => _CartridgeScoreStarsState();
}

class _CartridgeScoreStarsState extends State<CartridgeScoreStars> {
  int? _bounced;
  int _tick = 0;

  static const _faces = [
    Icons.sentiment_very_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_very_satisfied_rounded,
  ];

  bool get _isFaces => widget.scoring == ScoringSystem.point3;
  int get _count => _isFaces ? 3 : 5;
  bool get _allowHalf =>
      widget.scoring != ScoringSystem.point5 && !_isFaces;

  double _fill(int i) {
    if (_isFaces) return widget.value.round() == i + 1 ? 1 : 0;
    final perStar = widget.scoring.max / _count;
    return ((widget.value - i * perStar) / perStar).clamp(0.0, 1.0);
  }

  void _tap(int i, bool leftHalf) {
    final perStar = widget.scoring.max / _count;
    var target = _allowHalf && leftHalf ? (i + 0.5) * perStar : (i + 1) * perStar;
    target = widget.scoring == ScoringSystem.point10Decimal
        ? (target * 10).round() / 10
        : target.roundToDouble();
    if ((target - widget.value).abs() < 0.001) target = 0;
    HapticFeedback.selectionClick();
    setState(() {
      _bounced = i;
      _tick++;
    });
    widget.onChanged(target);
  }

  String _number() {
    final v = widget.value;
    if (v <= 0) return widget.emptyLabel;
    return switch (widget.scoring) {
      ScoringSystem.point100 => '${v.round()}',
      ScoringSystem.point10Decimal => v.toStringAsFixed(1),
      ScoringSystem.point10 => '${v.round()}',
      ScoringSystem.point5 => '${v.round()}/5',
      ScoringSystem.point3 => widget.scoring.formatScore(v),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gold = Colors.amber.shade500;
    final hasScore = widget.value > 0;
    const size = 34.0;

    return Row(
      children: [
        for (var i = 0; i < _count; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tap(i, d.localPosition.dx < size / 2 + 2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_bounced == i ? _tick : -1),
                tween: Tween(begin: _bounced == i ? 1.45 : 1, end: 1),
                duration: const Duration(milliseconds: 520),
                curve: Curves.elasticOut,
                builder: (_, s, child) => Transform.scale(scale: s, child: child),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    children: [
                      Icon(
                        _isFaces ? _faces[i] : Icons.star_rounded,
                        size: size,
                        color: cs.surfaceContainerHighest,
                      ),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _fill(i),
                          child: Icon(
                            _isFaces ? _faces[i] : Icons.star_rounded,
                            size: size,
                            color: gold,
                            shadows: [
                              Shadow(color: gold.withAlpha(150), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        ChunkyButton(
          color: hasScore ? gold.withAlpha(45) : cs.surfaceContainerHighest,
          foreground: hasScore ? Colors.amber.shade600 : cs.onSurfaceVariant,
          depth: 3,
          radius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          onTap: widget.onTapNumber,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _number(),
                style: TextStyle(
                  fontSize: hasScore ? 22 : 13,
                  fontWeight: FontWeight.w900,
                  fontFeatures: _tabular,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 13),
            ],
          ),
        ),
      ],
    );
  }
}
