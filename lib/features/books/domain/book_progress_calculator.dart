import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/l10n/app_localizations.dart';

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

class BookProgressCalculator {
  const BookProgressCalculator._();


  static int? getEffectiveTotalPages(LibraryEntry entry) {
    return entry.userTotalPagesOverride ??
        entry.totalPagesFromApi ??
        entry.totalEpisodes;
  }

  static int? getEffectiveTotalChapters(LibraryEntry entry) {
    return entry.userTotalChaptersOverride ?? entry.totalChaptersFromApi;
  }

  static BookTrackingMode getTrackingMode(LibraryEntry entry) {
    return BookTrackingMode.fromString(entry.bookTrackingMode);
  }


  static double calculateProgressPercentage(LibraryEntry entry) {
    final mode = getTrackingMode(entry);
    switch (mode) {
      case BookTrackingMode.pages:
        final total = getEffectiveTotalPages(entry);
        final current = entry.progress ?? 0;
        if (total == null || total == 0) return 0;
        return (current / total * 100).clamp(0, 100);

      case BookTrackingMode.percentage:
        return (entry.progress ?? 0).toDouble().clamp(0, 100);

      case BookTrackingMode.chapters:
        final total = getEffectiveTotalChapters(entry);
        final current = entry.currentChapter ?? 0;
        if (total == null || total == 0) return 0;
        return (current / total * 100).clamp(0, 100);
    }
  }


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

  static int? getIncrementCap(LibraryEntry entry) {
    final mode = getTrackingMode(entry);
    return switch (mode) {
      BookTrackingMode.pages => getEffectiveTotalPages(entry),
      BookTrackingMode.percentage => 100,
      BookTrackingMode.chapters => getEffectiveTotalChapters(entry),
    };
  }
}
