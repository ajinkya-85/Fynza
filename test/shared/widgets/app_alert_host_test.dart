import 'package:fynza/shared/providers/app_alert_provider.dart';
import 'package:fynza/shared/widgets/app_alert_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows grouped updates and runs an alert action', (tester) async {
    var actionCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => Stack(
            fit: StackFit.expand,
            children: [child ?? const SizedBox.shrink(), const AppAlertHost()],
          ),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () {
                  ref
                      .read(appAlertProvider.notifier)
                      .show(
                        'Transaction dismissed',
                        actionLabel: 'Undo',
                        onAction: () => actionCalled = true,
                      );
                  ref
                      .read(appAlertProvider.notifier)
                      .show('Backup created', tone: AppAlertTone.success);
                },
                child: const Text('Show updates'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show updates'));
    await tester.pump();

    expect(find.text('Updates'), findsOneWidget);
    expect(find.text('Transaction dismissed'), findsOneWidget);
    expect(find.text('Backup created'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();

    expect(actionCalled, isTrue);
    expect(find.text('Transaction dismissed'), findsNothing);
    expect(find.text('Backup created'), findsOneWidget);
  });
}
