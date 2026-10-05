import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityService() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _poll;

  bool _online = true; // optimistic, avoids a flash on startup
  bool _checking = false;

  bool get isOnline => _online;
  bool get isChecking => _checking;

  Future<void> _init() async {
    await check();
    _sub = _connectivity.onConnectivityChanged.listen((_) => check());
    // Catches "connected to Wi-Fi but no internet", which has no event.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => check());
  }

  /// Returns true if the internet is reachable.
  /// [manual] shows the loading state on the Retry button.
  Future<bool> check({bool manual = false}) async {
    if (_checking) return _online;

    if (manual) {
      _checking = true;
      notifyListeners();
    }

    final result = await _hasInternet();

    _checking = false;
    if (result != _online || manual) {
      _online = result;
      notifyListeners();
    }
    return _online;
  }

  Future<bool> _hasInternet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) return false;

      final lookup = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    super.dispose();
  }
}