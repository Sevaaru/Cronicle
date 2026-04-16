import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/trakt/data/trakt_library_remote_sync.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';
import 'package:cronicle/shared/widgets/remote_network_image.dart';

String traktFormatApiStatus(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  return raw.replaceAll('_', ' ');
}

String traktFormatGenreLabel(String g) => g.replaceAll('-', ' ');

String traktFormatVoteCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

class TraktTag extends StatelessWidget {
  const TraktTag(this.text, this.bg, this.fg, {super.key});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class TraktStatColumn extends StatelessWidget {
  const TraktStatColumn(this.icon, this.iconColor, this.value, this.label, {super.key});
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class TraktInfoPill extends StatelessWidget {
  const TraktInfoPill(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

/// Cabecera estilo detalle Anilist/IGDB: banner + póster superpuesto + título.
class TraktDetailHeroHeader extends StatelessWidget {
  const TraktDetailHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.poster,
    this.fanart,
  });

  final String title;
  final String? subtitle;
  final String? poster;
  final String? fanart;

  static const _bannerH = 200.0;
  static const _posterH = 140.0;
  static const _posterW = 95.0;
  static const _overlap = 50.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness:
            (fanart != null || isDark) ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            (fanart != null || isDark) ? Brightness.dark : Brightness.light,
      ),
      child: Column(
        children: [
          SizedBox(
            height: _bannerH + _posterH - _overlap + 10,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: fanart != null ? () => showFullscreenImage(context, fanart!) : null,
                  child: Container(
                    height: _bannerH,
                    width: double.infinity,
                    color: fanart == null ? cs.surfaceContainerHighest : null,
                    child: fanart != null
                        ? ClipRect(
                            child: RemoteNetworkImage(
                              imageUrl: fanart!,
                              width: double.infinity,
                              height: _bannerH,
                              fit: BoxFit.cover,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _bannerH,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(fanart != null ? 40 : 0),
                          Colors.black.withAlpha(fanart != null ? 80 : 0),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black26),
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
                      if (poster != null)
                        GestureDetector(
                          onTap: () => showFullscreenImage(context, poster!),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.surface, width: 3),
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
                              child: RemoteNetworkImage(
                                imageUrl: poster!,
                                width: _posterW,
                                height: _posterH,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cs.surface.withAlpha(210),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (subtitle != null && subtitle!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, top: 4),
                                  child: Text(
                                    subtitle!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    maxLines: 4,
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class TraktFavoriteButton extends ConsumerWidget {
  const TraktFavoriteButton({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final id = (item['id'] as num?)?.toInt() ?? 0;
    final type = (item['trakt_type'] as String?) ?? 'movie';
    final list = ref.watch(favoriteTraktTitlesProvider);
    final isFav = id != 0 &&
        list.any((e) {
          final eid = (e['id'] as num?)?.toInt() ?? 0;
          final et = (e['trakt_type'] as String?) ?? 'movie';
          return eid == id && et == type;
        });

    return Tooltip(
      message: isFav ? l10n.tooltipRemoveFavorite : l10n.tooltipAddFavorite,
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: id == 0
            ? null
            : () => ref.read(favoriteTraktTitlesProvider.notifier).toggleFavorite(item),
        icon: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFav ? Colors.redAccent : null,
        ),
      ),
    );
  }
}

class TraktAddToLibraryRow extends ConsumerWidget {
  const TraktAddToLibraryRow({
    super.key,
    required this.item,
    required this.kind,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TraktFavoriteButton(item: item),
        const SizedBox(width: 8),
        Expanded(child: _TraktAddToLibraryButton(item: item, kind: kind)),
      ],
    );
  }
}

class _TraktAddToLibraryButton extends ConsumerWidget {
  const _TraktAddToLibraryButton({required this.item, required this.kind});

  final Map<String, dynamic> item;
  final MediaKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final db = ref.watch(databaseProvider);
    final extId = '${item['id'] ?? ''}';

    return StreamBuilder<LibraryEntry?>(
      stream: db.watchLibraryByKind(kind.code).map(
            (list) => list.cast<LibraryEntry?>().firstWhere(
                  (e) => e?.externalId == extId,
                  orElse: () => null,
                ),
          ),
      builder: (context, snap) {
        final existing = snap.data;
        final inLibrary = existing != null;
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            icon: Icon(inLibrary ? Icons.edit : Icons.library_add_check_rounded),
            label: Text(inLibrary ? l10n.editLibraryEntry : l10n.addToListTitle),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: inLibrary ? cs.secondaryContainer : null,
              foregroundColor: inLibrary ? cs.onSecondaryContainer : null,
            ),
            onPressed: () async {
              final added = await showAddToLibrarySheet(
                context: context,
                ref: ref,
                item: item,
                kind: kind,
                existingEntry: existing,
              );
              if (context.mounted && added) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      inLibrary ? l10n.entryUpdated : l10n.addedToLibrary,
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

Future<void> traktLaunchUrl(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final l10n = AppLocalizations.of(context)!;
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(url))),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage('$e'))),
      );
    }
  }
}

List<Widget> traktExternalLinkChips(
  BuildContext context,
  AppLocalizations l10n,
  Map<String, dynamic> item, {
  required bool isMovie,
}) {
  final chips = <Widget>[];

  void add(String label, String? url) {
    if (url == null || url.isEmpty) return;
    chips.add(
      ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        onPressed: () => traktLaunchUrl(context, url),
      ),
    );
  }

  add(l10n.traktLinkTrailer, item['trailer'] as String?);
  add(l10n.traktLinkHomepage, item['homepage'] as String?);

  final imdb = item['imdb_id'] as String?;
  if (imdb != null && imdb.isNotEmpty) {
    add('IMDb', 'https://www.imdb.com/title/$imdb');
  }
  final tmdb = item['tmdb_id'];
  final tmdbInt = tmdb is int ? tmdb : int.tryParse('$tmdb');
  if (tmdbInt != null && tmdbInt > 0) {
    add(
      'TMDB',
      isMovie
          ? 'https://www.themoviedb.org/movie/$tmdbInt'
          : 'https://www.themoviedb.org/tv/$tmdbInt',
    );
  }
  final slug = item['trakt_slug'] as String?;
  final type = isMovie ? 'movies' : 'shows';
  if (slug != null && slug.isNotEmpty) {
    add(l10n.traktDetailOnTrakt, 'https://trakt.tv/$type/$slug');
  }

  if (chips.isEmpty) return [];

  return [
    Text(
      l10n.traktDetailLinks,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
    const SizedBox(height: 8),
    Wrap(spacing: 8, runSpacing: 8, children: chips),
    SizedBox(height: chips.isNotEmpty ? 12 : 0),
  ];
}

/// Progreso por episodio (conteo local) para series Trakt en biblioteca.
class TraktTvEpisodeProgressCard extends ConsumerWidget {
  const TraktTvEpisodeProgressCard({
    super.key,
    required this.traktId,
    required this.item,
  });

  final int traktId;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final db = ref.watch(databaseProvider);
    final ext = '$traktId';
    final apiTotal = item['episodes'] as int?;

    return StreamBuilder<List<LibraryEntry>>(
      stream: db.watchLibraryByKind(MediaKind.tv.code),
      builder: (context, snap) {
        final entries = snap.data ?? [];
        LibraryEntry? found;
        for (final e in entries) {
          if (e.externalId == ext) {
            found = e;
            break;
          }
        }
        if (found == null) {
          return GlassCard(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.traktEpisodeProgressHint,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.35),
            ),
          );
        }
        final entry = found;

        final prog = entry.progress ?? 0;
        final maxE = entry.totalEpisodes ?? apiTotal ?? 0;
        final ratio = maxE > 0 ? (prog / maxE).clamp(0.0, 1.0) : 0.0;

        Future<void> bump(int delta) async {
          var next = prog + delta;
          if (next < 0) next = 0;
          if (maxE > 0 && next > maxE) next = maxE;
          await db.setLibraryProgress(entry.id, next);
          unawaited(syncTraktEntryFromLocalDatabase(ref, MediaKind.tv, traktId));
        }

        Future<void> setAbs(int v) async {
          await db.setLibraryProgress(entry.id, v);
          unawaited(syncTraktEntryFromLocalDatabase(ref, MediaKind.tv, traktId));
        }

        Future<void> markComplete() async {
          await db.setLibraryProgressAndStatus(entry.id, maxE, 'COMPLETED');
          unawaited(syncTraktEntryFromLocalDatabase(ref, MediaKind.tv, traktId));
        }

        return GlassCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.traktEpisodeProgressTitle,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: maxE > 0 ? ratio : 0,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.traktEpisodeMinusOne,
                    onPressed: prog > 0 ? () => bump(-1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Expanded(
                    child: Text(
                      maxE > 0 ? '$prog / $maxE' : '$prog',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.traktEpisodePlusOne,
                    onPressed: maxE <= 0 || prog < maxE ? () => bump(1) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              if (maxE > 0) ...[
                Slider(
                  value: prog.clamp(0, maxE).toDouble(),
                  min: 0,
                  max: maxE.toDouble(),
                  divisions: maxE > 120 ? null : maxE,
                  label: '$prog',
                  onChanged: (v) => setAbs(v.round()),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: prog >= maxE ? null : markComplete,
                    child: Text(l10n.traktEpisodeProgressMarkComplete),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
