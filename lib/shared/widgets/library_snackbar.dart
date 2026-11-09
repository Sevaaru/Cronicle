import 'package:flutter/material.dart';

import 'package:cronicle/l10n/app_localizations.dart';

/// Shows a Material 3 styled snackbar after the user added or edited a
/// library entry. Pass [wasEdit] = true when the entry already existed before
/// the action so the message reflects "Entry updated" rather than
/// "Added to library".
void showLibrarySnackbar(
  BuildContext context, {
  required bool wasEdit,
}) {
  final l10n = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);

  final icon = wasEdit
      ? Icons.edit_rounded
      : Icons.bookmark_added_rounded;
  final text = wasEdit ? l10n.entryUpdated : l10n.addedToLibrary;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        elevation: 6,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Row(
          children: [
            Icon(icon, color: cs.onInverseSurface, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: cs.onInverseSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
