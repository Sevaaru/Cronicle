import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/features/games/data/datasources/opencritic_api_datasource.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';

part 'opencritic_providers.g.dart';

@Riverpod(keepAlive: true)
OpenCriticApiDatasource openCriticApi(OpenCriticApiRef ref) {
  return OpenCriticApiDatasource(ref.watch(dioProvider));
}

@riverpod
Future<OpenCriticGameInsights?> openCriticGameInsights(
  OpenCriticGameInsightsRef ref,
  int igdbGameId,
) async {
  if (EnvConfig.openCriticRapidApiKey.isEmpty) return null;
  final game = await ref.watch(igdbGameDetailProvider(igdbGameId).future);
  if (game == null) return null;
  final title = game['title'];
  final english = title is Map<String, dynamic>
      ? title['english'] as String?
      : null;
  final name = (english != null && english.trim().isNotEmpty)
      ? english.trim()
      : (game['name'] as String?)?.trim() ?? '';
  if (name.isEmpty) return null;

  final api = ref.read(openCriticApiProvider);
  if (!api.isConfigured) return null;
  try {
    return await api.fetchInsightsForTitle(name);
  } catch (_) {
    return null;
  }
}
