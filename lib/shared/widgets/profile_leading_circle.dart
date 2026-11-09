import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const double kProfileLeadingCircleSize = 36;

const EdgeInsets kProfileLeadingPadding =
    EdgeInsets.only(left: 18, top: 6, bottom: 6, right: 16);

const double kProfileLeadingTrailingSlotExtra = 12;

double get kProfileLeadingWidth =>
    kProfileLeadingPadding.left +
    kProfileLeadingCircleSize +
    kProfileLeadingPadding.right +
    kProfileLeadingTrailingSlotExtra;

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
              size: 22,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );

    return Tooltip(
      message: l10n.closeButtonLabel,
      child: SizedBox(
        width: kProfileLeadingWidth,
        child: Align(
          alignment: Alignment.centerLeft,
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
                child: Theme(
                  data: Theme.of(context).copyWith(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: SizedBox(
                    width: kProfileLeadingCircleSize,
                    height: kProfileLeadingCircleSize,
                    child: Material(
                      type: MaterialType.transparency,
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
            ),
          ),
        ),
      ),
    );
  }
}
