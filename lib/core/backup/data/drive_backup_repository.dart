import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:cronicle/core/backup/domain/backup_repository.dart';
import 'package:cronicle/core/errors/app_failure.dart';

class DriveBackupRepository implements BackupRepository {
  DriveBackupRepository(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  static const String noDriveBackupFailureMessage = 'No backup found';

  static const _fileName = 'cronicle_backup.json';
  static const _driveScopes = [
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  Future<drive.DriveApi?> _getDriveApi({bool allowAuthorize = true}) async {
    final authClient = _googleSignIn.authorizationClient;
    var authorization = await authClient.authorizationForScopes(_driveScopes);
    if (authorization == null && allowAuthorize) {
      authorization = await authClient.authorizeScopes(_driveScopes);
    }
    if (authorization == null) return null;
    final client = authorization.authClient(scopes: _driveScopes);
    return drive.DriveApi(client);
  }

  Future<AppResult<Unit>> _uploadWithApi(
    drive.DriveApi driveApi,
    Uint8List data,
  ) async {
    final existing = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName'",
      $fields: 'files(id)',
    );

    final media = drive.Media(Stream.value(data), data.length);

    if (existing.files != null && existing.files!.isNotEmpty) {
      await driveApi.files.update(
        drive.File(),
        existing.files!.first.id!,
        uploadMedia: media,
      );
    } else {
      final file = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder'];
      await driveApi.files.create(file, uploadMedia: media);
    }

    return right(unit);
  }

  Future<AppResult<Unit>> uploadBackupWithoutUserInteraction(
    Uint8List data,
  ) async {
    try {
      final driveApi = await _getDriveApi(allowAuthorize: false);
      if (driveApi == null) {
        return left(const GoogleDriveFailure('Not authenticated with Google'));
      }
      return _uploadWithApi(driveApi, data);
    } catch (e) {
      return left(GoogleDriveFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<Unit>> uploadBackup(Uint8List data) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return left(const GoogleDriveFailure('Not authenticated with Google'));
      }
      return _uploadWithApi(driveApi, data);
    } catch (e) {
      return left(GoogleDriveFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<Uint8List>> downloadBackup() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return left(const GoogleDriveFailure('Not authenticated with Google'));
      }

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_fileName'",
        $fields: 'files(id)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return left(
          GoogleDriveFailure(noDriveBackupFailureMessage),
        );
      }

      final response = await driveApi.files.get(
        fileList.files!.first.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }
      return right(Uint8List.fromList(bytes));
    } catch (e) {
      return left(GoogleDriveFailure(e.toString()));
    }
  }
}
