import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureGallerySavePermission() async {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return _ensureIos();
    case TargetPlatform.android:
      return _ensureAndroid();
    default:
      return true;
  }
}

Future<bool> _ensureIos() async {
  var status = await Permission.photosAddOnly.status;
  if (status.isGranted || status.isLimited) return true;
  status = await Permission.photosAddOnly.request();
  return status.isGranted || status.isLimited;
}

Future<bool> _ensureAndroid() async {
  final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
  final Permission perm = sdk >= 33 ? Permission.photos : Permission.storage;
  var status = await perm.status;
  if (status.isGranted || status.isLimited) return true;
  status = await perm.request();
  return status.isGranted || status.isLimited;
}
