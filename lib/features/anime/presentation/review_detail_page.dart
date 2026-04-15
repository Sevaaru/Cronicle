import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class ReviewDetailPage extends ConsumerStatefulWidget {
  const ReviewDetailPage({super.key, required this.reviewId, this.initialData});
  final int reviewId;
  final Map<String, dynamic>? initialData;

  @override
  ConsumerState<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends ConsumerState<ReviewDetailPage> {
  Map<String, dynamic>? _review;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && (widget.initialData!['body'] as String?)?.isNotEmpty == true) {
      _review = widget.initialData;
      _loading = false;
    } else {
      _fetchReview();
    }
  }

  Future<void> _fetchReview() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    final data = await graphql.fetchReviewById(widget.reviewId, token: token);
    if (!mounted) return;
    setState(() {
      _review = data;
      _loading = false;
    });
  }

  Future<void> _rateReview(String rating) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.reviewLoginRequired)),
      );
      return;
    }
    final graphql = ref.read(anilistGraphqlProvider);
    final currentRating = _review?['userRating'] as String?;
    final newRating = (currentRating == rating) ? 'NO_VOTE' : rating;
    final result = await graphql.rateReview(widget.reviewId, newRating, token);
    if (result != null && mounted) {
      setState(() {
        _review = {..._review!, ...result};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _review == null
              ? Center(child: Text(l10n.errorGeneric))
              : _buildContent(cs, l10n),
    );
  }

  Widget _buildContent(ColorScheme cs, AppLocalizations l10n) {
    final review = _review!;
    final user = review['user'] as Map<String, dynamic>? ?? {};
    final avatar = user['avatar'] as Map<String, dynamic>? ?? {};
    final userName = user['name'] as String? ?? l10n.mediaAnonymous;
    final userId = user['id'] as int?;
    final score = review['score'] as int?;
    final body = review['body'] as String? ?? '';
    final rating = review['rating'] as int? ?? 0;
    final ratingAmount = review['ratingAmount'] as int? ?? 0;
    final userRating = review['userRating'] as String?;
    final createdAtRaw = review['createdAt'] as int?;

    String? dateStr;
    if (createdAtRaw != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw * 1000);
      dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: userId != null ? () => context.push('/user/$userId') : null,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: avatar['medium'] != null
                        ? CachedNetworkImageProvider(avatar['medium'] as String)
                        : null,
                    child: avatar['medium'] == null ? const Icon(Icons.person, size: 20) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: userId != null ? () => context.push('/user/$userId') : null,
                        child: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (dateStr != null)
                        Text(dateStr, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (score != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _scoreColor(score).withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: _scoreColor(score)),
                        const SizedBox(width: 2),
                        Text('$score/100', style: TextStyle(fontWeight: FontWeight.w700, color: _scoreColor(score), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: AnilistMarkdown(body),
          ),

          const SizedBox(height: 16),

          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reviewUsersFoundHelpful(rating, ratingAmount),
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${l10n.reviewHelpful}  ', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    FilledButton.tonalIcon(
                      onPressed: () => _rateReview('UP_VOTE'),
                      icon: Icon(
                        Icons.thumb_up_rounded,
                        size: 16,
                        color: userRating == 'UP_VOTE' ? Colors.green : null,
                      ),
                      label: Text(l10n.reviewUpVote),
                      style: FilledButton.styleFrom(
                        backgroundColor: userRating == 'UP_VOTE' ? Colors.green.withAlpha(40) : null,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 34),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _rateReview('DOWN_VOTE'),
                      icon: Icon(
                        Icons.thumb_down_rounded,
                        size: 16,
                        color: userRating == 'DOWN_VOTE' ? Colors.red : null,
                      ),
                      label: Text(l10n.reviewDownVote),
                      style: FilledButton.styleFrom(
                        backgroundColor: userRating == 'DOWN_VOTE' ? Colors.red.withAlpha(40) : null,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 34),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.amber.shade700;
    return Colors.red;
  }
}
