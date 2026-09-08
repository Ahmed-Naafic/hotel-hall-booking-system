import 'dart:convert';

import 'package:customer_mobile/features/customer_profile/presentation/customer_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

http.Response _envelope(dynamic data) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data}),
  200,
);

Map<String, dynamic> _meJson({String? fullName, bool hasProfile = true}) => {
  'user': {'id': 'user-1', 'mobileNumber': '+15551234567', 'accountType': 'CUSTOMER', 'isVerified': true, 'isActive': true},
  'profile': hasProfile
      ? {
          'id': 'profile-1',
          'profileData': fullName != null ? {'fullName': fullName} : {},
          'createdAt': '2026-09-08T00:00:00.000Z',
          'updatedAt': '2026-09-08T00:00:00.000Z',
        }
      : null,
  'readiness': {'profileExists': hasProfile, 'isComplete': null, 'missingRequiredFields': null},
};

Widget _wrap(MockClient httpClient) {
  final apiClient = ApiClient(httpClient: httpClient, baseUrl: 'http://test/api/v1');
  return Provider<ApiClient>.value(
    value: apiClient,
    child: const MaterialApp(home: CustomerProfileScreen()),
  );
}

void main() {
  testWidgets('shows the Customer\'s real Full Name and Mobile Number (BDR-018)', (tester) async {
    await tester.pumpWidget(_wrap(MockClient((_) async => _envelope(_meJson(fullName: 'Amina Yusuf')))));
    await tester.pumpAndSettle();

    expect(find.text('Amina Yusuf'), findsOneWidget);
    expect(find.text('+15551234567'), findsOneWidget);
    expect(find.text('Full name not set yet'), findsNothing);
    expect(find.byType(TextField), findsNothing, reason: 'no need to prompt for a name that already exists');
  });

  testWidgets('a pre-BDR-018 Customer with no profile can set their Full Name (POST)', (tester) async {
    String? capturedBody;
    String? capturedMethod;
    var reloaded = false;
    await tester.pumpWidget(_wrap(MockClient((request) async {
      if (request.method == 'POST' && request.url.path.endsWith('/customers/me/profile')) {
        capturedMethod = 'POST';
        capturedBody = request.body;
        reloaded = true;
        return _envelope({'profile': _meJson(fullName: 'Amina Yusuf')['profile'], 'readiness': _meJson(fullName: 'Amina Yusuf')['readiness']});
      }
      return _envelope(_meJson(hasProfile: false));
    })));
    await tester.pumpAndSettle();

    expect(find.text('Full name not set yet'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Amina Yusuf');
    await tester.pump();
    await tester.tap(find.text('Save name'));
    await tester.pumpAndSettle();

    expect(capturedMethod, 'POST');
    expect(capturedBody, contains('"fullName":"Amina Yusuf"'));
    expect(reloaded, true);
  });

  testWidgets('a Customer with a profile but no Full Name yet can set one (PATCH)', (tester) async {
    String? capturedMethod;
    await tester.pumpWidget(_wrap(MockClient((request) async {
      if (request.method == 'PATCH' && request.url.path.endsWith('/customers/me/profile')) {
        capturedMethod = 'PATCH';
        return _envelope({'profile': _meJson(fullName: 'Amina Yusuf')['profile'], 'readiness': _meJson(fullName: 'Amina Yusuf')['readiness']});
      }
      return _envelope(_meJson(hasProfile: true));
    })));
    await tester.pumpAndSettle();

    expect(find.text('Full name not set yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Amina Yusuf');
    await tester.pump();
    await tester.tap(find.text('Save name'));
    await tester.pumpAndSettle();

    expect(capturedMethod, 'PATCH');
  });

  testWidgets('the Save button is disabled until a non-empty name is entered', (tester) async {
    await tester.pumpWidget(_wrap(MockClient((_) async => _envelope(_meJson(hasProfile: false)))));
    await tester.pumpAndSettle();

    final buttonBefore = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(buttonBefore.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Amina Yusuf');
    await tester.pump();

    final buttonAfter = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(buttonAfter.onPressed, isNotNull);
  });
}
