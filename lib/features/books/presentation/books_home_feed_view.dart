import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

String? _coverUrl(Map<String, dynamic> item) =>
    (item['coverImage'] as Map?)?['large'] as String?;

String _bookTitle(Map<String, dynamic> item) =>
    ((item['title'] as Map?)?['english'] as String?) ?? '';

int? _bookScore(Map<String, dynamic> item) => item['averageScore'] as int?;

Color _scoreColor(int s) {
  if (s >= 80) return const Color(0xFF22C55E);
  if (s >= 60) return const Color(0xFFF59E0B);
  return const Color(0xFF94A3B8);
}

void _navigateToBook(BuildContext context, Map<String, dynamic> item) {
  final workKey = item['workKey'] as String?;
  if (workKey != null) context.push('/book/$workKey');
}

// ─── Book feed slugs ────────────────────────────────────────────────────────

class BookFeedSection {
  BookFeedSection._();
  static const trending = 'trending';
  static const love = 'love';
  static const fantasy = 'fantasy';
  static const scienceFiction = 'science_fiction';
  static const classics = 'classics';
  static const mystery = 'mystery';

  static const all = [trending, love, fantasy, scienceFiction, classics, mystery];
  static bool isValid(String slug) => all.contains(slug);
}

String booksHomeSectionTitle(AppLocalizations l10n, String slug) => switch (slug) {
      BookFeedSection.trending => l10n.booksHomeTrending,
      BookFeedSection.love => l10n.booksHomePopularNow,
      BookFeedSection.fantasy => 'Fantasy',
      BookFeedSection.scienceFiction => 'Sci-Fi',
      BookFeedSection.classics => l10n.booksHomeClassics,
      BookFeedSection.mystery => l10n.booksHomeMystery,
      _ => slug,
    };

/// Full-page home feed for the Books tab (matching games/trakt style).
class BooksHomeFeedView extends ConsumerWidget {
  const BooksHomeFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bookTrendingProvider);
        ref.invalidate(bookSubjectProvider(BookFeedSection.love));
        ref.invalidate(bookSubjectProvider(BookFeedSection.fantasy));
        ref.invalidate(bookSubjectProvider(BookFeedSection.scienceFiction));
        ref.invalidate(bookSubjectProvider(BookFeedSection.classics));
        ref.invalidate(bookSubjectProvider(BookFeedSection.mystery));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // 1. Trending → Score Carousel
          _AsyncSection(
            asyncValue: ref.watch(bookTrendingProvider),
            skeleton: const _ScoreCarouselSkeleton(
              cardWidth: 126,
              cardHeight: 172,
            ),
            builder: (items) => _ScoreCarouselSection(
              title: l10n.booksHomeTrending,
              slug: BookFeedSection.trending,
              items: items,
              cardWidth: 126,
              cardHeight: 172,
              icon: Icons.local_fire_department_rounded,
              accent: Theme.of(context).colorScheme.primary,
            ),
          ),

          // 2. Popular (Love) → Hero
          _AsyncSection(
            asyncValue: ref.watch(bookSubjectProvider(BookFeedSection.love)),
            skeleton: const _HeroSkeleton(),
            builder: (items) => _HeroSection(
              title: l10n.booksHomePopularNow,
              slug: BookFeedSection.love,
              items: items,
              accent: Colors.redAccent,
              icon: Icons.favorite_rounded,
            ),
          ),

          // 3. Fantasy → Mood Band
          _AsyncSection(
            asyncValue: ref.watch(bookSubjectProvider(BookFeedSection.fantasy)),
            skeleton: _MoodBandSkeleton(
              accent: Colors.indigo,
              darkBg: const Color(0xFF0C0A1D),
            ),
            builder: (items) => _MoodBandSection(
              title: 'Fantasy',
              slug: BookFeedSection.fantasy,
              items: items,
              accent: Colors.indigo,
              darkBg: const Color(0xFF0C0A1D),
              icon: Icons.auto_fix_high_rounded,
            ),
          ),

          // 4. Sci-Fi → Score Carousel
          _AsyncSection(
            asyncValue:
                ref.watch(bookSubjectProvider(BookFeedSection.scienceFiction)),
            skeleton: const _ScoreCarouselSkeleton(
              cardWidth: 108,
              cardHeight: 148,
            ),
            builder: (items) => _ScoreCarouselSection(
              title: 'Sci-Fi',
              slug: BookFeedSection.scienceFiction,
              items: items,
              cardWidth: 108,
              cardHeight: 148,
              icon: Icons.rocket_launch_rounded,
              accent: Colors.teal,
            ),
          ),

          // 5. Classics → Spotlight Rows
          _AsyncSection(
            asyncValue:
                ref.watch(bookSubjectProvider(BookFeedSection.classics)),
            skeleton: const _SpotlightRowsSkeleton(),
            builder: (items) => _SpotlightRowsSection(
              title: l10n.booksHomeClassics,
              slug: BookFeedSection.classics,
              items: items,
              accent: Colors.amber.shade700,
              icon: Icons.menu_book_rounded,
            ),
          ),

          // 6. Mystery → Ranked List
          _AsyncSection(
            asyncValue:
                ref.watch(bookSubjectProvider(BookFeedSection.mystery)),
            skeleton: const _RankedListSkeleton(),
            builder: (items) => _RankedListSection(
              title: 'Mystery',
              slug: BookFeedSection.mystery,
              items: items,
              icon: Icons.search_rounded,
              accent: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a skeleton while [asyncValue] is loading, the built widget when it
/// has data, and nothing (`SizedBox.shrink`) on error or empty results.
class _AsyncSection extends StatelessWidget {
  const _AsyncSection({
    required this.asyncValue,
    required this.skeleton,
    required this.builder,
  });

  final AsyncValue<List<Map<String, dynamic>>> asyncValue;
  final Widget skeleton;
  final Widget Function(List<Map<String, dynamic>> items) builder;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      skipLoadingOnRefresh: true,
      loading: () => skeleton,
      error: (_, _) => const SizedBox.shrink(),
      data: (items) =>
          items.isEmpty ? const SizedBox.shrink() : builder(items),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.slug,
    this.accent,
    this.icon,
    this.onDark = false,
  });

  final String title;
  final String slug;
  final Color? accent;
  final IconData? icon;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = accent ?? cs.primary;
    final textColor = onDark ? Colors.white : cs.onSurface;
    final chevronColor = onDark ? Colors.white60 : cs.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/books/section/$slug'),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: chevronColor),
        ],
      ),
    );
  }
}

// ─── Score badge ──────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, this.small = false});
  final int score;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final bg = _scoreColor(score);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Poster placeholder ──────────────────────────────────────────────────────

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({
    required this.width,
    required this.height,
    required this.radius,
  });
  final double width, height, radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Icon(Icons.auto_stories, color: Colors.white24),
    );
  }
}

// ─── Skeleton helper ─────────────────────────────────────────────────────────

Widget _skel(BuildContext ctx,
    {required double w, required double h, double r = 8}) {
  final cs = Theme.of(ctx).colorScheme;
  return Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

// ─── 1. Score Carousel ────────────────────────────────────────────────────────

class _ScoreCarouselSection extends StatelessWidget {
  const _ScoreCarouselSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.cardWidth,
    required this.cardHeight,
    this.icon,
    this.accent,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final double cardWidth;
  final double cardHeight;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(10).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SectionHeader(
              title: title,
              slug: slug,
              icon: icon,
              accent: accent,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: cardHeight + 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slice.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _ScoreCarouselCard(
                item: slice[i],
                width: cardWidth,
                height: cardHeight,
                accent: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCarouselCard extends StatelessWidget {
  const _ScoreCarouselCard({
    required this.item,
    required this.width,
    required this.height,
    this.accent,
  });

  final Map<String, dynamic> item;
  final double width;
  final double height;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _bookTitle(item);
    final score = _bookScore(item);

    return GestureDetector(
      onTap: () => _navigateToBook(context, item),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: url != null
                      ? CachedNetworkImage(
                          imageUrl: url,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                        )
                      : _PosterPlaceholder(
                          width: width, height: height, radius: 10),
                ),
                if (score != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ScoreBadge(score: score, small: true),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Icon(Icons.auto_stories,
                    size: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(width: 3),
                Text(
                  'Book',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 2. Hero Section ─────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hero = items.first;
    final rest = items.skip(1).take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, slug: slug, icon: icon, accent: accent),
          const SizedBox(height: 12),
          _HeroCard(item: hero, accent: accent),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rest.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final it = rest[i];
                  final url = _coverUrl(it);
                  final score = _bookScore(it);
                  return GestureDetector(
                    onTap: () => _navigateToBook(ctx, it),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: url != null
                              ? CachedNetworkImage(
                                  imageUrl: url,
                                  width: 70,
                                  height: 96,
                                  fit: BoxFit.cover,
                                )
                              : _PosterPlaceholder(
                                  width: 70, height: 96, radius: 8),
                        ),
                        if (score != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: _ScoreBadge(score: score, small: true),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item, required this.accent});

  final Map<String, dynamic> item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _bookTitle(item);
    final score = _bookScore(item);
    final authors = (item['authors'] as List?)?.cast<String>() ?? [];
    final genresList = (item['genres'] as List?)?.cast<String>();
    final genres = genresList != null && genresList.isNotEmpty
        ? genresList.take(2).join(' · ')
        : '';
    final year = item['year'] as int?;

    return GestureDetector(
      onTap: () => _navigateToBook(context, item),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 88,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : _PosterPlaceholder(width: 88, height: 120, radius: 0),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (score != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Icon(Icons.star_rounded, size: 15, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              height: 1,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 5),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (authors.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        authors.first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ] else if (genres.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        genres,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (year != null)
                      Text(
                        '$year',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 3. Mood Band ────────────────────────────────────────────────────────────

class _MoodBandSection extends StatelessWidget {
  const _MoodBandSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.accent,
    required this.darkBg,
    required this.icon,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final Color accent;
  final Color darkBg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: _SectionHeader(
                title: title,
                slug: slug,
                icon: icon,
                accent: accent,
                onDark: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: slice.length,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final it = slice[i];
                  final url = _coverUrl(it);
                  return GestureDetector(
                    onTap: () => _navigateToBook(ctx, it),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url != null
                          ? CachedNetworkImage(
                              imageUrl: url,
                              width: 108,
                              height: 148,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 108,
                              height: 148,
                              color: accent.withValues(alpha: 0.15),
                              child: const Icon(
                                Icons.auto_stories,
                                color: Colors.white24,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// ─── 4. Spotlight Rows ───────────────────────────────────────────────────────

class _SpotlightRowsSection extends StatelessWidget {
  const _SpotlightRowsSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, slug: slug, icon: icon, accent: accent),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: accent.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(slice.length, (i) {
                final isLast = i == slice.length - 1;
                return Column(
                  children: [
                    _SpotlightRow(item: slice[i], accent: accent),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: accent.withValues(alpha: 0.15),
                        indent: 72,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightRow extends StatelessWidget {
  const _SpotlightRow({required this.item, required this.accent});

  final Map<String, dynamic> item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _bookTitle(item);
    final score = _bookScore(item);
    final authors = (item['authors'] as List?)?.cast<String>();
    final subtitle = authors != null && authors.isNotEmpty ? authors.first : null;

    return GestureDetector(
      onTap: () => _navigateToBook(context, item),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : _PosterPlaceholder(width: 48, height: 64, radius: 7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (score != null) ...[
              const SizedBox(width: 8),
              _ScoreBadge(score: score),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 5. Ranked List ──────────────────────────────────────────────────────────

class _RankedListSection extends StatelessWidget {
  const _RankedListSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, slug: slug, icon: icon, accent: accent),
          const SizedBox(height: 10),
          ...List.generate(
            slice.length,
            (i) => _RankedRow(item: slice[i], rank: i + 1),
          ),
        ],
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({required this.item, required this.rank});

  final Map<String, dynamic> item;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _bookTitle(item);
    final authors = (item['authors'] as List?)?.cast<String>();
    final subtitle = authors != null && authors.isNotEmpty ? authors.first : null;
    final year = item['year'] as int?;

    return GestureDetector(
      onTap: () => _navigateToBook(context, item),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: rank <= 3
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: 0.45),
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : _PosterPlaceholder(width: 48, height: 64, radius: 7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (year != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SKELETON WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _ScoreCarouselSkeleton extends StatelessWidget {
  const _ScoreCarouselSkeleton({
    required this.cardWidth,
    required this.cardHeight,
  });
  final double cardWidth, cardHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skel(context, w: 140, h: 16),
          const SizedBox(height: 12),
          SizedBox(
            height: cardHeight + 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, _) =>
                  _skel(ctx, w: cardWidth, h: cardHeight, r: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skel(context, w: 140, h: 16),
          const SizedBox(height: 12),
          _skel(context, w: double.infinity, h: 120, r: 14),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: Row(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  child: _skel(context, w: 70, h: 96, r: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodBandSkeleton extends StatelessWidget {
  const _MoodBandSkeleton({required this.accent, required this.darkBg});
  final Color accent, darkBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skel(context, w: 120, h: 16),
            const SizedBox(height: 12),
            SizedBox(
              height: 148,
              child: Row(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: _skel(context, w: 108, h: 148, r: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightRowsSkeleton extends StatelessWidget {
  const _SpotlightRowsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skel(context, w: 140, h: 16),
          const SizedBox(height: 10),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _skel(context, w: 48, h: 64, r: 7),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skel(context, w: double.infinity, h: 14),
                        const SizedBox(height: 6),
                        _skel(context, w: 100, h: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedListSkeleton extends StatelessWidget {
  const _RankedListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skel(context, w: 140, h: 16),
          const SizedBox(height: 10),
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: _skel(context, w: 20, h: 22, r: 4),
                  ),
                  const SizedBox(width: 10),
                  _skel(context, w: 48, h: 64, r: 7),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skel(context, w: double.infinity, h: 14),
                        const SizedBox(height: 6),
                        _skel(context, w: 80, h: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
