import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppAlertTone { information, success, error }

class AppAlert {
  final int id;
  final String message;
  final AppAlertTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppAlert({
    required this.id,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
  });
}

class AppAlertController extends StateNotifier<List<AppAlert>> {
  AppAlertController() : super(const []);

  var _nextId = 0;

  void show(
    String message, {
    AppAlertTone tone = AppAlertTone.information,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final updated = [
      ...state,
      AppAlert(
        id: _nextId++,
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    ];
    state = updated.length <= 4 ? updated : updated.sublist(updated.length - 4);
  }

  void dismiss(int id) {
    state = state.where((alert) => alert.id != id).toList();
  }

  void clear() {
    state = const [];
  }
}

final appAlertProvider =
    StateNotifierProvider<AppAlertController, List<AppAlert>>(
      (ref) => AppAlertController(),
    );
