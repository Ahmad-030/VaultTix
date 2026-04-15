// lib/utils/auto_lock_manager.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import '../services/encryption_service.dart';

class AutoLockManager with WidgetsBindingObserver {
  Timer? _lockTimer;
  final VoidCallback onLock;
  bool _isEnabled = true;

  AutoLockManager({required this.onLock}) {
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final duration = await EncryptionService.getAutoLockDuration();
    _isEnabled = duration >= 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _scheduleAutoLock();
        break;
      case AppLifecycleState.resumed:
        _cancelAutoLock();
        break;
      default:
        break;
    }
  }

  Future<void> _scheduleAutoLock() async {
    final duration = await EncryptionService.getAutoLockDuration();
    if (duration == 0) {
      onLock();
      return;
    }
    _lockTimer?.cancel();
    _lockTimer = Timer(Duration(seconds: duration), onLock);
  }

  void _cancelAutoLock() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }

  void resetTimer() {
    _cancelAutoLock();
  }

  void dispose() {
    _lockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
