import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
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

  Timer? _retryTimer;

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
    await _updateStatus(results);
    _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    final hasInterface = results.any((r) => r != ConnectivityResult.none);

    if (!hasInterface) {
      _setStatus(ConnectivityStatus.offline);
      return;
    }

    // Network interface is up — verify real internet by pinging a known host
    final hasInternet = await _checkRealConnectivity();
    _setStatus(hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline);
  }

  /// Attempt a real DNS lookup to confirm internet works.
  Future<bool> _checkRealConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('[Connectivity] Real check failed: $e');
      return false;
    }
  }

  void _setStatus(ConnectivityStatus status) {
    final changed = status != _currentStatus;
    _currentStatus = status;

    if (changed || status == ConnectivityStatus.offline) {
      _controller.add(_currentStatus);
      debugPrint('[Connectivity] Status: $_currentStatus');
    }

    // When offline (or real connectivity fails), start a retry timer.
    // When online, cancel it.
    if (status == ConnectivityStatus.offline) {
      _startRetryTimer();
    } else {
      _stopRetryTimer();
    }
  }

  /// Periodically re-check real internet every 60s while offline.
  /// Automatically stops once online is confirmed.
  void _startRetryTimer() {
    if (_retryTimer != null && _retryTimer!.isActive) return;
    debugPrint('[Connectivity] Starting 60s retry timer');
    _retryTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      debugPrint('[Connectivity] Retry: checking real connectivity...');
      final hasInternet = await _checkRealConnectivity();
      if (hasInternet) {
        _setStatus(ConnectivityStatus.online);
      } else {
        debugPrint('[Connectivity] Retry: still offline, will try again in 60s');
      }
    });
  }

  void _stopRetryTimer() {
    if (_retryTimer != null && _retryTimer!.isActive) {
      debugPrint('[Connectivity] Online confirmed, stopping retry timer');
      _retryTimer!.cancel();
      _retryTimer = null;
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _controller.close();
  }
}

/// Riverpod provider for connectivity status — always has the current value
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ConnectivityService.instance.statusStream;
});
