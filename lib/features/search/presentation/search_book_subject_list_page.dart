import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/l10n/app_localizations.dart';

/// Book subjects shown from search browse.
const kBookBrowseSubjects = <String>[
  'fantasy',
  'romance',
  'science_fiction',
  'horror',
  'mystery',
  'fiction',
  'history',
  'biography',
];

String bookSubjectLabel(AppLocalizations l10n, String slug) =>
    switch (slug) {
      'fantasy' => l10n.searchOlSubjectFantasy,
      'romance' => l10n.searchOlSubjectRomance,
      'science_fiction' => l10n.searchOlSubjectScienceFiction,
      'horror' => l10n.searchOlSubjectHorror,
      'mystery' => l10n.searchOlSubjectMystery,
      'fiction' => l10n.searchOlSubjectFiction,
      'history' => l10n.searchOlSubjectHistory,
      'biography' => l10n.searchOlSubjectBiography,
      _ => slug,
    };

class SearchBookSubjectListPage extends StatelessWidget {
  const SearchBookSubjectListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.searchBrowseBookSubjects),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: kBookBrowseSubjects.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final slug = kBookBrowseSubjects[i];
          final label = bookSubjectLabel(l10n, slug);
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text(label),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                context.push(
                  '/books/subject?subject=${Uri.encodeQueryComponent(slug)}&sort=popularity',
                );
              },
            ),
          );
        },
      ),
    );
  }
}
