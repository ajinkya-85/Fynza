import 'package:fynza/shared/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('month changes settle cleanly after rapid navigation', (
    tester,
  ) async {
    var selectedDate = DateTime(2026, 12);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MonthSelector(
              selectedDate: selectedDate,
              onPrevious: () {
                setState(() {
                  selectedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month - 1,
                  );
                });
              },
              onNext: () {
                setState(() {
                  selectedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month + 1,
                  );
                });
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('December 2026'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('January 2027'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('February 2027'), findsOneWidget);
    expect(find.text('December 2026'), findsNothing);
    expect(find.text('January 2027'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('January 2027'), findsOneWidget);
    expect(find.text('February 2027'), findsNothing);
  });
}
