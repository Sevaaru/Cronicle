import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/library_insert_animation.dart';
import 'package:cronicle/shared/widgets/library_snackbar.dart';

/// Floating Material 3 styled "+" / edit badge that overlays a media cover.
///
/// Self contained: it reads the user's library to figure out whether the
/// item already exists, opens the add-to-library bottom sheet on tap, plays
/// the insertion animation and shows the M3 snackbar afterwards.
///
/// Drop it inside a `Stack` next to the cover image and place it with a
/// `Positioned` widget (typically top-right or bottom-right corner).
class LibraryAddBadge extends ConsumerWidget {
  const LibraryAddBadge({
    super.key,
    required this.item,
    required this.kind,
    this.size = 32,
  });

  /// Raw item map. Must contain at least an `id` (or `workKey` for books)
  /// and ideally a poster URL for the insertion animation.
  final Map<String, dynamic> item;
  final MediaKind kind;

  /// Diameter of the circular button. Defaults to 32 which fits compact
  /// poster carousels. For larger hero cards bump to 36-40.
  final double size;

  String get _externalId {
    if (kind == MediaKind.book) {
      return (item['workKey'] as String?) ?? item['id'].toString();
    }
    return item['id'].toString();
  }

  String? get _posterUrl {
    final cover = item['coverImage'] as Map<String, dynamic>?;
    return (cover?['extraLarge'] as String?) ??
        (cover?['large'] as String?) ??
        (cover?['medium'] as String?) ??
        (item['poster'] as String?) ??
        (item['cover'] as String?) ??
        (item['image'] as String?);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final entriesAsync = ref.watch(libraryByKindProvider(kind));
    final externalId = _externalId;
    final inLibrary = entriesAsync.maybeWhen(
      data: (entries) => entries.any((e) => e.externalId == externalId),
      orElse: () => false,
    );

    final iconColor = inLibrary ? cs.onTertiary : cs.onPrimary;
    final bg = inLibrary ? cs.tertiary : cs.primary;
    final iconData =
        inLibrary ? Icons.edit_rounded : Icons.add_rounded;
    // Squircle / M3 neomorphism: rounded square with dual soft shadows.
    final radius = BorderRadius.circular(size * 0.34);
    final shape = RoundedRectangleBorder(borderRadius: radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          // Dark drop shadow (bottom-right)
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          // Soft highlight (top-left) for neomorphic feel
          BoxShadow(
            color: Colors.white.withAlpha(28),
            blurRadius: 6,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Material(
        color: bg,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Tooltip(
          message: inLibrary ? l10n.editLibraryEntry : l10n.addToLibrary,
          child: InkWell(
            onTap: () => _onTap(context, ref, inLibrary),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                iconData,
                size: size * 0.6,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context, WidgetRef ref, bool inLibrary,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final db = ref.read(databaseProvider);
    final existing = await db.getLibraryEntryByKindAndExternalId(
      kind.code, _externalId,
    );
    if (!context.mounted) return;
    final wasEdit = existing != null;
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: kind,
      existingEntry: existing,
    );
    if (!context.mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!added) return;
    if (!wasEdit) {
      playLibraryInsertAnimation(
        sourceContext: context,
        imageUrl: _posterUrl,
      );
    }
    showLibrarySnackbar(context, wasEdit: wasEdit);
  }
}
