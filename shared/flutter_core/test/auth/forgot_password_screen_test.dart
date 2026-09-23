import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

http.Response _success(Object data, {int status = 200}) =>
    http.Response(jsonEncode({'status': 'success', 'message': 'ok', 'data': data}), status);

http.Response _error(String error, String message, int status) => http.Response(
      jsonEncode({'status': 'error', 'error': error, 'message': message, 'timestamp': '', 'requestId': 'r'}),
      status,
    );

AuthRepository _repository(Future<http.Response> Function(http.Request) handler) =>
    AuthRepository(ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1'));

void main() {
  testWidgets('requesting a code moves to the confirm step, showing the number it was sent to', (tester) async {
    final repository = _repository((request) async {
      if (request.method == 'POST' && request.url.path.endsWith('/auth/password-resets')) {
        return _success({});
      }
      throw StateError('unexpected: ${request.method} ${request.url.path}');
    });

    await tester.pumpWidget(MaterialApp(home: ForgotPasswordScreen(repository: repository)));
    await tester.enterText(find.byType(TextFormField).first, '619690404');
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();

    expect(find.textContaining('We sent a code to 619690404'), findsOneWidget);
  });

  testWidgets('a request failure shows the server error and stays on the request step', (tester) async {
    final repository = _repository(
      (request) async => _error('VALIDATION_ERROR', 'Invalid input.', 400),
    );

    await tester.pumpWidget(MaterialApp(home: ForgotPasswordScreen(repository: repository)));
    await tester.enterText(find.byType(TextFormField).first, '619690404');
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid input.'), findsOneWidget);
    expect(find.text('Send reset code'), findsOneWidget);
  });

  testWidgets('confirming with a valid code and password pops the screen with true', (tester) async {
    final repository = _repository((request) async {
      if (request.method == 'POST') return _success({});
      if (request.method == 'PATCH') {
        expect(jsonDecode(request.body), {
          'mobileNumber': '619690404',
          'code': '482913',
          'newPassword': 'newpassword123',
        });
        return _success({});
      }
      throw StateError('unexpected: ${request.method} ${request.url.path}');
    });

    bool? poppedWith;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            poppedWith = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => ForgotPasswordScreen(repository: repository)),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '619690404');
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '482913');
    await tester.enterText(find.byType(TextFormField).at(1), 'newpassword123');
    await tester.tap(find.text('Confirm reset'));
    await tester.pumpAndSettle();

    expect(poppedWith, isTrue);
  });

  testWidgets('an invalid code shows the server error and stays on the confirm step', (tester) async {
    final repository = _repository((request) async {
      if (request.method == 'POST') return _success({});
      return _error('VALIDATION_ERROR', 'This code is invalid or expired.', 422);
    });

    await tester.pumpWidget(MaterialApp(home: ForgotPasswordScreen(repository: repository)));
    await tester.enterText(find.byType(TextFormField).first, '619690404');
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '000000');
    await tester.enterText(find.byType(TextFormField).at(1), 'newpassword123');
    await tester.tap(find.text('Confirm reset'));
    await tester.pumpAndSettle();

    expect(find.text('This code is invalid or expired.'), findsOneWidget);
  });

  testWidgets('"Use a different number" returns to the request step', (tester) async {
    final repository = _repository((request) async => _success({}));

    await tester.pumpWidget(MaterialApp(home: ForgotPasswordScreen(repository: repository)));
    await tester.enterText(find.byType(TextFormField).first, '619690404');
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use a different number'));
    await tester.pumpAndSettle();

    expect(find.text('Send reset code'), findsOneWidget);
  });
}
