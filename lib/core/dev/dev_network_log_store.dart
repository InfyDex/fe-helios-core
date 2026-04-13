import 'package:flutter/foundation.dart';

import 'dev_network_call.dart';

/// In-memory ring buffer of HTTP calls for the debug dev menu.
///
/// Wired only in [kDebugMode] today; later a remote flag can attach the same
/// store for specific users without changing call sites.
class DevNetworkLogStore extends ChangeNotifier {
  DevNetworkLogStore({this.maxEntries = 200});

  final int maxEntries;
  final List<DevNetworkCall> _calls = [];
  int _nextId = 1;

  List<DevNetworkCall> get calls => List.unmodifiable(_calls);

  void add(DevNetworkCall call) {
    _calls.add(call);
    while (_calls.length > maxEntries) {
      _calls.removeAt(0);
    }
    notifyListeners();
  }

  void clear() {
    _calls.clear();
    notifyListeners();
  }

  int allocateId() => _nextId++;
}
