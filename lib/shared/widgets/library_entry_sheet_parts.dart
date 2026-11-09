import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/remote_network_image.dart';
import 'package:cronicle/shared/widgets/signal_style.dart';

/// Color de acento por tipo (mismo que las tarjetas de la biblioteca).
Color entryKindAccent(MediaKind kind) => switch (kind) {
  MediaKind.anime => const Color(0xFF7C4DFF),
  MediaKind.manga => const Color(0xFFEC407A),
  MediaKind.movie => const Color(0xFFFF7043),
  MediaKind.tv => const Color(0xFF26A69A),
  MediaKind.game => const Color(0xFF42A5F5),
  MediaKind.book => const Color(0xFFAB47BC),
};

const _tabular = [ui.FontFeature.tabularFigures()];

/// Tramo [begin]..[end] de [parent]. Usa `drive` para no registrar listeners
/// en el controlador cada vez que se reconstruye.
Animation<double> signalInterval(
  Animation<double> parent,
  double begin,
  double end,
) => parent.drive(CurveTween(curve: Interval(begin, end.clamp(begin, 1.0))));

/// Cabecera del editor: tiras verticales acento/pizarra que entran
/// escalonadas sobre el póster, póster biselado y etiqueta vertical hueca.
class SignalEntryHeader extends StatelessWidget {
  const SignalEntryHeader({
    super.key,
    required this.title,
    required this.kindLabel,
    required this.kindIcon,
    required this.accent,
    required this.badge,
    required this.intro,
    this.posterUrl,
  });

  final String title;
  final String kindLabel;
  final IconData kindIcon;
  final Color accent;
  final String badge;
  final Animation<double> intro;
  final String? posterUrl;

  @override
  Widget build(BuildContext context) {
    final hasPoster = posterUrl != null && posterUrl!.isNotEmpty;
    final placeholder = ColoredBox(
      color: accent.withAlpha(90),
      child: Center(child: Icon(kindIcon, color: Colors.white, size: 30)),
    );
    final posterShape = signalChamfer(12);

    return RepaintBoundary(
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: signalChamfer(24)),
        child: SizedBox(
          height: 176,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: kSignalInk),
              if (hasPoster)
                RemoteNetworkImage(
                  imageUrl: posterUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 220,
                  placeholder: const SizedBox.shrink(),
                  error: const SizedBox.shrink(),
                ),
              CustomPaint(painter: _HeaderStripsPainter(intro, accent)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0, 0.75],
                    colors: [Color(0xD90B0B10), Color(0x000B0B10)],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                bottom: 14,
                right: 8,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SignalOutlineText(
                      kindLabel.toUpperCase(),
                      fontSize: 30,
                      color: Colors.white.withAlpha(170),
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 52, 18),
                child: Row(
                  children: [
                    SignalReveal(
                      animation: signalInterval(intro, 0.25, 0.75),
                      color: accent,
                      shape: posterShape,
                      child: Container(
                        width: 90,
                        height: 128,
                        decoration: ShapeDecoration(
                          shape: signalChamfer(
                            12,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: ClipPath(
                          clipper: ShapeBorderClipper(shape: posterShape),
                          child: hasPoster
                              ? RemoteNetworkImage(
                                  imageUrl: posterUrl!,
                                  width: 90,
                                  height: 128,
                                  fit: BoxFit.cover,
                                  placeholder: placeholder,
                                  error: placeholder,
                                )
                              : placeholder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SignalReveal(
                        animation: signalInterval(intro, 0.38, 0.9),
                        color: Colors.white,
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
                                  decoration: ShapeDecoration(
                                    color: accent,
                                    shape: signalChamfer(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        kindIcon,
                                        size: 13,
                                        color: signalOnColor(accent),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          kindLabel.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: signalFont(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: signalOnColor(accent),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    7,
                                    3,
                                    4,
                                    3,
                                  ),
                                  decoration: ShapeDecoration(
                                    shape: signalChamfer(
                                      6,
                                      side: BorderSide(
                                        color: Colors.white.withAlpha(200),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        badge,
                                        style: signalFont(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.6,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 5,
                                        height: 11,
                                        color: kSignalRed,
                                      ),
                                    ],
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
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiras verticales translúcidas (acento/pizarra alternos) que entran desde
/// arriba y abajo, más una línea de acento inferior que crece.
class _HeaderStripsPainter extends CustomPainter {
  _HeaderStripsPainter(this.intro, this.accent) : super(repaint: intro);

  final Animation<double> intro;
  final Color accent;

  static const _strips = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final t = intro.value;
    final w = size.width / _strips;
    final accentPaint = Paint()..color = accent.withAlpha(150);
    final slatePaint = Paint()..color = kSignalSlate.withAlpha(200);
    final linePaint = Paint()..color = Colors.black.withAlpha(90);
    for (var i = 0; i < _strips; i++) {
      final start = i * 0.06;
      final local = ((t - start) / 0.45).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(local);
      final dir = i.isEven ? -1.0 : 1.0;
      final dy = dir * size.height * (1 - eased);
      final rect = Rect.fromLTWH(i * w, dy, w + 0.5, size.height);
      canvas.drawRect(rect, i.isEven ? slatePaint : accentPaint);
      if (i > 0) {
        canvas.drawRect(Rect.fromLTWH(i * w, 0, 1, size.height), linePaint);
      }
    }
    final line = Curves.easeOutCubic.transform(
      ((t - 0.4) / 0.6).clamp(0.0, 1.0),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 3, size.width * line, 3),
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(_HeaderStripsPainter old) =>
      old.intro != intro || old.accent != accent;
}

/// Botón plano biselado que se encoge y oscurece al pulsar.
class SignalButton extends StatefulWidget {
  const SignalButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    this.foreground,
    this.cut = 8,
    this.padding = const EdgeInsets.all(12),
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? foreground;
  final double cut;
  final EdgeInsetsGeometry padding;
  final String? tooltip;

  @override
  State<SignalButton> createState() => _SignalButtonState();
}

class _SignalButtonState extends State<SignalButton> {
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
        ? (widget.foreground ?? signalOnColor(face))
        : cs.onSurface.withAlpha(80);

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
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          padding: widget.padding,
          decoration: ShapeDecoration(
            color: _pressed ? Color.lerp(face, Colors.black, 0.18) : face,
            shape: signalChamfer(widget.cut),
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: 22),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: widget.child,
              ),
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

/// Bloque del editor: superficie biselada con índice hueco ("01"), título en
/// mayúsculas y una regla de acento. Entra con barrido si recibe [reveal].
class SignalSection extends StatelessWidget {
  const SignalSection({
    super.key,
    required this.index,
    required this.accent,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.reveal,
  });

  final int index;
  final Color accent;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final Animation<double>? reveal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shape = signalChamfer(16);
    Widget body = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: ShapeDecoration(color: cs.surfaceContainerHigh, shape: shape),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SignalOutlineText(
                signalIndex(index),
                fontSize: 24,
                color: accent,
                letterSpacing: 1,
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: signalFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: cs.onSurface,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 18, height: 2, color: accent),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 1,
                  color: cs.outlineVariant.withAlpha(90),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
    if (reveal != null) {
      body = SignalReveal(
        animation: reveal!,
        color: accent,
        shape: shape,
        child: body,
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: body);
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
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
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
        style: signalFont(fontSize: 30, fontWeight: FontWeight.w700),
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

/// Contador grande con dígitos que ruedan y barra de segmentos inclinados.
/// Tocar el número abre el teclado.
class SignalCounter extends StatelessWidget {
  const SignalCounter({
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
        final fraction = max != null && max! > 0
            ? (current / max!).clamp(0.0, 1.0)
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SignalButton(
                  color: cs.surfaceContainerHighest,
                  foreground: cs.onSurface,
                  onTap: current > 0 ? () => _set(current - 1) : null,
                  child: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Tooltip(
                    message: tapHint,
                    child: InkWell(
                      onTap: () async {
                        final v = await _askNumber(
                          context,
                          title: title,
                          initial: value.text,
                          max: max,
                        );
                        if (v != null) _set(max != null ? v.clamp(0, max!) : v);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          OdometerText(
                            value: current,
                            style: signalFont(
                              fontSize: 42,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                              color: cs.onSurface,
                            ),
                          ),
                          if (max != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 7,
                                left: 4,
                              ),
                              child: SignalOutlineText(
                                '/$max',
                                fontSize: 20,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SignalButton(
                  color: accent,
                  onTap: canAdd ? () => _set(current + 1) : null,
                  child: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            if (fraction != null) ...[
              const SizedBox(height: 12),
              SignalSegmentBar(fraction: fraction, accent: accent),
            ],
            if (onMax != null || footer != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: footer?.call(current) ?? const SizedBox()),
                  if (onMax != null)
                    SignalButton(
                      color: accent.withAlpha(45),
                      foreground: accent,
                      cut: 6,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      onTap: canAdd ? onMax : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            (maxLabel ?? '').toUpperCase(),
                            style: signalFont(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

typedef SignalStatusOption = ({String key, IconData icon, String label});

/// Rejilla de estados: teclas biseladas; la elegida se rellena en barrido.
class SignalStatusGrid extends StatelessWidget {
  const SignalStatusGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  final List<SignalStatusOption> options;
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
                child: SignalSelectable(
                  selected: o.key == selected,
                  accent: accent,
                  background: cs.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(o.key);
                  },
                  builder: (fg) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(o.icon, size: 22, color: fg),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          o.label.toUpperCase(),
                          maxLines: 1,
                          style: signalFont(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Repeticiones como fichas numeradas; la nueva cae con un golpe seco.
class SignalRepeatTally extends StatelessWidget {
  const SignalRepeatTally({
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

  static const _size = 36.0;
  static const _step = 42.0;

  Widget _tile(Color color, Widget content, {bool filled = true}) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: filled ? color.withAlpha(40) : null,
        shape: signalChamfer(8, side: BorderSide(color: color, width: 1.5)),
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final numberStyle = signalFont(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: accent,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _size,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fit =
                        ((constraints.maxWidth - _size) / _step).floor() + 1;
                    final overflow = count > fit;
                    final shown = overflow ? fit - 1 : count;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (count == 0)
                          _tile(
                            cs.outlineVariant,
                            Icon(
                              Icons.replay_rounded,
                              size: 16,
                              color: cs.outlineVariant,
                            ),
                            filled: false,
                          ),
                        for (var i = 0; i < shown; i++)
                          Positioned(
                            key: ValueKey('tally-$i'),
                            left: i * _step,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              builder: (_, t, child) => Transform.translate(
                                offset: Offset(0, -10 * (1 - t)),
                                child: Transform.scale(
                                  scale: 1.35 - 0.35 * t,
                                  child: child,
                                ),
                              ),
                              child: _tile(
                                accent,
                                Text(signalIndex(i + 1), style: numberStyle),
                              ),
                            ),
                          ),
                        if (overflow)
                          Positioned(
                            left: shown * _step,
                            child: _tile(
                              accent,
                              Text('+${count - shown}', style: numberStyle),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SignalButton(
              color: cs.surfaceContainerHighest,
              foreground: cs.onSurface,
              padding: const EdgeInsets.all(10),
              onTap: count > 0 ? () => onChanged(count - 1) : null,
              child: const Icon(Icons.remove_rounded, size: 20),
            ),
            const SizedBox(width: 8),
            SignalButton(
              color: accent,
              padding: const EdgeInsets.all(10),
              onTap: () => onChanged(count + 1),
              child: const Icon(Icons.add_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
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

/// Puntuación señal: barra de segmentos inclinados que se toca o arrastra
/// (redondea al paso del sistema) y número grande que abre el teclado.
/// Tocar el valor actual lo borra. [compact] = solo barra + valor.
class SignalScoreBar extends StatelessWidget {
  const SignalScoreBar({
    super.key,
    required this.value,
    required this.scoring,
    required this.accent,
    required this.onChanged,
    this.emptyLabel = '',
    this.onTapNumber,
    this.compact = false,
  });

  final double value;
  final ScoringSystem scoring;
  final Color accent;
  final ValueChanged<double> onChanged;
  final String emptyLabel;
  final VoidCallback? onTapNumber;
  final bool compact;

  static const _faces = [
    Icons.sentiment_very_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_very_satisfied_rounded,
  ];

  int get _segments => switch (scoring) {
    ScoringSystem.point100 => 20,
    ScoringSystem.point10Decimal || ScoringSystem.point10 => 10,
    ScoringSystem.point5 => 5,
    ScoringSystem.point3 => 3,
  };

  double get _step => scoring == ScoringSystem.point10Decimal ? 0.1 : 1;

  double _snap(double v) {
    final snapped = (v.clamp(0.0, scoring.max) / _step).round() * _step;
    return (snapped * 10).round() / 10;
  }

  double _valueAt(double dx, double width) {
    final raw = (dx / width).clamp(0.0, 1.0) * scoring.max;
    final v = ((raw / _step).ceil() * _step).clamp(_step, scoring.max);
    return (v * 10).round() / 10;
  }

  void _set(double v, {bool toggle = false}) {
    if (toggle && (v - value).abs() < 0.001) v = 0;
    if ((v - value).abs() < 0.001) return;
    HapticFeedback.selectionClick();
    onChanged(v);
  }

  String get _number => switch (scoring) {
    ScoringSystem.point10Decimal => value.toStringAsFixed(1),
    _ => '${value.round()}',
  };

  String get _suffix => '/${scoring.max.round()}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final hasScore = value > 0;
    final fraction = value / scoring.max;
    final keyStep = switch (scoring) {
      ScoringSystem.point100 => 5.0,
      ScoringSystem.point10Decimal => 0.5,
      _ => 1.0,
    };

    final bar = Semantics(
      slider: true,
      value: hasScore ? '$_number$_suffix' : emptyLabel,
      onIncrease: () => _set(_snap(value + keyStep)),
      onDecrease: () => _set(_snap(value - keyStep)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) =>
                _set(_valueAt(d.localPosition.dx, width), toggle: true),
            onHorizontalDragStart: (d) =>
                _set(_valueAt(d.localPosition.dx, width)),
            onHorizontalDragUpdate: (d) =>
                _set(_valueAt(d.localPosition.dx, width)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 8 : 6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: fraction),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                builder: (context, f, _) => SizedBox(
                  height: compact ? 10 : 22,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ScoreSegmentsPainter(
                      fraction: f,
                      segments: _segments,
                      accent: accent,
                      track: cs.surfaceContainerHighest,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (compact) {
      return Row(
        children: [
          Expanded(child: bar),
          SizedBox(
            width: 40,
            child: Text(
              hasScore ? _number : '—',
              textAlign: TextAlign.end,
              style: signalFont(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: hasScore ? accent : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    final Widget number;
    if (!hasScore) {
      number = Row(
        key: const ValueKey('empty'),
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SignalOutlineText('--', fontSize: 42, color: cs.outline),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              emptyLabel.toUpperCase(),
              style: signalFont(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    } else if (scoring == ScoringSystem.point3) {
      number = Icon(
        _faces[(value.round() - 1).clamp(0, 2)],
        key: ValueKey(value),
        size: 44,
        color: accent,
      );
    } else {
      number = Row(
        key: ValueKey(value),
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _number,
            style: signalFont(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1,
              color: accent,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _suffix,
              style: signalFont(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    final labelStyle = signalFont(fontSize: 10, color: cs.onSurfaceVariant);
    final Widget ticks;
    if (scoring == ScoringSystem.point100) {
      ticks = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final t in const [0, 25, 50, 75, 100])
            Text(
              signalIndex(t),
              style: labelStyle.copyWith(
                color: hasScore && t > 0 && value >= t ? accent : null,
              ),
            ),
        ],
      );
    } else {
      final per = scoring.max / _segments;
      ticks = Row(
        children: [
          for (var i = 0; i < _segments; i++)
            Expanded(
              child: Center(
                child: scoring == ScoringSystem.point3
                    ? Icon(
                        _faces[i],
                        size: 16,
                        color: value.round() == i + 1
                            ? accent
                            : cs.onSurfaceVariant.withAlpha(140),
                      )
                    : Text(
                        '${i + 1}',
                        style: labelStyle.copyWith(
                          color: value >= (i + 1) * per - 0.001 ? accent : null,
                        ),
                      ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapNumber,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.bottomLeft,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.35),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: number,
                  ),
                ),
              ),
            ),
            if (hasScore) ...[
              SignalButton(
                color: cs.surfaceContainerHighest,
                foreground: cs.onSurfaceVariant,
                cut: 6,
                padding: const EdgeInsets.all(8),
                onTap: () => onChanged(0),
                child: const Icon(Icons.close_rounded, size: 18),
              ),
              const SizedBox(width: 8),
            ],
            if (onTapNumber != null)
              SignalButton(
                color: accent.withAlpha(40),
                foreground: accent,
                cut: 6,
                padding: const EdgeInsets.all(8),
                onTap: onTapNumber,
                child: const Icon(Icons.keyboard_rounded, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 8),
        bar,
        const SizedBox(height: 2),
        ticks,
      ],
    );
  }
}

/// Segmentos paralelogramo; el último encendido se rellena en proporción
/// para las notas intermedias (decimales, escala de 100).
class _ScoreSegmentsPainter extends CustomPainter {
  _ScoreSegmentsPainter({
    required this.fraction,
    required this.segments,
    required this.accent,
    required this.track,
  });

  final double fraction;
  final int segments;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = segments > 10 ? 3.0 : 4.0;
    final skew = size.height * 0.45;
    final segW = (size.width - skew - gap * (segments - 1)) / segments;
    final on = Paint()..color = accent;
    final off = Paint()..color = track;
    final lit = fraction * segments;
    for (var i = 0; i < segments; i++) {
      final x = i * (segW + gap);
      final path = Path()
        ..moveTo(x + skew, 0)
        ..lineTo(x + skew + segW, 0)
        ..lineTo(x + segW, size.height)
        ..lineTo(x, size.height)
        ..close();
      final fill = (lit - i).clamp(0.0, 1.0);
      if (fill >= 1) {
        canvas.drawPath(path, on);
        continue;
      }
      canvas.drawPath(path, off);
      if (fill > 0) {
        final w = segW * fill;
        canvas.drawPath(
          Path()
            ..moveTo(x + skew, 0)
            ..lineTo(x + skew + w, 0)
            ..lineTo(x + w, size.height)
            ..lineTo(x, size.height)
            ..close(),
          on,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ScoreSegmentsPainter old) =>
      old.fraction != fraction ||
      old.segments != segments ||
      old.accent != accent ||
      old.track != track;
}
