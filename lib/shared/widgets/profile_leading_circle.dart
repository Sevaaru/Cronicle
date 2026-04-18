import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mismo tamaño y padding que [ProfileAvatarButton] para alinear la transición perfil ↔ shell.
const double kProfileLeadingCircleSize = 28;

const EdgeInsets kProfileLeadingPadding =
    EdgeInsets.only(left: 10, top: 8, bottom: 8, right: 4);

/// Botón circular con ✕ para cerrar el perfil; misma huella visual que el avatar del AppBar.
class ProfileLeadingCloseButton extends StatefulWidget {
  const ProfileLeadingCloseButton({super.key});

  @override
  State<ProfileLeadingCloseButton> createState() => _ProfileLeadingCloseButtonState();
}

class _ProfileLeadingCloseButtonState extends State<ProfileLeadingCloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = MaterialLocalizations.of(context);

    final core = SizedBox(
      width: kProfileLeadingCircleSize,
      height: kProfileLeadingCircleSize,
      child: ClipOval(
        child: ColoredBox(
          color: cs.surfaceContainerHighest,
          child: Center(
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );

    return Tooltip(
      message: l10n.closeButtonLabel,
      child: Padding(
        padding: kProfileLeadingPadding,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _hover
                  ? [
                      BoxShadow(
                        color: cs.primary.withAlpha(100),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const [],
            ),
            child: Material(
              color: Colors.transparent,
              clipBehavior: Clip.none,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.pop(),
                child: core,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
