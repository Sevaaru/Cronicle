import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class CharacterDetailPage extends ConsumerWidget {
  const CharacterDetailPage({super.key, required this.characterId});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(anilistCharacterDetailProvider(characterId));
    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
        data: (character) {
          if (character == null) return Center(child: Text(l10n.mediaNoData));
          return _CharacterContent(character: character);
        },
      ),
    );
  }
}

class _CharacterContent extends ConsumerStatefulWidget {
  const _CharacterContent({required this.character});
  final Map<String, dynamic> character;

  @override
  ConsumerState<_CharacterContent> createState() => _CharacterContentState();
}

class _CharacterContentState extends ConsumerState<_CharacterContent> {
  bool _busy = false;
  bool _descExpanded = false;

  Map<String, dynamic> get c => widget.character;

  Future<void> _toggleFavourite() async {
    final l10n = AppLocalizations.of(context)!;
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginRequiredFavoriteCharacter)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(anilistGraphqlProvider).toggleFavouriteCharacter(
            characterId: c['id'] as int,
            token: token,
          );
      ref.invalidate(anilistCharacterDetailProvider(c['id'] as int));
      ref.invalidate(anilistProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = c['name'] as Map<String, dynamic>? ?? {};
    final fullName = (name['full'] as String?) ??
        (name['userPreferred'] as String?) ??
        '';
    final nativeName = name['native'] as String?;
    final image = c['image'] as Map<String, dynamic>? ?? {};
    final imageUrl = (image['large'] as String?) ?? (image['medium'] as String?);
    final description = c['description'] as String?;
    final favourites = c['favourites'] as int?;
    final isFav = c['isFavourite'] as bool? ?? false;
    final siteUrl = c['siteUrl'] as String?;

    final age = c['age'] as String?;
    final gender = c['gender'] as String?;
    final bloodType = c['bloodType'] as String?;
    final dob = c['dateOfBirth'] as Map<String, dynamic>?;
    final altNames = (name['alternative'] as List?)?.cast<String>() ?? const [];
    final altSpoiler =
        (name['alternativeSpoiler'] as List?)?.cast<String>() ?? const [];

    final mediaContainer = c['media'] as Map<String, dynamic>?;
    final mediaEdges = (mediaContainer?['edges'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              if (siteUrl != null && siteUrl.isNotEmpty)
                IconButton(
                  tooltip: 'AniList',
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: () => launchUrl(Uri.parse(siteUrl),
                      mode: LaunchMode.externalApplication),
                ),
              IconButton(
                tooltip: isFav
                    ? l10n.tooltipRemoveFavorite
                    : l10n.tooltipAddFavorite,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? Colors.redAccent : null,
                      ),
                onPressed: _busy ? null : _toggleFavourite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    GestureDetector(
                      onTap: () => showFullscreenImage(context, imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 120,
                          height: 170,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700)),
                        if (nativeName != null && nativeName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(nativeName,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant)),
                          ),
                        const SizedBox(height: 8),
                        if (favourites != null)
                          Row(
                            children: [
                              const Icon(Icons.favorite,
                                  size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text('$favourites',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.list(
              children: [
                _InfoCard(
                  rows: [
                    if (age != null && age.isNotEmpty)
                      (l10n.characterAge, age),
                    if (gender != null && gender.isNotEmpty)
                      (l10n.characterGender, gender),
                    if (bloodType != null && bloodType.isNotEmpty)
                      (l10n.characterBloodType, bloodType),
                    if (_formatDate(dob).isNotEmpty)
                      (l10n.characterDateOfBirth, _formatDate(dob)),
                  ],
                ),
                if (altNames.isNotEmpty)
                  _ChipsCard(
                    title: l10n.characterAlternativeNames,
                    items: altNames,
                  ),
                if (altSpoiler.isNotEmpty)
                  _ChipsCard(
                    title: l10n.characterAlternativeSpoiler,
                    items: altSpoiler,
                    spoiler: true,
                  ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(l10n.characterDescription,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: _descExpanded ? double.infinity : 220,
                          ),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: AnilistMarkdown(
                              description,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                  height: 1.5),
                            ),
                          ),
                        ),
                        if (description.length > 400)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => setState(
                                  () => _descExpanded = !_descExpanded),
                              child: Text(_descExpanded
                                  ? l10n.mediaDetailChipsShowLess
                                  : l10n.mediaDetailChipsShowMore),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (mediaEdges.isNotEmpty) ...[
                  Text(l10n.characterAppearances,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...mediaEdges.map((edge) => _MediaEdgeTile(edge: edge)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Map<String, dynamic>? d) {
    if (d == null) return '';
    final y = d['year'];
    final m = d['month'];
    final day = d['day'];
    if (y == null && m == null && day == null) return '';
    if (y == null && m != null && day != null) return '$day/$m';
    if (y != null && m == null) return '$y';
    if (y != null && m != null && day == null) return '$m/$y';
    return '$day/$m/$y';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 24,
          runSpacing: 8,
          children: rows
              .map((r) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(r.$1,
                          style: TextStyle(
                              fontSize: 10, color: cs.onSurfaceVariant)),
                      Text(r.$2,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _ChipsCard extends StatefulWidget {
  const _ChipsCard({
    required this.title,
    required this.items,
    this.spoiler = false,
  });

  final String title;
  final List<String> items;
  final bool spoiler;

  @override
  State<_ChipsCard> createState() => _ChipsCardState();
}

class _ChipsCardState extends State<_ChipsCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showItems = !widget.spoiler || _revealed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                if (widget.spoiler) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _revealed = !_revealed),
                    icon: Icon(_revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                        size: 16),
                    label: Text(_revealed ? 'Hide' : 'Reveal',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 6),
            if (!showItems)
              Text('•••', style: TextStyle(color: cs.onSurfaceVariant))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.items
                    .map((s) => Chip(
                          label: Text(s,
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaEdgeTile extends StatelessWidget {
  const _MediaEdgeTile({required this.edge});
  final Map<String, dynamic> edge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final node = edge['node'] as Map<String, dynamic>? ?? {};
    final title = node['title'] as Map<String, dynamic>? ?? {};
    final cover = (node['coverImage'] as Map?)?['large'] as String?;
    final mid = node['id'] as int?;
    final mtype = node['type'] as String?;
    final role = edge['characterRole'] as String?;
    final year = node['seasonYear']?.toString();
    final voiceActors =
        (edge['voiceActors'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: mid == null
            ? null
            : () {
                final mk = mtype == 'MANGA' ? MediaKind.manga : MediaKind.anime;
                context.push('/media/$mid?kind=${mk.code}');
              },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cover != null
                  ? CachedNetworkImage(
                      imageUrl: cover,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 50,
                      height: 70,
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.image_outlined),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (title['english'] as String?) ??
                        (title['romaji'] as String?) ??
                        '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (role != null && role.isNotEmpty)
                        Text(
                          _formatRole(role, l10n),
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      if (year != null && year != 'null')
                        Text('· $year',
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                  if (voiceActors.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(l10n.characterVoiceActors,
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: voiceActors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final va = voiceActors[i];
                          final vaName =
                              (va['name'] as Map?)?['full'] as String? ?? '';
                          final vaImg =
                              (va['image'] as Map?)?['medium'] as String? ??
                                  (va['image'] as Map?)?['large'] as String?;
                          final vaId = va['id'] as int?;
                          return InkWell(
                            onTap: vaId == null
                                ? null
                                : () => context.push('/staff/$vaId'),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: vaImg != null
                                      ? CachedNetworkImageProvider(vaImg)
                                      : null,
                                  child: vaImg == null
                                      ? const Icon(Icons.person, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(vaName,
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          );
                        },
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

String _formatRole(String role, AppLocalizations l10n) {
  return switch (role) {
    'MAIN' => l10n.characterRoleMain,
    'SUPPORTING' => l10n.characterRoleSupporting,
    'BACKGROUND' => l10n.characterRoleBackground,
    _ => role,
  };
}
