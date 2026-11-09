import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/backup/data/drive_backup_repository.dart';
import 'package:cronicle/core/backup/domain/backup_repository.dart';
import 'package:cronicle/core/network/google_sign_in_provider.dart';

part 'backup_repository_provider.g.dart';

@Riverpod(keepAlive: true)
BackupRepository backupRepository(BackupRepositoryRef ref) {
  final googleSignIn = ref.watch(googleSignInProvider);
  return DriveBackupRepository(googleSignIn);
}
