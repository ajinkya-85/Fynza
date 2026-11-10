import '../models/capture_status.dart';

abstract interface class CapturePreferences {
  CaptureMode getMode();
  Future<void> setMode(CaptureMode mode);
  bool isMasterEnabled();
  Future<void> setMasterEnabled(bool enabled);
  List<String> getIgnoredSenders();
  Future<void> addIgnoredSender(String sender);
  Future<void> removeIgnoredSender(String sender);
  bool isSenderIgnored(String sender);
}

abstract interface class CapturePermissionService {
  Future<bool> isPermissionGranted();
  Future<bool> openPermissionSettings();
}

abstract interface class CaptureQueueDrainer {
  Future<void> drainNow();
}

abstract interface class CaptureEnabledController {
  Future<void> setEnabled(bool enabled);
}
