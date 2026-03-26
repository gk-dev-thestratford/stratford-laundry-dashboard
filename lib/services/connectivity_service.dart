import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _connectivity = Connectivity();
  // Use a regular controller + replay the last value manually for late subscribers
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.offline;
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Stream that always replays the current status to new listeners,
  /// then emits future changes.
  Stream<ConnectivityStatus> get statusStream async* {
    // Immediately yield current status so late subscribers get it
    yield _currentStatus;
    // Then forward all future changes
    yield* _controller.stream;
  }

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    final newStatus = isConnected ? ConnectivityStatus.online : ConnectivityStatus.offline;
    if (newStatus != _currentStatus || _currentStatus == ConnectivityStatus.offline) {
      _currentStatus = newStatus;
      _controller.add(_currentStatus);
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Riverpod provider for connectivity status — always has the current value
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ConnectivityService.instance.statusStream;
});
