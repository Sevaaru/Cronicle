import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';

@immutable
class ResolvedProfileAvatar {
  const ResolvedProfileAvatar({
    this.networkUrl,
    this.memoryBytes,
    this.isLoadingPreferred = false,
  });

  final String? networkUrl;
  final Uint8List? memoryBytes;
  final bool isLoadingPreferred;

  bool get hasImage =>
      (networkUrl != null && networkUrl!.trim().isNotEmpty) ||
      (memoryBytes != null && memoryBytes!.isNotEmpty);
}

final resolvedProfileAvatarProvider = Provider<ResolvedProfileAvatar>((ref) {
  final source = ref.watch(profileAvatarSourceSettingProvider);
  final localBytes = ref.watch(localProfileAvatarProvider);

  final tokenAsync = ref.watch(anilistTokenProvider);
  final profileAsync = ref.watch(anilistProfileProvider);
  final traktAsync = ref.watch(traktSessionProvider);

  final anilistAvatar = ((profileAsync.valueOrNull?['avatar'] as Map?)?['large'] as String?)?.trim();
  final traktAvatar = (traktAsync.valueOrNull?.userAvatarUrl ?? '').trim();

  String? fallbackNetwork() {
    if (anilistAvatar != null && anilistAvatar.isNotEmpty) return anilistAvatar;
    if (traktAvatar.isNotEmpty) return traktAvatar;
    return null;
  }

  switch (source) {
    case ProfileAvatarSource.local:
      if (localBytes != null && localBytes.isNotEmpty) {
        return ResolvedProfileAvatar(memoryBytes: localBytes);
      }
      return ResolvedProfileAvatar(networkUrl: fallbackNetwork());

    case ProfileAvatarSource.anilist:
      if (tokenAsync.isLoading) {
        return const ResolvedProfileAvatar(isLoadingPreferred: true);
      }
      final hasAnilistToken = tokenAsync.valueOrNull != null;
      if (hasAnilistToken) {
        if (anilistAvatar != null && anilistAvatar.isNotEmpty) {
          return ResolvedProfileAvatar(networkUrl: anilistAvatar);
        }
        if (profileAsync.isLoading) {
          return const ResolvedProfileAvatar(isLoadingPreferred: true);
        }
      }
      if (traktAvatar.isNotEmpty) {
        return ResolvedProfileAvatar(networkUrl: traktAvatar);
      }
      if (localBytes != null && localBytes.isNotEmpty) {
        return ResolvedProfileAvatar(memoryBytes: localBytes);
      }
      return const ResolvedProfileAvatar();

    case ProfileAvatarSource.trakt:
      if (traktAvatar.isNotEmpty) {
        return ResolvedProfileAvatar(networkUrl: traktAvatar);
      }
      if (anilistAvatar != null && anilistAvatar.isNotEmpty) {
        return ResolvedProfileAvatar(networkUrl: anilistAvatar);
      }
      if (localBytes != null && localBytes.isNotEmpty) {
        return ResolvedProfileAvatar(memoryBytes: localBytes);
      }
      return const ResolvedProfileAvatar();
  }
});
