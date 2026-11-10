import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'capture_preferences_service.dart';
import '../../domain/repositories/capture_repository.dart';
import 'notification_capture_service.dart';

const String autoCaptureTaskName = 'expense_tracker_auto_capture';
const String autoCaptureTaskType = 'auto_capture_periodic';

class AutoCaptureScheduler {
  final NotificationCaptureService _captureService;
  final CaptureRepository _repository;
  final CapturePreferencesService preferences;
  final Workmanager _workmanager;

  AutoCaptureScheduler(
    this._captureService,
    this._repository, {
    required this.preferences,
    Workmanager? workmanager,
  }) : _workmanager = workmanager ?? Workmanager();

  /// Registers periodic background drain task if on Android.
  Future<void> initialize() async {
    await registerPeriodicDrain(workmanager: _workmanager);
  }

  /// Drains pending notifications immediately and ingests them.
  Future<void> drainNow() async {
    if (!Platform.isAndroid || !preferences.isMasterEnabled()) return;

    try {
      final notifications = await _captureService.drain();
      if (notifications.isNotEmpty) {
        await _repository.ingest(notifications);
      }
    } catch (error) {
      debugPrint('Auto-capture queue drain failed: ${error.runtimeType}');
    }
  }

  /// Registers the worker from app startup without constructing a repository.
  static Future<void> registerPeriodicDrain({Workmanager? workmanager}) async {
    if (!Platform.isAndroid) return;

    try {
      await (workmanager ?? Workmanager()).registerPeriodicTask(
        autoCaptureTaskName,
        autoCaptureTaskType,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
    } catch (error) {
      debugPrint('Auto-capture task registration failed: ${error.runtimeType}');
    }
  }
}

final autoCaptureSchedulerProvider = Provider<AutoCaptureScheduler>((ref) {
  final captureService = ref.watch(notificationCaptureServiceProvider);
  final repository = ref.watch(captureRepositoryProvider);
  final preferences = ref.watch(capturePreferencesServiceProvider);
  return AutoCaptureScheduler(
    captureService,
    repository,
    preferences: preferences,
  );
});
