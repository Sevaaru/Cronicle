import 'package:flutter/material.dart';

import 'package:cronicle/shared/widgets/anilist_markdown.dart';

/// A collapsible "Bio" tile used on profile pages.
///
/// Header is always visible (icon + label + chevron). Tapping the header
/// expands/collapses the markdown body with a top→bottom vertical animation
/// (no diagonal grow). State is managed internally.
class CollapsibleBioTile extends StatefulWidget {
  const CollapsibleBioTile({
    super.key,
    required this.about,
    this.label = 'Bio',
    this.initiallyExpanded = false,
  });

  final String about;
  final String label;
  final bool initiallyExpanded;

  @override
  State<CollapsibleBioTile> createState() => _CollapsibleBioTileState();
}

class _CollapsibleBioTileState extends State<CollapsibleBioTile> {
  late bool _expanded = widget.initiallyExpanded;

  static const double _radius = 22;
  static const Duration _kDuration = Duration(milliseconds: 250);
  static const Curve _kCurve = Curves.easeInOut;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(_radius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(_radius),
              bottom: _expanded ? Radius.zero : const Radius.circular(_radius),
            ),
            onTap: _toggle,
            splashColor: cs.primary.withValues(alpha: 0.14),
            highlightColor: cs.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: cs.onSecondaryContainer,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: _kDuration,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Vertical-only reveal: ClipRect + AnimatedAlign(heightFactor)
          // animates only the height (top→bottom), never the width.
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: _expanded ? 1.0 : 0.0,
              duration: _kDuration,
              curve: _kCurve,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: AnilistMarkdown(
                    widget.about,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
