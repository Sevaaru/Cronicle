import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> get hasConnection async {
    final result = await _connectivity.checkConnectivity();
    if (result.isEmpty) return true;
    return !result.contains(ConnectivityResult.none);
  }
}

@Riverpod(keepAlive: true)
Connectivity connectivityRaw(ConnectivityRawRef ref) => Connectivity();

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(ConnectivityServiceRef ref) {
  return ConnectivityService(ref.watch(connectivityRawProvider));
}
