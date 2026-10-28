import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class MediaStaffPage extends ConsumerStatefulWidget {
  const MediaStaffPage({super.key, required this.mediaId});
  final int mediaId;

  @override
  ConsumerState<MediaStaffPage> createState() => _MediaStaffPageState();
}

class _MediaStaffPageState extends ConsumerState<MediaStaffPage> {
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
          .fetchMediaStaff(widget.mediaId, page: next, perPage: 25);
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mediaStaff)),
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
          final edge = _edges[i];
          final node = edge['node'] as Map<String, dynamic>? ?? {};
          final name = (node['name'] as Map?)?['full'] as String? ?? '';
          final native = (node['name'] as Map?)?['native'] as String?;
          final img = (node['image'] as Map?)?['large'] as String? ??
              (node['image'] as Map?)?['medium'] as String?;
          final sId = node['id'] as int?;
          final role = edge['role'] as String?;

          return Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: sId == null ? null : () => context.push('/staff/$sId'),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          if (native != null && native.isNotEmpty)
                            Text(native,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant)),
                          if (role != null && role.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(role,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
