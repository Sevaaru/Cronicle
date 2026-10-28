import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';

enum LikersTarget { activity, reply }

/// Opens a modal bottom sheet showing all users that liked an AniList
/// activity (or activity reply). Tapping a user navigates to their profile.
Future<void> showActivityLikersSheet(
  BuildContext context,
  WidgetRef ref, {
  required int targetId,
  LikersTarget target = LikersTarget.activity,
  int? expectedCount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _LikersSheet(
      targetId: targetId,
      target: target,
      expectedCount: expectedCount,
    ),
  );
}

class _LikersSheet extends ConsumerStatefulWidget {
  const _LikersSheet({
    required this.targetId,
    required this.target,
    required this.expectedCount,
  });

  final int targetId;
  final LikersTarget target;
  final int? expectedCount;

  @override
  ConsumerState<_LikersSheet> createState() => _LikersSheetState();
}

class _LikersSheetState extends ConsumerState<_LikersSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final token = await ref.read(anilistTokenProvider.future);
    final graphql = ref.read(anilistGraphqlProvider);
    return widget.target == LikersTarget.activity
        ? graphql.fetchActivityLikes(widget.targetId, token: token)
        : graphql.fetchActivityReplyLikes(widget.targetId, token: token);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      size: 18, color: const Color(0xFFE53935)),
                  const SizedBox(width: 8),
                  Text(
                    'Likes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  color: cs.error, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                snap.error.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _future = _load()),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final users = snap.data ?? const [];
                    if (users.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Aún no hay likes',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final u = users[i];
                        final id = u['id'] as int?;
                        final name = u['name'] as String? ?? '';
                        final avatar = u['avatar'] as String?;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: id == null
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                    context.push('/user/$id');
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        cs.surfaceContainerHighest,
                                    backgroundImage: avatar != null
                                        ? CachedNetworkImageProvider(avatar)
                                        : null,
                                    child: avatar == null
                                        ? Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: cs.onSurface),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      size: 18,
                                      color: cs.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
