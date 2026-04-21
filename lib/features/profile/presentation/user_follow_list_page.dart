import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class UserFollowListPage extends ConsumerStatefulWidget {
  const UserFollowListPage({
    super.key,
    required this.userId,
    required this.followers,
  });

  final int userId;
  final bool followers;

  @override
  ConsumerState<UserFollowListPage> createState() => _UserFollowListPageState();
}

class _UserFollowListPageState extends ConsumerState<UserFollowListPage> {
  final _scroll = ScrollController();
  final _users = <Map<String, dynamic>>[];
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = true;
  String? _error;

  static const _perPage = 50;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(initial: true);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasNext || _loadingMore || _loading) return;
    final pos = _scroll.position;
    if (!pos.hasViewportDimension) return;
    if (pos.pixels > pos.maxScrollExtent - 280) {
      _load(initial: false);
    }
  }

  Future<void> _load({required bool initial}) async {
    if (initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final token = await ref.read(anilistTokenProvider.future);
      final graphql = ref.read(anilistGraphqlProvider);
      final page = initial ? 1 : _page + 1;
      final result = await graphql.fetchUserFollowListPage(
        widget.userId,
        followers: widget.followers,
        page: page,
        perPage: _perPage,
        token: token,
      );
      if (!mounted) return;
      setState(() {
        if (initial) {
          _users
            ..clear()
            ..addAll(result.users);
        } else {
          _users.addAll(result.users);
        }
        _page = page;
        _hasNext = result.hasNextPage;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (initial) _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title =
        widget.followers ? l10n.anilistProfileFollowers : l10n.anilistProfileFollowing;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(initial: true),
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(_error!, textAlign: TextAlign.center)),
          ),
        ],
      );
    }
    if (_users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.35,
            child: Center(child: Text(l10n.anilistFollowListEmpty)),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
      itemCount: _users.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _users.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final u = _users[i];
        final id = u['id'] as int?;
        final name = u['name'] as String? ?? '';
        final avatar = (u['avatar'] as Map?)?['large'] as String? ??
            (u['avatar'] as Map?)?['medium'] as String?;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                avatar != null ? CachedNetworkImageProvider(avatar) : null,
            child: avatar == null
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                : null,
          ),
          title: Text(name),
          onTap: id != null ? () => context.push('/user/$id') : null,
        );
      },
    );
  }
}
