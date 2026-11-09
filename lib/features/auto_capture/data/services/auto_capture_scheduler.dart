import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../domain/repositories/capture_repository.dart';
import 'notification_capture_service.dart';

const String autoCaptureTaskName = 'expense_tracker_auto_capture';

class AutoCaptureScheduler {
  final NotificationCaptureService _captureService;
  final CaptureRepository _repository;
  final Workmanager _workmanager;

  AutoCaptureScheduler(
    this._captureService,
    this._repository, {
    Workmanager? workmanager,
  }) : _workmanager = workmanager ?? Workmanager();

  /// Registers periodic background drain task if on Android.
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      await _workmanager.registerPeriodicTask(
        autoCaptureTaskName,
        'auto_capture_periodic',
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );
    } catch (_) {}
  }

  /// Drains pending notifications immediately and ingests them.
  Future<void> drainNow() async {
    if (!Platform.isAndroid) return;

    try {
      final notifications = await _captureService.drain();
      if (notifications.isNotEmpty) {
        await _repository.ingest(notifications);
      }
    } catch (_) {}
  }
}

final autoCaptureSchedulerProvider = Provider<AutoCaptureScheduler>((ref) {
  final captureService = ref.watch(notificationCaptureServiceProvider);
  final repository = ref.watch(captureRepositoryProvider);
  return AutoCaptureScheduler(captureService, repository);
});

