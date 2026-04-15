import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: kIsWeb ? 25 : 10),
      receiveTimeout: Duration(seconds: kIsWeb ? 45 : 15),
    ),
  );
  assert(() {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
    return true;
  }());
  return dio;
}
