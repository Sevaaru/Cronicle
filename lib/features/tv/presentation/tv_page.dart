import 'package:flutter/material.dart';

import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/feature_placeholder_page.dart';

class TvPage extends StatelessWidget {
  const TvPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeaturePlaceholderPage(title: l10n.navTv);
  }
}
