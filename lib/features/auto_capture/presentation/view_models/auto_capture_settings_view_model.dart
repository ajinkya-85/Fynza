import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/database_provider.dart';
import '../../domain/models/capture_status.dart';
import '../../domain/repositories/capture_repository.dart';
import '../../domain/services/capture_services.dart';

class AutoCaptureSettingsState {
  final bool isMasterEnabled;
  final CaptureMode mode;
  final bool isPermissionGranted;
  final List<String> ignoredSenders;
  final bool isLoading;

  const AutoCaptureSettingsState({
    required this.isMasterEnabled,
    required this.mode,
    required this.isPermissionGranted,
    required this.ignoredSenders,
    this.isLoading = false,
  });

  AutoCaptureSettingsState copyWith({
    bool? isMasterEnabled,
    CaptureMode? mode,
    bool? isPermissionGranted,
    List<String>? ignoredSenders,
    bool? isLoading,
  }) {
    return AutoCaptureSettingsState(
      isMasterEnabled: isMasterEnabled ?? this.isMasterEnabled,
      mode: mode ?? this.mode,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      ignoredSenders: ignoredSenders ?? this.ignoredSenders,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AutoCaptureSettingsViewModel
    extends StateNotifier<AutoCaptureSettingsState> {
  final CapturePreferences _prefs;
  final CapturePermissionService _captureService;
  final CaptureRepository _repository;
  final CaptureEnabledController? _enabledNotifier;

  AutoCaptureSettingsViewModel(
    this._prefs,
    this._captureService,
    this._repository, [
    this._enabledNotifier,
  ]) : super(
         AutoCaptureSettingsState(
           isMasterEnabled: _prefs.isMasterEnabled(),
           mode: _prefs.getMode(),
           isPermissionGranted: false,
           ignoredSenders: _prefs.getIgnoredSenders(),
         ),
       ) {
    refreshPermissionStatus();
  }

  Future<void> refreshPermissionStatus() async {
    final granted = await _captureService.isPermissionGranted();
    state = state.copyWith(
      isMasterEnabled: _prefs.isMasterEnabled(),
      mode: _prefs.getMode(),
      isPermissionGranted: granted,
      ignoredSenders: _prefs.getIgnoredSenders(),
    );
  }

  Future<void> setMasterEnabled(bool enabled) async {
    if (_enabledNotifier != null) {
      await _enabledNotifier.setEnabled(enabled);
    } else {
      await _prefs.setMasterEnabled(enabled);
    }
    state = state.copyWith(isMasterEnabled: enabled);
  }

  Future<void> setMode(CaptureMode mode) async {
    await _prefs.setMode(mode);
    state = state.copyWith(mode: mode);
  }

  Future<void> removeIgnoredSender(String sender) async {
    await _prefs.removeIgnoredSender(sender);
    state = state.copyWith(ignoredSenders: _prefs.getIgnoredSenders());
  }

  Future<void> requestPermission() async {
    await _captureService.openPermissionSettings();
  }

  Future<void> deleteAllCapturedData() async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteAllCapturedData();
    state = state.copyWith(isLoading: false);
  }
}

final autoCaptureSettingsViewModelProvider =
    StateNotifierProvider.autoDispose<
      AutoCaptureSettingsViewModel,
      AutoCaptureSettingsState
    >((ref) {
      final prefs = ref.watch(capturePreferencesServiceProvider);
      final captureService = ref.watch(notificationCaptureServiceProvider);
      final repo = ref.watch(captureRepositoryProvider);
      final enabledNotifier = ref.watch(autoCaptureEnabledProvider.notifier);
      return AutoCaptureSettingsViewModel(
        prefs,
        captureService,
        repo,
        enabledNotifier,
      );
    });
