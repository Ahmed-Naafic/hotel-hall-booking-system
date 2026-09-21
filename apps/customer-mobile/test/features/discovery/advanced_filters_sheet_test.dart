import 'package:customer_mobile/features/discovery/application/all_halls_controller.dart';
import 'package:customer_mobile/features/discovery/presentation/widgets/advanced_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap() => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await showAdvancedFiltersSheet(context, initial: AdvancedHallFilters.none);
            // Surface the result somewhere findable by the test.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('result:${result?.minCapacity}:${result?.minPriceCents}:${result?.maxPriceCents}:${result == null}')),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('applying valid values returns the parsed filters', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'e.g. 200'), '250');
    await tester.enterText(find.widgetWithText(TextField, 'Min'), '100');
    await tester.enterText(find.widgetWithText(TextField, 'Max'), '500');
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    expect(find.text('result:250:10000:50000:false'), findsOneWidget);
  });

  testWidgets('an empty sheet applies as no filters at all', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    expect(find.text('result:null:null:null:false'), findsOneWidget);
  });

  testWidgets('max price below min price shows an inline error and does not close', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Min'), '500');
    await tester.enterText(find.widgetWithText(TextField, 'Max'), '100');
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Max price must be at least the min price.'), findsOneWidget);
    expect(find.text('Apply Filters'), findsOneWidget);
  });

  testWidgets('tapping Reset returns AdvancedHallFilters.none', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'e.g. 200'), '250');
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('result:null:null:null:false'), findsOneWidget);
  });
}
