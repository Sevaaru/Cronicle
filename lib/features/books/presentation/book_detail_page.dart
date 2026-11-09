import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/books/domain/book_progress_calculator.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/library_insert_animation.dart';
import 'package:cronicle/shared/widgets/m3_detail.dart';

class BookDetailPage extends ConsumerWidget {
  const BookDetailPage({super.key, required this.workKey});

  final String workKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(bookWorkProvider(workKey));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: detailAsync.when(
        loading: () => const _BookDetailLoadingView(),
        error: (e, _) => Center(
          child: Text(l10n.bookDetailNoData,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
        data: (book) => _DetailContent(book: book, workKey: workKey),
      ),
    );
  }
}


class _BookDetailLoadingView extends StatelessWidget {
  const _BookDetailLoadingView();

  static const _bannerH = 170.0;
  static const _posterH = 130.0;
  static const _posterW = 90.0;
  static const _overlap = 50.0;
  static const _headerExtra = 10.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget line(double h, {double? w}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(
                height: _bannerH + _posterH - _overlap + _headerExtra,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: _bannerH,
                      width: double.infinity,
                      color: cs.surfaceContainerHighest,
                    ),
                    SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black26,
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: _bannerH - _overlap,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: _posterW,
                            height: _posterH,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: cs.surface, width: 3),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                line(24),
                                const SizedBox(height: 8),
                                line(14, w: 160),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        line(26, w: 56),
                        const SizedBox(width: 8),
                        line(26, w: 80),
                      ],
                    ),
                    const SizedBox(height: 14),
                    line(110),
                    const SizedBox(height: 10),
                    line(14),
                    const SizedBox(height: 6),
                    line(14),
                    const SizedBox(height: 6),
                    line(14, w: 200),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.book, required this.workKey});

  final Map<String, dynamic> book;
  final String workKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = book['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ?? '';
    final subtitle = book['subtitle'] as String?;
    final coverImage = book['coverImage'] as Map<String, dynamic>? ?? {};
    final poster = (coverImage['extraLarge'] as String?) ??
        (coverImage['large'] as String?);
    final score = book['averageScore'] as int?;
    final rawRating = (book['rawRating'] as num?)?.toDouble();
    final ratingsCount = book['ratingsCount'] as int?;
    final genres = (book['genres'] as List?)?.cast<String>() ?? [];
    final authors = (book['authors'] as List?)?.cast<String>() ?? [];
    final description = book['description'] as String?;
    final editionCount = book['editionCount'] as int?;
    final pages = (book['pages'] as num?)?.toInt();
    final firstPublishDate = book['firstPublishDate'] as String? ??
        book['publishDate'] as String?;
    final publisher = book['publisher'] as String?;
    final language = book['language'] as String?;
    final printType = book['printType'] as String?;
    final maturityRating = book['maturityRating'] as String?;
    final isbn10 = book['isbn10'] as String?;
    final isbn13 = book['isbn13'] as String?;
    final isEbook = book['isEbook'] as bool? ?? false;
    final saleability = book['saleability'] as String?;
    final buyLink = book['buyLink'] as String?;
    final priceAmount = (book['priceAmount'] as num?)?.toDouble();
    final priceCurrency = book['priceCurrency'] as String?;
    final viewability = book['viewability'] as String?;
    final publicDomain = book['publicDomain'] as bool? ?? false;
    final epubAvailable = book['epubAvailable'] as bool? ?? false;
    final pdfAvailable = book['pdfAvailable'] as bool? ?? false;
    final webReaderLink = book['webReaderLink'] as String?;
    final previewLink = book['previewLink'] as String?;
    final infoLink = book['infoLink'] as String?;

    const bannerHeight = 170.0;
    const posterHeight = 130.0;
    const posterWidth = 90.0;
    const overlapAmount = 50.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness:
            (poster != null || isDark) ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            (poster != null || isDark) ? Brightness.dark : Brightness.light,
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                M3DetailHero(
                  title: name,
                  subtitleLines: [
                    if (authors.isNotEmpty) authors.join(', '),
                    if (subtitle != null && subtitle.isNotEmpty) subtitle,
                  ],
                  banner: poster,
                  poster: poster,
                  bannerHeight: bannerHeight,
                  posterHeight: posterHeight,
                  posterWidth: posterWidth,
                  overlap: overlapAmount,
                  pills: [
                    M3HeroPill(_prettyPrintType(printType),
                        bg: cs.tertiaryContainer,
                        fg: cs.onTertiaryContainer),
                    if (isEbook)
                      M3HeroPill('eBook',
                          bg: cs.primaryContainer,
                          fg: cs.onPrimaryContainer),
                    if (publicDomain)
                      M3HeroPill('Public domain',
                          bg: Colors.green.shade100,
                          fg: Colors.green.shade900),
                    if (maturityRating == 'MATURE')
                      M3HeroPill('Mature',
                          bg: Colors.red.shade100,
                          fg: Colors.red.shade900),
                    if (language != null && language.isNotEmpty)
                      M3HeroPill(language.toUpperCase(),
                          bg: cs.secondaryContainer,
                          fg: cs.onSecondaryContainer),
                  ],
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BookFavoriteButton(book: book),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AddToLibraryButton(
                            book: book, workKey: workKey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _BookProgressCard(workKey: workKey),

                  if (score != null ||
                      ratingsCount != null ||
                      (pages != null && pages > 0) ||
                      book['year'] != null)
                    M3SurfaceCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (score != null)
                                _StatColumn(Icons.star,
                                    Colors.amber.shade600, '$score%',
                                    l10n.statMeanScore),
                              if (ratingsCount != null && ratingsCount > 0)
                                _StatColumn(Icons.people, Colors.teal,
                                    _formatNumber(ratingsCount),
                                    l10n.statPopularity),
                              if (pages != null && pages > 0)
                                _StatColumn(
                                    Icons.menu_book_rounded,
                                    Colors.indigoAccent,
                                    '$pages',
                                    l10n.bookDetailPages(pages)),
                              if (book['year'] != null)
                                _StatColumn(
                                    Icons.calendar_today_rounded,
                                    Colors.deepOrangeAccent,
                                    '${book['year']}',
                                    l10n.bookDetailPublishDate),
                            ],
                          ),
                          if (rawRating != null) ...[
                            const SizedBox(height: 10),
                            _StarRow(rating: rawRating),
                          ],
                        ],
                      ),
                    ),

                  if (previewLink != null ||
                      webReaderLink != null ||
                      buyLink != null ||
                      infoLink != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (previewLink != null)
                            _ActionChip(
                              icon: Icons.preview_rounded,
                              label: l10n.bookActionPreview,
                              color: cs.primary,
                              onTap: () => _open(previewLink),
                            ),
                          if (webReaderLink != null && webReaderLink != previewLink)
                            _ActionChip(
                              icon: Icons.menu_book_rounded,
                              label: l10n.bookActionReadOnline,
                              color: Colors.deepPurple,
                              onTap: () => _open(webReaderLink),
                            ),
                          if (buyLink != null)
                            _ActionChip(
                              icon: Icons.shopping_cart_rounded,
                              label: priceAmount != null
                                  ? '${l10n.bookActionBuy} · ${priceAmount.toStringAsFixed(2)} ${priceCurrency ?? ''}'.trim()
                                  : l10n.bookActionBuy,
                              color: Colors.green.shade700,
                              onTap: () => _open(buyLink),
                            ),
                          _ActionChip(
                            icon: Icons.reviews_rounded,
                            label: l10n.bookActionReviews,
                            color: Colors.orange.shade700,
                            onTap: () => _open(
                                'https://books.google.com/books?id=$workKey&dq=reviews'),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: M3SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          M3SectionHeader(label: l10n.mediaInfo),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 24,
                            runSpacing: 6,
                            children: [
                              if (pages != null && pages > 0)
                                _InfoPill(l10n.bookDetailPages(pages), '$pages'),
                              if (editionCount != null && editionCount > 0)
                                _InfoPill(l10n.bookDetailEditions, '$editionCount'),
                              if (firstPublishDate != null)
                                _InfoPill(l10n.bookDetailPublishDate, firstPublishDate),
                              if (publisher != null && publisher.isNotEmpty)
                                _InfoPill(l10n.bookDetailPublisher, publisher),
                              if (language != null && language.isNotEmpty)
                                _InfoPill(l10n.bookDetailLanguage,
                                    language.toUpperCase()),
                              if (printType != null && printType.isNotEmpty)
                                _InfoPill(l10n.bookDetailPrintType,
                                    _prettyPrintType(printType)),
                              if (maturityRating != null && maturityRating.isNotEmpty)
                                _InfoPill(l10n.bookDetailMaturity,
                                    _prettyMaturity(maturityRating)),
                              if (viewability != null && viewability != 'NO_PAGES')
                                _InfoPill(l10n.bookDetailPreview,
                                    _prettyViewability(viewability)),
                              if (epubAvailable || pdfAvailable)
                                _InfoPill(
                                    l10n.bookDetailFormats,
                                    [
                                      if (epubAvailable) 'EPUB',
                                      if (pdfAvailable) 'PDF',
                                    ].join(' · ')),
                              if (saleability != null &&
                                  saleability != 'NOT_FOR_SALE')
                                _InfoPill(l10n.bookDetailAvailability,
                                    _prettySaleability(saleability)),
                              if (authors.isNotEmpty)
                                _InfoPill(l10n.bookDetailAuthors, authors.join(', ')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isbn10 != null || isbn13 != null)
                    SizedBox(
                      width: double.infinity,
                      child: M3SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            M3SectionHeader(label: l10n.bookDetailIdentifiers),
                            const SizedBox(height: 10),
                            if (isbn13 != null)
                              _CopyableRow(label: 'ISBN-13', value: isbn13),
                            if (isbn10 != null)
                              _CopyableRow(label: 'ISBN-10', value: isbn10),
                          ],
                        ),
                      ),
                    ),

                  if (genres.isNotEmpty) ...[
                    M3SectionHeader(label: l10n.bookDetailSubjects),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: genres
                          .map((g) => M3PillChip(
                                label: g,
                                bg: cs.surfaceContainerHigh,
                                fg: cs.onSurface,
                                onTap: () => context.push(
                                  '/books/subject?subject=${Uri.encodeQueryComponent(g.toLowerCase())}&sort=popularity',
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (description != null && description.isNotEmpty) ...[
                    M3SectionHeader(label: l10n.bookDetailDescription),
                    const SizedBox(height: 10),
                    M3SurfaceCard(
                      child: Text(
                        description,
                        style: TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                            color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(l10n.bookDetailOpenOnGoogleBooks),
                      onPressed: () => launchUrl(
                        Uri.parse(
                            'https://books.google.com/books?id=$workKey'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _prettyPrintType(String? value) {
    switch (value) {
      case 'BOOK':
        return 'Book';
      case 'MAGAZINE':
        return 'Magazine';
      default:
        return 'Book';
    }
  }

  static String _prettyMaturity(String value) {
    switch (value) {
      case 'NOT_MATURE':
        return 'All ages';
      case 'MATURE':
        return 'Mature';
      default:
        return value;
    }
  }

  static String _prettyViewability(String value) {
    switch (value) {
      case 'PARTIAL':
        return 'Partial';
      case 'ALL_PAGES':
        return 'Full preview';
      case 'NO_PAGES':
        return 'No preview';
      default:
        return value;
    }
  }

  static String _prettySaleability(String value) {
    switch (value) {
      case 'FOR_SALE':
        return 'For sale';
      case 'FREE':
        return 'Free';
      case 'FOR_PREORDER':
        return 'Pre-order';
      case 'FOR_SALE_AND_RENTAL':
        return 'Sale / Rent';
      default:
        return value;
    }
  }
}


class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final stars = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      final IconData icon;
      if (rating >= i) {
        icon = Icons.star_rounded;
      } else if (rating >= i - 0.5) {
        icon = Icons.star_half_rounded;
      } else {
        icon = Icons.star_outline_rounded;
      }
      stars.add(Icon(icon, color: Colors.amber.shade600, size: 18));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...stars,
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}


class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}


class _CopyableRow extends StatelessWidget {
  const _CopyableRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('$label copied'),
                      duration: const Duration(seconds: 1)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}


class _StatColumn extends StatelessWidget {
  const _StatColumn(this.icon, this.color, this.value, this.label);
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        Text(value,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}


class _BookProgressCard extends ConsumerWidget {
  const _BookProgressCard({required this.workKey});
  final String workKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final entries = ref.watch(libraryByKindProvider(MediaKind.book));

    return entries.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        final entry = list.cast<LibraryEntry?>().firstWhere(
          (e) => e!.externalId == workKey,
          orElse: () => null,
        );
        if (entry == null) return const SizedBox.shrink();

        final pct = BookProgressCalculator.calculateProgressPercentage(entry);
        final progressText = BookProgressCalculator.getProgressText(entry, l10n);
        final remainingText = BookProgressCalculator.getRemainingText(entry, l10n);
        final mode = BookProgressCalculator.getTrackingMode(entry);
        final modeLabel = switch (mode) {
          BookTrackingMode.pages => l10n.bookTrackingModePages,
          BookTrackingMode.percentage => l10n.bookTrackingModePercent,
          BookTrackingMode.chapters => l10n.bookTrackingModeChapters,
        };

        return M3SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(l10n.bookReadingProgress,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(modeLabel,
                        style: TextStyle(
                            fontSize: 10, color: cs.onSecondaryContainer)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (progressText.isNotEmpty)
                    Expanded(
                      child: Text(progressText,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ),
                  Text('${pct.round()}%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.primary)),
                ],
              ),
              if (remainingText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(remainingText,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.primary.withAlpha(180))),
                ),
            ],
          ),
        );
      },
    );
  }
}


class _BookFavoriteButton extends ConsumerWidget {
  const _BookFavoriteButton({required this.book});
  final Map<String, dynamic> book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workKey = book['workKey'] as String? ?? '';
    final list = ref.watch(favoriteBooksProvider);
    final isFav =
        workKey.isNotEmpty && list.any((e) => e['workKey'] == workKey);

    return M3FavoriteIconButton(
      isFavorite: isFav,
      tooltip: isFav ? l10n.tooltipRemoveFavorite : l10n.tooltipAddFavorite,
      onPressed: workKey.isEmpty
          ? null
          : () => ref
              .read(favoriteBooksProvider.notifier)
              .toggleFavorite(book),
    );
  }
}


class _AddToLibraryButton extends ConsumerStatefulWidget {
  const _AddToLibraryButton({required this.book, required this.workKey});
  final Map<String, dynamic> book;
  final String workKey;

  @override
  ConsumerState<_AddToLibraryButton> createState() =>
      _AddToLibraryButtonState();
}

class _AddToLibraryButtonState extends ConsumerState<_AddToLibraryButton> {
  LibraryEntry? _existing;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final db = ref.read(databaseProvider);
    final entry = await db.getLibraryEntryByKindAndExternalId(
      MediaKind.book.code,
      widget.workKey,
    );
    if (mounted) {
      setState(() {
        _existing = entry;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(libraryByKindProvider(MediaKind.book), (_, _) {
      _checkExisting();
    });

    final l10n = AppLocalizations.of(context)!;
    final isEdit = _existing != null;

    return _loaded
        ? SizedBox(
            width: double.infinity,
            child: M3AddToLibraryButton(
              isEdit: isEdit,
              label: isEdit ? l10n.editLibraryEntry : l10n.addToLibrary,
              onPressed: () async {
                final saved = await showAddToLibrarySheet(
                  context: context,
                  ref: ref,
                  item: widget.book,
                  kind: MediaKind.book,
                  existingEntry: _existing,
                );
                if (!context.mounted || !saved) return;
                if (!isEdit) {
                  final cover = widget.book['coverImage'] as Map<String, dynamic>? ?? const {};
                  final coverUrl = (cover['extraLarge'] as String?) ??
                      (cover['large'] as String?);
                  playLibraryInsertAnimation(
                    sourceContext: context,
                    imageUrl: coverUrl,
                  );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(isEdit
                          ? l10n.entryUpdated
                          : l10n.addedToLibrary)),
                );
                _checkExisting();
              },
            ),
          )
        : const SizedBox.shrink();
  }
}
