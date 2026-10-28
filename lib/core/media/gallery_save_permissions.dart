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
  // API 29+ inserts into MediaStore without READ_MEDIA_IMAGES / READ_MEDIA_VIDEO.
  if (sdk >= 29) return true;
  var status = await Permission.storage.status;
  if (status.isGranted || status.isLimited) return true;
  status = await Permission.storage.request();
  return status.isGranted || status.isLimited;
}
