import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'package:cronicle/core/errors/app_failure.dart';

abstract class BackupRepository {
  Future<AppResult<Unit>> uploadBackup(Uint8List data);

  Future<AppResult<Uint8List>> downloadBackup();
}
