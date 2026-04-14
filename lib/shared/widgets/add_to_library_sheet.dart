import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:drift/drift.dart' as drift;

const _anilistStatuses = [
  ('CURRENT', 'Viendo', Icons.play_arrow_rounded),
  ('PLANNING', 'Planeado', Icons.bookmark_add_outlined),
  ('COMPLETED', 'Completado', Icons.check_circle_outline),
  ('DROPPED', 'Abandonado', Icons.cancel_outlined),
  ('PAUSED', 'Pausado', Icons.pause_circle_outline),
  ('REPEATING', 'Rewatching', Icons.replay_rounded),
];

const _mangaStatuses = [
  ('CURRENT', 'Leyendo', Icons.auto_stories_rounded),
  ('PLANNING', 'Planeado', Icons.bookmark_add_outlined),
  ('COMPLETED', 'Completado', Icons.check_circle_outline),
  ('DROPPED', 'Abandonado', Icons.cancel_outlined),
  ('PAUSED', 'Pausado', Icons.pause_circle_outline),
  ('REPEATING', 'Releyendo', Icons.replay_rounded),
];

/// Shows the "add to library" bottom sheet.
/// Returns true if the item was added.
Future<bool> showAddToLibrarySheet({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> item,
  required MediaKind kind,
}) async {
  final db = ref.read(databaseProvider);

  // First-time Anilist prompt (only for anime/manga, only once ever)
  if (kind == MediaKind.anime || kind == MediaKind.manga) {
    final prompted = await db.getKeyValue('anilist_prompt_shown');
    if (prompted == null && context.mounted) {
      final choice = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _AnilistPromptDialog(),
      );
      await db.setKeyValue('anilist_prompt_shown', 'true');

      if (choice == 'connect' && context.mounted) {
        final auth = ref.read(anilistAuthProvider);
        await launchUrl(
          Uri.parse(auth.authorizeUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  if (!context.mounted) return false;

  final result = await showModalBottomSheet<_AddResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddToLibrarySheet(item: item, kind: kind),
  );

  if (result == null) return false;

  final title = item['title'] as Map<String, dynamic>? ?? {};
  final coverImage = item['coverImage'] as Map<String, dynamic>? ?? {};
  final isManga = kind == MediaKind.manga;
  final mediaId = item['id'];

  await db.upsertLibraryEntry(
    LibraryEntriesCompanion(
      kind: drift.Value(kind.code),
      externalId: drift.Value(mediaId.toString()),
      title: drift.Value(
        (title['english'] as String?) ??
            (title['romaji'] as String?) ??
            (item['name'] as String?) ??
            'Unknown',
      ),
      posterUrl: drift.Value(
        (coverImage['extraLarge'] as String?) ??
            (coverImage['large'] as String?),
      ),
      status: drift.Value(result.status),
      score: drift.Value(result.score),
      progress: drift.Value(result.progress),
      totalEpisodes: drift.Value(
        isManga
            ? (item['chapters'] as num?)?.toInt()
            : (item['episodes'] as num?)?.toInt(),
      ),
      notes: drift.Value(result.notes),
      updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
    ),
  );

  // Sincronizar con Anilist si estamos logueados y es anime/manga
  if ((kind == MediaKind.anime || kind == MediaKind.manga) && mediaId != null) {
    _syncEntryToAnilist(ref, mediaId as int, result);
  }

  return true;
}

/// Envía los cambios a Anilist en background (fire-and-forget).
void _syncEntryToAnilist(WidgetRef ref, int mediaId, _AddResult result) async {
  try {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) return;
    final graphql = ref.read(anilistGraphqlProvider);
    await graphql.saveMediaListEntry(
      mediaId: mediaId,
      token: token,
      status: result.status,
      score: result.score,
      progress: result.progress,
      notes: result.notes,
    );
  } catch (_) {
    // Sync silencioso, no bloqueamos al usuario
  }
}

class _AddResult {
  const _AddResult({
    required this.status,
    this.score,
    this.progress,
    this.notes,
  });
  final String status;
  final int? score;
  final int? progress;
  final String? notes;
}

class _AnilistPromptDialog extends StatelessWidget {
  const _AnilistPromptDialog();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.sync_rounded, size: 40, color: cs.primary),
      title: const Text('Sincroniza con Anilist'),
      content: Text(
        'Conecta tu cuenta de Anilist para mantener tu lista de anime y manga '
        'sincronizada automáticamente.\n\n'
        'También puedes hacerlo más tarde desde Ajustes.',
        style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('skip'),
          child: const Text('No, gracias'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.login, size: 18),
          label: const Text('Conectar Anilist'),
          onPressed: () => Navigator.of(context).pop('connect'),
        ),
      ],
    );
  }
}

class _AddToLibrarySheet extends StatefulWidget {
  const _AddToLibrarySheet({required this.item, required this.kind});
  final Map<String, dynamic> item;
  final MediaKind kind;

  @override
  State<_AddToLibrarySheet> createState() => _AddToLibrarySheetState();
}

class _AddToLibrarySheetState extends State<_AddToLibrarySheet> {
  String _status = 'PLANNING';
  double _score = 0;
  final _progressCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  bool get _isManga => widget.kind == MediaKind.manga;

  List<(String, String, IconData)> get _statuses =>
      _isManga ? _mangaStatuses : _anilistStatuses;

  int? get _totalCount => _isManga
      ? widget.item['chapters'] as int?
      : widget.item['episodes'] as int?;

  String get _countLabel => _isManga ? 'Capítulos' : 'Episodios';

  @override
  void dispose() {
    _progressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = widget.item['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Añadir a tu lista',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // Status
              Text('Estado', style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statuses.map((s) {
                  final selected = _status == s.$1;
                  return ChoiceChip(
                    selected: selected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.$3, size: 16),
                        const SizedBox(width: 4),
                        Text(s.$2),
                      ],
                    ),
                    onSelected: (_) => setState(() => _status = s.$1),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Score (0-10 slider)
              Row(
                children: [
                  Text('Nota', style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  )),
                  const Spacer(),
                  Text(
                    _score == 0 ? '—' : '${_score.round()}/10',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _score > 0 ? Colors.amber.shade600 : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _score,
                min: 0,
                max: 10,
                divisions: 10,
                label: _score == 0 ? 'Sin nota' : '${_score.round()}',
                onChanged: (v) => setState(() => _score = v),
              ),
              const SizedBox(height: 12),

              // Progress
              Row(
                children: [
                  Text(_countLabel, style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  )),
                  const Spacer(),
                  if (_totalCount != null)
                    Text(
                      'de $_totalCount',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      final current = int.tryParse(_progressCtrl.text) ?? 0;
                      if (current > 0) {
                        _progressCtrl.text = '${current - 1}';
                      }
                    },
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _progressCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      final current = int.tryParse(_progressCtrl.text) ?? 0;
                      final max = _totalCount;
                      if (max == null || current < max) {
                        _progressCtrl.text = '${current + 1}';
                      }
                    },
                  ),
                  if (_totalCount != null) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _progressCtrl.text = '$_totalCount';
                        setState(() => _status = 'COMPLETED');
                      },
                      child: const Text('Máx', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              Text('Notas', style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              )),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Notas personales (opcional)...',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar'),
                  onPressed: () {
                    final progress = int.tryParse(_progressCtrl.text);
                    final notes = _notesCtrl.text.trim();
                    Navigator.of(context).pop(_AddResult(
                      status: _status,
                      score: _score > 0 ? _score.round() : null,
                      progress: progress != null && progress > 0 ? progress : null,
                      notes: notes.isNotEmpty ? notes : null,
                    ));
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
