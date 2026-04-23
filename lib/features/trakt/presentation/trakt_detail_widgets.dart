import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/trakt/data/trakt_library_remote_sync.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/library_snackbar.dart';
import 'package:cronicle/shared/widgets/library_insert_animation.dart';
import 'package:cronicle/shared/widgets/m3_detail.dart';

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

/// Formats a Trakt ISO-8601 date/datetime string (e.g. `2019-07-25` or
/// `2019-07-25T07:00:00.000Z`) into a human-readable, locale-aware date.
/// Returns the raw string as a safe fallback if parsing fails.
String traktFormatDate(BuildContext context, String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(dt.toLocal());
}

class TraktTag extends StatelessWidget {
  const TraktTag(this.text, this.bg, this.fg, {super.key});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return M3HeroPill(text, bg: bg, fg: fg);
  }
}

class TraktStatColumn extends StatelessWidget {
  const TraktStatColumn(this.icon, this.iconColor, this.value, this.label,
      {super.key});
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
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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

class TraktDetailHeroHeader extends StatelessWidget {
  const TraktDetailHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleLines,
    this.pills = const [],
    this.poster,
    this.fanart,
  });

  final String title;
  final String? subtitle;
  final List<String>? subtitleLines;
  final List<Widget> pills;
  final String? poster;
  final String? fanart;

  @override
  Widget build(BuildContext context) {
    final lines = subtitleLines ??
        (subtitle != null && subtitle!.isNotEmpty
            ? subtitle!.split('\n').where((l) => l.isNotEmpty).toList()
            : const <String>[]);
    return M3DetailHero(
      title: title,
      subtitleLines: lines,
      pills: pills,
      banner: fanart,
      poster: poster,
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

    return M3FavoriteIconButton(
      isFavorite: isFav,
      tooltip: isFav ? l10n.tooltipRemoveFavorite : l10n.tooltipAddFavorite,
      onPressed: id == 0
          ? null
          : () => ref
              .read(favoriteTraktTitlesProvider.notifier)
              .toggleFavorite(item),
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
          child: M3AddToLibraryButton(
            isEdit: inLibrary,
            label: inLibrary ? l10n.editLibraryEntry : l10n.addToListTitle,
            onPressed: () async {
              final added = await showAddToLibrarySheet(
                context: context,
                ref: ref,
                item: item,
                kind: kind,
                existingEntry: existing,
              );
              if (context.mounted && added) {
                if (!inLibrary) {
                  final coverUrl = (item['poster'] as String?) ??
                      (item['fanart'] as String?);
                  playLibraryInsertAnimation(
                    sourceContext: context,
                    imageUrl: coverUrl,
                  );
                }
                showLibrarySnackbar(context, wasEdit: inLibrary);
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
  final cs = Theme.of(context).colorScheme;
  final chips = <Widget>[];

  void add(String label, String? url, {Color? bg, Color? fg, IconData? icon}) {
    if (url == null || url.isEmpty) return;
    chips.add(
      M3PillChip(
        label: label,
        bg: bg ?? cs.surfaceContainerHigh,
        fg: fg ?? cs.onSurface,
        icon: icon,
        onTap: () => traktLaunchUrl(context, url),
      ),
    );
  }

  add(l10n.traktLinkTrailer, item['trailer'] as String?,
      icon: Icons.play_circle_outline_rounded);
  add(l10n.traktLinkHomepage, item['homepage'] as String?,
      icon: Icons.public_rounded);

  final imdb = item['imdb_id'] as String?;
  if (imdb != null && imdb.isNotEmpty) {
    add('IMDb', 'https://www.imdb.com/title/$imdb',
        bg: cs.tertiaryContainer, fg: cs.onTertiaryContainer);
  }
  final tmdb = item['tmdb_id'];
  final tmdbInt = tmdb is int ? tmdb : int.tryParse('$tmdb');
  if (tmdbInt != null && tmdbInt > 0) {
    add(
      'TMDB',
      isMovie
          ? 'https://www.themoviedb.org/movie/$tmdbInt'
          : 'https://www.themoviedb.org/tv/$tmdbInt',
      bg: cs.tertiaryContainer,
      fg: cs.onTertiaryContainer,
    );
  }
  final slug = item['trakt_slug'] as String?;
  final type = isMovie ? 'movies' : 'shows';
  if (slug != null && slug.isNotEmpty) {
    add(l10n.traktDetailOnTrakt, 'https://trakt.tv/$type/$slug',
        bg: cs.tertiaryContainer, fg: cs.onTertiaryContainer);
  }

  if (chips.isEmpty) return [];

  return [
    M3SectionHeader(label: l10n.traktDetailLinks),
    const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 8, children: chips),
    const SizedBox(height: 12),
  ];
}

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
          return M3SurfaceCard(
            child: Text(
              l10n.traktEpisodeProgressHint,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.35),
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

        return M3SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              M3SectionHeader(label: l10n.traktEpisodeProgressTitle),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: maxE > 0 ? ratio : 0,
                  minHeight: 8,
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.traktEpisodePlusOne,
                    onPressed:
                        maxE <= 0 || prog < maxE ? () => bump(1) : null,
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
