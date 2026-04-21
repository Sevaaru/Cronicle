import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/l10n/app_localizations.dart';

/// Tracking modes for book progress.
enum BookTrackingMode {
  pages,
  percentage,
  chapters;

  static BookTrackingMode fromString(String? value) => switch (value) {
        'percentage' => BookTrackingMode.percentage,
        'chapters' => BookTrackingMode.chapters,
        _ => BookTrackingMode.pages,
      };
}

/// Pure-function utilities for book reading-progress calculations.
///
/// Priority for totals: user override → API value → null (user enters manually).
class BookProgressCalculator {
  const BookProgressCalculator._();

  // ---------------------------------------------------------------------------
  // Effective totals
  // ---------------------------------------------------------------------------

  /// Returns the effective total pages for this entry.
  /// Priority: userTotalPagesOverride → totalPagesFromApi → totalEpisodes (legacy) → null.
  static int? getEffectiveTotalPages(LibraryEntry entry) {
    return entry.userTotalPagesOverride ??
        entry.totalPagesFromApi ??
        entry.totalEpisodes;
  }

  /// Returns the effective total chapters for this entry.
  /// Priority: userTotalChaptersOverride → totalChaptersFromApi → null.
  static int? getEffectiveTotalChapters(LibraryEntry entry) {
    return entry.userTotalChaptersOverride ?? entry.totalChaptersFromApi;
  }

  /// Resolved tracking mode.
  static BookTrackingMode getTrackingMode(LibraryEntry entry) {
    return BookTrackingMode.fromString(entry.bookTrackingMode);
  }

  // ---------------------------------------------------------------------------
  // Progress percentage (always 0–100)
  // ---------------------------------------------------------------------------

  /// Calculate completion percentage based on the current tracking mode.
  static double calculateProgressPercentage(LibraryEntry entry) {
    final mode = getTrackingMode(entry);
    switch (mode) {
      case BookTrackingMode.pages:
        final total = getEffectiveTotalPages(entry);
        final current = entry.progress ?? 0;
        if (total == null || total == 0) return 0;
        return (current / total * 100).clamp(0, 100);

      case BookTrackingMode.percentage:
        // `progress` stores the raw percentage (0–100).
        return (entry.progress ?? 0).toDouble().clamp(0, 100);

      case BookTrackingMode.chapters:
        final total = getEffectiveTotalChapters(entry);
        final current = entry.currentChapter ?? 0;
        if (total == null || total == 0) return 0;
        return (current / total * 100).clamp(0, 100);
    }
  }

  // ---------------------------------------------------------------------------
  // Friendly text helpers
  // ---------------------------------------------------------------------------

  /// Human-readable progress string, e.g. "Page 120 of 350 (34%)".
  static String getProgressText(LibraryEntry entry, AppLocalizations l10n) {
    final mode = getTrackingMode(entry);
    final pct = calculateProgressPercentage(entry).round();

    switch (mode) {
      case BookTrackingMode.pages:
        final total = getEffectiveTotalPages(entry);
        final current = entry.progress ?? 0;
        if (total != null && total > 0) {
          return l10n.bookProgressPageOf(current, total, pct);
        }
        return current > 0 ? l10n.bookProgressPageSimple(current) : '';

      case BookTrackingMode.percentage:
        return '$pct%';

      case BookTrackingMode.chapters:
        final total = getEffectiveTotalChapters(entry);
        final current = entry.currentChapter ?? 0;
        if (total != null && total > 0) {
          return l10n.bookProgressChapterOf(current, total, pct);
        }
        return current > 0 ? l10n.bookProgressChapterSimple(current) : '';
    }
  }

  /// "X pages left" / "X chapters left" depending on mode.
  static String? getRemainingText(LibraryEntry entry, AppLocalizations l10n) {
    final mode = getTrackingMode(entry);

    switch (mode) {
      case BookTrackingMode.pages:
        final total = getEffectiveTotalPages(entry);
        final current = entry.progress ?? 0;
        if (total == null || total <= current) return null;
        return l10n.libraryPagesRemaining(total - current);

      case BookTrackingMode.percentage:
        final remaining = 100 - (entry.progress ?? 0);
        if (remaining <= 0) return null;
        return l10n.bookPercentRemaining(remaining);

      case BookTrackingMode.chapters:
        final total = getEffectiveTotalChapters(entry);
        final current = entry.currentChapter ?? 0;
        if (total == null || total <= current) return null;
        return l10n.libraryChaptersRemaining(total - current);
    }
  }

  /// Short label for library list cards, e.g. "120/350" or "34%".
  static String getShortProgressLabel(LibraryEntry entry, AppLocalizations l10n) {
    final mode = getTrackingMode(entry);

    switch (mode) {
      case BookTrackingMode.pages:
        final total = getEffectiveTotalPages(entry);
        final current = entry.progress ?? 0;
        if (total != null) return '$current/$total';
        return '$current';

      case BookTrackingMode.percentage:
        return '${entry.progress ?? 0}%';

      case BookTrackingMode.chapters:
        final total = getEffectiveTotalChapters(entry);
        final current = entry.currentChapter ?? 0;
        if (total != null) {
          return l10n.bookLibraryProgressChaptersShort(current, total);
        }
        return l10n.bookLibraryProgressChapterOnly(current);
    }
  }

  /// The effective "max" value for the increment button cap.
  static int? getIncrementCap(LibraryEntry entry) {
    final mode = getTrackingMode(entry);
    return switch (mode) {
      BookTrackingMode.pages => getEffectiveTotalPages(entry),
      BookTrackingMode.percentage => 100,
      BookTrackingMode.chapters => getEffectiveTotalChapters(entry),
    };
  }
}
