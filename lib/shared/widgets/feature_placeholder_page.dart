import 'package:flutter/material.dart';

import 'package:cronicle/l10n/app_localizations.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          l10n.placeholderSoon,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
