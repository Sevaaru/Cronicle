import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/connected_accounts/connected_account_kind.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/identity/data/connected_accounts_repository.dart';
import 'package:cronicle/features/identity/presentation/cronicle_auth_providers.dart';
import 'package:cronicle/features/steam/presentation/steam_providers.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';

final connectedAccountsRepositoryProvider =
    Provider<ConnectedAccountsRepository?>((ref) {
  ref.watch(cronicleAuthSessionProvider);
  return ConnectedAccountsRepository.tryCreate();
});

void schedulePushConnectedAccount(ConnectedAccountKind kind) {
  final repo = ConnectedAccountsRepository.tryCreate();
  if (repo == null) return;
  unawaited(repo.push(kind));
}

void scheduleClearConnectedAccountRemote(ConnectedAccountKind kind) {
  final repo = ConnectedAccountsRepository.tryCreate();
  if (repo == null) return;
  unawaited(repo.clearRemote(kind));
}

Future<Set<ConnectedAccountKind>> restoreConnectedAccounts(WidgetRef ref) async {
  final repo = ref.read(connectedAccountsRepositoryProvider);
  if (repo == null) return {};
  final restored = await repo.restoreMissingLocally();
  if (restored.contains(ConnectedAccountKind.anilist)) {
    ref.invalidate(anilistTokenProvider);
  }
  if (restored.contains(ConnectedAccountKind.trakt)) {
    ref.invalidate(traktSessionProvider);
  }
  if (restored.contains(ConnectedAccountKind.steam)) {
    ref.invalidate(steamSessionProvider);
  }
  if (restored.contains(ConnectedAccountKind.twitch)) {
    ref.invalidate(twitchIgdbAccountProvider);
  }
  return restored;
}
