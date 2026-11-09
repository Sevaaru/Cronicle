import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart';

Widget buildGoogleWebButton(BuildContext context) {
  try {
    return renderButton();
  } catch (_) {
    return const Text('Google Sign-In not available');
  }
}
