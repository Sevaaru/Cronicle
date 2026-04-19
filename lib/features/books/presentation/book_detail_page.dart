import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

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

// ---------------------------------------------------------------------------
// Carga: layout similar al detalle (placeholders grises, sin spinner aislado)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Main content — mirrors the anime / manga detail layout
// ---------------------------------------------------------------------------

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
    final coverImage = book['coverImage'] as Map<String, dynamic>? ?? {};
    final poster = (coverImage['extraLarge'] as String?) ??
        (coverImage['large'] as String?);
    final score = book['averageScore'] as int?;
    final ratingsCount = book['ratingsCount'] as int?;
    final genres = (book['genres'] as List?)?.cast<String>() ?? [];
    final authors = (book['authors'] as List?)?.cast<String>() ?? [];
    final description = book['description'] as String?;
    final editionCount = book['editionCount'] as int?;
    final pages = (book['pages'] as num?)?.toInt();
    final firstPublishDate = book['firstPublishDate'] as String?;

    const bannerHeight = 170.0;
    const posterHeight = 130.0;
    const posterWidth = 90.0;
    const overlapAmount = 50.0;
    const headerOverflowAllowance = 10.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness:
            (poster != null || isDark) ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            (poster != null || isDark) ? Brightness.dark : Brightness.light,
      ),
      child: CustomScrollView(
        slivers: [
          // ── Banner + poster + title ──────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(
                  height: bannerHeight +
                      posterHeight -
                      overlapAmount +
                      headerOverflowAllowance,
                  child: Stack(
                    children: [
                      // Banner (reuses poster as blurred background)
                      GestureDetector(
                        onTap: poster != null
                            ? () => showFullscreenImage(context, poster)
                            : null,
                        child: Container(
                          height: bannerHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: poster != null
                                ? DecorationImage(
                                    image:
                                        CachedNetworkImageProvider(poster),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                        Colors.black.withAlpha(60),
                                        BlendMode.darken),
                                  )
                                : null,
                            color: poster == null
                                ? cs.surfaceContainerHighest
                                : null,
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  style: IconButton.styleFrom(
                                      backgroundColor: Colors.black26),
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Poster + title
                      Positioned(
                        left: 16,
                        right: 16,
                        top: bannerHeight - overlapAmount,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (poster != null)
                              GestureDetector(
                                onTap: () =>
                                    showFullscreenImage(context, poster),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: cs.surface, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(60),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: CachedNetworkImage(
                                      imageUrl: poster,
                                      width: posterWidth,
                                      height: posterHeight,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: cs.surface.withAlpha(210),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (authors.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, top: 2),
                                        child: Text(
                                          authors.join(', '),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  cs.onSurfaceVariant),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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

                const SizedBox(height: 12),

                // Format tag
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Tag('Book', cs.tertiaryContainer,
                          cs.onTertiaryContainer),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Favorite toggle + Add-to-library row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

                  // Reading progress card (only shown when entry exists)
                  _BookProgressCard(workKey: workKey),

                  // Stats card
                  if (score != null || ratingsCount != null)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (score != null)
                            _StatColumn(Icons.star,
                                Colors.amber.shade600, '$score%',
                                l10n.statMeanScore),
                          if (ratingsCount != null)
                            _StatColumn(Icons.people, Colors.teal,
                                _formatNumber(ratingsCount),
                                l10n.statPopularity),
                        ],
                      ),
                    ),

                  // Info card
                  SizedBox(
                    width: double.infinity,
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.mediaInfo,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          const SizedBox(height: 8),
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
                              if (authors.isNotEmpty)
                                _InfoPill(l10n.bookDetailAuthors, authors.join(', ')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Subjects / genres
                  if (genres.isNotEmpty) ...[
                    Text(
                      l10n.bookDetailSubjects,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: genres
                          .take(12)
                          .map((g) => ActionChip(
                                label: Text(g,
                                    style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                onPressed: () => context.push(
                                  '/books/subject?subject=${Uri.encodeQueryComponent(g.toLowerCase())}&sort=popularity',
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Description
                  if (description != null && description.isNotEmpty) ...[
                    Text(l10n.bookDetailDescription,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        description,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Open in OpenLibrary link
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(l10n.bookDetailOpenOnOpenLibrary),
                      onPressed: () => launchUrl(
                        Uri.parse(
                            'https://openlibrary.org/works/$workKey'),
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
}

// ---------------------------------------------------------------------------
// Reusable small widgets (same style as anime / manga detail)
// ---------------------------------------------------------------------------

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
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

// ---------------------------------------------------------------------------
// Reading progress card (shown when entry exists in library)
// ---------------------------------------------------------------------------

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

        return GlassCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
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

// ---------------------------------------------------------------------------
// Favorite toggle (local SharedPreferences — same pattern as games)
// ---------------------------------------------------------------------------

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

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Tooltip(
        message:
            isFav ? l10n.tooltipRemoveFavorite : l10n.tooltipAddFavorite,
        child: IconButton.filledTonal(
          style: IconButton.styleFrom(
            fixedSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: workKey.isEmpty
              ? null
              : () => ref
                  .read(favoriteBooksProvider.notifier)
                  .toggleFavorite(book),
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? Colors.redAccent : null,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-to-library button (reactive, matches anime detail)
// ---------------------------------------------------------------------------

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _loaded
          ? FilledButton.icon(
              icon: Icon(isEdit ? Icons.edit : Icons.add),
              label:
                  Text(isEdit ? l10n.editLibraryEntry : l10n.addToLibrary),
              onPressed: () async {
                final saved = await showAddToLibrarySheet(
                  context: context,
                  ref: ref,
                  item: widget.book,
                  kind: MediaKind.book,
                  existingEntry: _existing,
                );
                if (!context.mounted || !saved) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(isEdit
                          ? l10n.entryUpdated
                          : l10n.addedToLibrary)),
                );
                _checkExisting();
              },
            )
          : const SizedBox.shrink(),
    );
  }
}
