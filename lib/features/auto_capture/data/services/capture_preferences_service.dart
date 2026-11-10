import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/capture_status.dart';
import '../../domain/services/capture_services.dart';

class CapturePreferencesService implements CapturePreferences {
  static const String _keyMode = 'auto_capture_mode';
  static const String _keyMasterEnabled = 'auto_capture_master_enabled';
  static const String _keyIgnoredSenders = 'auto_capture_ignored_senders';

  final SharedPreferences _prefs;

  CapturePreferencesService(this._prefs);

  @override
  CaptureMode getMode() {
    final raw = _prefs.getString(_keyMode);
    if (raw == CaptureMode.addAutomatically.name) {
      return CaptureMode.addAutomatically;
    }
    return CaptureMode.reviewFirst;
  }

  @override
  Future<void> setMode(CaptureMode mode) async {
    await _prefs.setString(_keyMode, mode.name);
  }

  @override
  bool isMasterEnabled() {
    return _prefs.getBool(_keyMasterEnabled) ?? false;
  }

  @override
  Future<void> setMasterEnabled(bool enabled) async {
    await _prefs.setBool(_keyMasterEnabled, enabled);
  }

  @override
  List<String> getIgnoredSenders() {
    return _prefs.getStringList(_keyIgnoredSenders) ?? [];
  }

  @override
  Future<void> addIgnoredSender(String sender) async {
    final current = getIgnoredSenders().toSet();
    current.add(sender.trim().toUpperCase());
    await _prefs.setStringList(_keyIgnoredSenders, current.toList());
  }

  @override
  Future<void> removeIgnoredSender(String sender) async {
    final current = getIgnoredSenders().toSet();
    current.remove(sender.trim().toUpperCase());
    await _prefs.setStringList(_keyIgnoredSenders, current.toList());
  }

  @override
  bool isSenderIgnored(String sender) {
    final ignored = getIgnoredSenders().toSet();
    return ignored.contains(sender.trim().toUpperCase());
  }
}

class AutoCaptureEnabledNotifier extends StateNotifier<bool>
    implements CaptureEnabledController {
  final CapturePreferencesService _prefs;

  AutoCaptureEnabledNotifier(this._prefs) : super(_prefs.isMasterEnabled());

  @override
  Future<void> setEnabled(bool enabled) async {
    await _prefs.setMasterEnabled(enabled);
    state = enabled;
  }
}
