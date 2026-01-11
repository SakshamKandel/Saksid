import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/local/database_service.dart';
import '../../data/models/listener_badge.dart';

class StatsService extends ChangeNotifier {
  final DatabaseService _db;

  // Keys
  static const String _listenTimeKey = 'total_listening_minutes';

  // State
  int _totalListeningMinutes = 0;
  ListenerBadge _currentBadge = ListenerBadge.fromListeningHours(0);

  StatsService(this._db) {
    _init();
  }

  void _init() {
    _totalListeningMinutes = _db.statsBox.get(_listenTimeKey, defaultValue: 0);
    _updateBadge();
  }

  // Getters
  int get totalMinutes => _totalListeningMinutes;
  double get totalHours => _totalListeningMinutes / 60.0;
  ListenerBadge get badge => _currentBadge;

  // Actions
  Future<void> logListeningTime(Duration duration) async {
    if (duration.inMinutes < 1) return;

    _totalListeningMinutes += duration.inMinutes;
    await _db.statsBox.put(_listenTimeKey, _totalListeningMinutes);

    _updateBadge();
  }

  void _updateBadge() {
    final hours = (_totalListeningMinutes / 60).floor();
    final newBadge = ListenerBadge.fromListeningHours(hours);

    if (newBadge.tier != _currentBadge.tier) {
      _currentBadge = newBadge;
      notifyListeners();
      // Could trigger a notification or snackbar here for "Level Up"
    } else {
      _currentBadge = newBadge;
      // Also notify for progress updates
      notifyListeners();
    }
  }

  Future<void> resetStats() async {
    _totalListeningMinutes = 0;
    await _db.statsBox.delete(_listenTimeKey);
    _updateBadge();
  }
}
