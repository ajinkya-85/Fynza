import 'dart:io';
import 'package:flutter/services.dart';

import '../../domain/models/raw_notification.dart';
import '../../domain/services/capture_services.dart';

abstract class NotificationCaptureService implements CapturePermissionService {
  Future<List<RawNotification>> drain();
  @override
  Future<bool> isPermissionGranted();
  @override
  Future<bool> openPermissionSettings();
}

class NotificationCaptureServiceImpl implements NotificationCaptureService {
  static const MethodChannel _channel = MethodChannel(
    'io.fynza.app/auto_capture',
  );

  @override
  Future<List<RawNotification>> drain() async {
    if (!Platform.isAndroid) return [];

    try {
      final List<dynamic>? rawList = await _channel.invokeMethod<List<dynamic>>(
        'drainQueue',
      );
      if (rawList == null || rawList.isEmpty) return [];

      return rawList
          .map(
            (item) =>
                RawNotification.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on PlatformException {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'isNotificationListenerGranted',
      );
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openPermissionSettings() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'openNotificationListenerSettings',
      );
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
