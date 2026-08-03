import 'package:flutter_test/flutter_test.dart';

import 'package:manager_mobile/main.dart';

void main() {
  testWidgets('ManagerMobileApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ManagerMobileApp());

    expect(find.text('Hotel Manager Mobile'), findsOneWidget);
  });
}
