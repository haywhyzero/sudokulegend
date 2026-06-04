import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _updateState(result);
    _connectivity.onConnectivityChanged.listen(_updateState);
  }

  void _updateState(List<ConnectivityResult> results) {
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    _connectionController.add(_isOnline);
  }

  void dispose() {
    _connectionController.close();
  }
}