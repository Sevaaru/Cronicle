import 'package:flutter/foundation.dart';

void appDebugLog(String message) {
  if (kDebugMode) {
    debugPrint('[Cronicle] $message');
  }
}
