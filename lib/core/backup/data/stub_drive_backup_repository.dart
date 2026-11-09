import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cronicle/core/backup/domain/backup_repository.dart';
import 'package:cronicle/core/errors/app_failure.dart';

class StubDriveBackupRepository implements BackupRepository {
  StubDriveBackupRepository(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  GoogleSignIn get googleSignIn => _googleSignIn;

  @override
  Future<AppResult<Unit>> uploadBackup(Uint8List data) async {
    return left(const BackupNotImplementedFailure());
  }

  @override
  Future<AppResult<Uint8List>> downloadBackup() async {
    return left(const BackupNotImplementedFailure());
  }
}
