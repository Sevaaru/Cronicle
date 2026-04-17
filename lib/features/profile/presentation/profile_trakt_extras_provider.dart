import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';

part 'profile_trakt_extras_provider.g.dart';

/// Estadísticas Trakt del perfil (API). Los favoritos de cine/series en la app
/// viven en [favoriteTraktTitlesProvider] (corazón en detalle), no en la API
/// `/users/.../favorites` de Trakt.
class ProfileTraktExtras {
  const ProfileTraktExtras({required this.stats});

  final Map<String, dynamic> stats;
}

@riverpod
Future<ProfileTraktExtras?> profileTraktExtras(ProfileTraktExtrasRef ref) async {
  final session = await ref.watch(traktSessionProvider.future);
  if (!session.connected || (session.userSlug ?? '').isEmpty) {
    return null;
  }
  final api = ref.watch(traktApiProvider);
  final slug = session.userSlug!;
  try {
    final stats = await api.fetchUserStats(slug);
    return ProfileTraktExtras(stats: stats);
  } catch (_) {
    return const ProfileTraktExtras(stats: {});
  }
}
