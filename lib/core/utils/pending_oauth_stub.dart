class PendingTraktOAuth {
  const PendingTraktOAuth({required this.code, required this.state});

  final String code;
  final String state;
}

Future<PendingTraktOAuth?> getPendingTraktOAuth() async => null;

Future<void> clearPendingTraktOAuth() async {}

Future<String?> getPendingSteamOAuthQuery() async => null;

Future<void> clearPendingSteamOAuth() async {}
