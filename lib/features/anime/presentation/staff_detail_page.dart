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

class StaffDetailPage extends ConsumerWidget {
  const StaffDetailPage({super.key, required this.staffId});

  final int staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(anilistStaffDetailProvider(staffId));
    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
        data: (staff) {
          if (staff == null) return Center(child: Text(l10n.mediaNoData));
          return _StaffContent(staff: staff);
        },
      ),
    );
  }
}

class _StaffContent extends ConsumerStatefulWidget {
  const _StaffContent({required this.staff});
  final Map<String, dynamic> staff;

  @override
  ConsumerState<_StaffContent> createState() => _StaffContentState();
}

class _StaffContentState extends ConsumerState<_StaffContent> {
  bool _busy = false;
  bool _descExpanded = false;

  Map<String, dynamic> get s => widget.staff;

  Future<void> _toggleFavourite() async {
    final l10n = AppLocalizations.of(context)!;
    final token = await ref.read(anilistTokenProvider.future);
    setState(() => _busy = true);
    try {
      final id = s['id'] as int;
      if (token == null) {
        await ref
            .read(favoriteAnilistStaffProvider.notifier)
            .toggleLocalFavorite(s);
      } else {
        await ref.read(anilistGraphqlProvider).toggleFavouriteStaff(
              staffId: id,
              token: token,
            );
        ref.invalidate(anilistStaffDetailProvider(id));
        ref.invalidate(anilistProfileProvider);
      }
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

    final name = s['name'] as Map<String, dynamic>? ?? {};
    final fullName = (name['full'] as String?) ??
        (name['userPreferred'] as String?) ??
        '';
    final nativeName = name['native'] as String?;
    final image = s['image'] as Map<String, dynamic>? ?? {};
    final imageUrl =
        (image['large'] as String?) ?? (image['medium'] as String?);
    final description = s['description'] as String?;
    final favourites = s['favourites'] as int?;
    final localFav = ref
        .watch(favoriteAnilistStaffProvider)
        .any((e) => ((e['id'] as num?)?.toInt() ?? 0) == (s['id'] as int? ?? 0));
    final isFav = (s['isFavourite'] as bool? ?? false) || localFav;
    final siteUrl = s['siteUrl'] as String?;

    final age = s['age']?.toString();
    final gender = s['gender'] as String?;
    final bloodType = s['bloodType'] as String?;
    final homeTown = s['homeTown'] as String?;
    final dob = s['dateOfBirth'] as Map<String, dynamic>?;
    final dod = s['dateOfDeath'] as Map<String, dynamic>?;
    final yearsActive = (s['yearsActive'] as List?)?.cast<int>() ?? const [];
    final occupations =
        (s['primaryOccupations'] as List?)?.cast<String>() ?? const [];

    final charMedia = s['characterMedia'] as Map<String, dynamic>?;
    final charEdges =
        (charMedia?['edges'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
    final staffMedia = s['staffMedia'] as Map<String, dynamic>?;
    final staffEdges =
        (staffMedia?['edges'] as List?)?.cast<Map<String, dynamic>>() ??
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
                        if (occupations.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: occupations
                                  .map((o) => Chip(
                                        label: Text(o,
                                            style: const TextStyle(
                                                fontSize: 10)),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.zero,
                                      ))
                                  .toList(),
                            ),
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
                    if (age != null && age.isNotEmpty && age != 'null')
                      (l10n.staffAge, age),
                    if (gender != null && gender.isNotEmpty)
                      (l10n.staffGender, gender),
                    if (homeTown != null && homeTown.isNotEmpty)
                      (l10n.staffHomeTown, homeTown),
                    if (bloodType != null && bloodType.isNotEmpty)
                      (l10n.staffBloodType, bloodType),
                    if (_formatDate(dob).isNotEmpty)
                      (l10n.staffDateOfBirth, _formatDate(dob)),
                    if (_formatDate(dod).isNotEmpty)
                      (l10n.staffDateOfDeath, _formatDate(dod)),
                    if (yearsActive.isNotEmpty)
                      (l10n.staffYearsActive, yearsActive.join(' – ')),
                  ],
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
                if (charEdges.isNotEmpty) ...[
                  Text(l10n.staffCharacterRoles,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...charEdges.map((edge) => _CharacterRoleTile(edge: edge)),
                  const SizedBox(height: 16),
                ],
                if (staffEdges.isNotEmpty) ...[
                  Text(l10n.staffRoles,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...staffEdges.map((edge) => _StaffRoleTile(edge: edge)),
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
    if (y != null && m == null) return '$y';
    if (y != null && m != null && day == null) return '$m/$y';
    if (y != null) return '$day/$m/$y';
    return '';
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

class _CharacterRoleTile extends StatelessWidget {
  const _CharacterRoleTile({required this.edge});
  final Map<String, dynamic> edge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final node = edge['node'] as Map<String, dynamic>? ?? {};
    final title = node['title'] as Map<String, dynamic>? ?? {};
    final cover = (node['coverImage'] as Map?)?['large'] as String?;
    final mid = node['id'] as int?;
    final mtype = node['type'] as String?;
    final chars =
        (edge['characters'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final year = node['seasonYear']?.toString();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: mid == null
                ? null
                : () {
                    final mk =
                        mtype == 'MANGA' ? MediaKind.manga : MediaKind.anime;
                    context.push('/media/$mid?kind=${mk.code}');
                  },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cover != null
                  ? CachedNetworkImage(
                      imageUrl: cover, width: 50, height: 70, fit: BoxFit.cover)
                  : Container(
                      width: 50,
                      height: 70,
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.image_outlined),
                    ),
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
                if (year != null && year != 'null')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('· $year',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chars.map((c) {
                    final cName =
                        (c['name'] as Map?)?['full'] as String? ?? '';
                    final cImg = (c['image'] as Map?)?['medium'] as String? ??
                        (c['image'] as Map?)?['large'] as String?;
                    final cId = c['id'] as int?;
                    return InkWell(
                      onTap: cId == null
                          ? null
                          : () => context.push('/character/$cId'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: cImg != null
                                ? CachedNetworkImageProvider(cImg)
                                : null,
                            child: cImg == null
                                ? const Icon(Icons.person, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(cName,
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffRoleTile extends StatelessWidget {
  const _StaffRoleTile({required this.edge});
  final Map<String, dynamic> edge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final node = edge['node'] as Map<String, dynamic>? ?? {};
    final title = node['title'] as Map<String, dynamic>? ?? {};
    final cover = (node['coverImage'] as Map?)?['large'] as String?;
    final mid = node['id'] as int?;
    final mtype = node['type'] as String?;
    final role = edge['staffRole'] as String?;
    final year = node['seasonYear']?.toString();

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
                      imageUrl: cover, width: 50, height: 70, fit: BoxFit.cover)
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
                  if (role != null && role.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(role,
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  if (year != null && year != 'null')
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(year,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
