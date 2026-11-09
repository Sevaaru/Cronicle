import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/features/trakt/presentation/trakt_home_feed_view.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

class TvPage extends StatelessWidget {
  const TvPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/feed');
            }
          },
        ),
        title: Text(l10n.navTv),
      ),
      body: const TraktHomeFeedView(kind: MediaKind.tv),
    );
  }
}
