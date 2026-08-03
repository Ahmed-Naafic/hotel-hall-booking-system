import 'package:flutter_test/flutter_test.dart';

import 'package:customer_mobile/main.dart';

void main() {
  testWidgets('CustomerMobileApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const CustomerMobileApp());

    expect(find.text('Customer Mobile'), findsOneWidget);
  });
}
