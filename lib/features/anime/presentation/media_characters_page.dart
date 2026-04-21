import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class MediaCharactersPage extends ConsumerStatefulWidget {
  const MediaCharactersPage({super.key, required this.mediaId});
  final int mediaId;

  @override
  ConsumerState<MediaCharactersPage> createState() =>
      _MediaCharactersPageState();
}

class _MediaCharactersPageState extends ConsumerState<MediaCharactersPage> {
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _edges = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = _page + 1;
      final res = await ref
          .read(anilistGraphqlProvider)
          .fetchMediaCharacters(widget.mediaId, page: next, perPage: 25);
      if (!mounted) return;
      setState(() {
        _page = next;
        _edges.addAll(res.edges);
        _hasMore = res.hasNextPage;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mediaCharacters)),
      body: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: _edges.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == _edges.length) {
            if (_error != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                    child: Text(l10n.errorWithMessage('$_error'))),
              );
            }
            if (!_hasMore) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _CharacterEdgeRow(edge: _edges[i]);
        },
      ),
    );
  }
}

class _CharacterEdgeRow extends StatelessWidget {
  const _CharacterEdgeRow({required this.edge});
  final Map<String, dynamic> edge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final node = edge['node'] as Map<String, dynamic>? ?? {};
    final name = (node['name'] as Map?)?['full'] as String? ?? '';
    final native = (node['name'] as Map?)?['native'] as String?;
    final img = (node['image'] as Map?)?['large'] as String? ??
        (node['image'] as Map?)?['medium'] as String?;
    final cId = node['id'] as int?;
    final role = edge['role'] as String?;
    final voiceActors =
        (edge['voiceActors'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: cId == null ? null : () => context.push('/character/$cId'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: img != null
                    ? CachedNetworkImage(
                        imageUrl: img,
                        width: 56,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 80,
                        color: cs.surfaceContainerHighest,
                        child: const Icon(Icons.person),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    if (native != null && native.isNotEmpty)
                      Text(native,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                    if (role != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_formatRole(role, l10n),
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
              if (voiceActors.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final va in voiceActors.take(1))
                      _VoiceActorChip(va: va),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceActorChip extends StatelessWidget {
  const _VoiceActorChip({required this.va});
  final Map<String, dynamic> va;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = (va['name'] as Map?)?['full'] as String? ?? '';
    final img = (va['image'] as Map?)?['medium'] as String? ??
        (va['image'] as Map?)?['large'] as String?;
    final id = va['id'] as int?;
    return InkWell(
      onTap: id == null ? null : () => context.push('/staff/$id'),
      child: SizedBox(
        width: 80,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage:
                  img != null ? CachedNetworkImageProvider(img) : null,
              child: img == null ? const Icon(Icons.person, size: 18) : null,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
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
