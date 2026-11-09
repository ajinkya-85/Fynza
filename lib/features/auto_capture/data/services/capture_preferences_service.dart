import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/currency_service.dart';
import '../../domain/models/capture_status.dart';

class CapturePreferencesService {
  static const String _keyMode = 'auto_capture_mode';
  static const String _keyMasterEnabled = 'auto_capture_master_enabled';
  static const String _keyIgnoredSenders = 'auto_capture_ignored_senders';

  final SharedPreferences _prefs;

  CapturePreferencesService(this._prefs);

  CaptureMode getMode() {
    final raw = _prefs.getString(_keyMode);
    if (raw == CaptureMode.addAutomatically.name) {
      return CaptureMode.addAutomatically;
    }
    return CaptureMode.reviewFirst;
  }

  Future<void> setMode(CaptureMode mode) async {
    await _prefs.setString(_keyMode, mode.name);
  }

  bool isMasterEnabled() {
    return _prefs.getBool(_keyMasterEnabled) ?? false;
  }

  Future<void> setMasterEnabled(bool enabled) async {
    await _prefs.setBool(_keyMasterEnabled, enabled);
  }

  List<String> getIgnoredSenders() {
    return _prefs.getStringList(_keyIgnoredSenders) ?? [];
  }

  Future<void> addIgnoredSender(String sender) async {
    final current = getIgnoredSenders().toSet();
    current.add(sender.trim().toUpperCase());
    await _prefs.setStringList(_keyIgnoredSenders, current.toList());
  }

  Future<void> removeIgnoredSender(String sender) async {
    final current = getIgnoredSenders().toSet();
    current.remove(sender.trim().toUpperCase());
    await _prefs.setStringList(_keyIgnoredSenders, current.toList());
  }

  bool isSenderIgnored(String sender) {
    final ignored = getIgnoredSenders().toSet();
    return ignored.contains(sender.trim().toUpperCase());
  }
}

final capturePreferencesServiceProvider =
    Provider<CapturePreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CapturePreferencesService(prefs);
});

final autoCaptureEnabledProvider =
    StateNotifierProvider<AutoCaptureEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(capturePreferencesServiceProvider);
  return AutoCaptureEnabledNotifier(prefs);
});

class AutoCaptureEnabledNotifier extends StateNotifier<bool> {
  final CapturePreferencesService _prefs;

  AutoCaptureEnabledNotifier(this._prefs) : super(_prefs.isMasterEnabled());

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setMasterEnabled(enabled);
    state = enabled;
  }
}
