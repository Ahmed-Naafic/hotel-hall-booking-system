import 'dart:convert';

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

void main() {
  group('AuthRepository.requestPasswordReset', () {
    test('POSTs the mobile number to /auth/password-resets', () async {
      String? capturedMethod;
      String? capturedPath;
      Map<String, dynamic>? capturedBody;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _success({});
        }),
        baseUrl: 'http://test/api/v1',
      );

      await AuthRepository(client).requestPasswordReset('+15551234567');

      expect(capturedMethod, 'POST');
      expect(capturedPath, '/api/v1/auth/password-resets');
      expect(capturedBody, {'mobileNumber': '+15551234567'});
    });

    test('propagates a backend error as ApiException', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async => _error('VALIDATION_ERROR', 'Invalid input.', 400)),
        baseUrl: 'http://test/api/v1',
      );

      expect(
        () => AuthRepository(client).requestPasswordReset('bad'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('AuthRepository.confirmPasswordReset', () {
    test('PATCHes mobile number, code, and new password to /auth/password-resets', () async {
      String? capturedMethod;
      Map<String, dynamic>? capturedBody;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          capturedMethod = request.method;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _success({});
        }),
        baseUrl: 'http://test/api/v1',
      );

      await AuthRepository(client).confirmPasswordReset(
        mobileNumber: '+15551234567',
        code: '482913',
        newPassword: 'newpassword123',
      );

      expect(capturedMethod, 'PATCH');
      expect(capturedBody, {
        'mobileNumber': '+15551234567',
        'code': '482913',
        'newPassword': 'newpassword123',
      });
    });

    test('an expired/invalid code surfaces the server message', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async => _error('VALIDATION_ERROR', 'This code is invalid or expired.', 422)),
        baseUrl: 'http://test/api/v1',
      );

      await expectLater(
        AuthRepository(client).confirmPasswordReset(
          mobileNumber: '+15551234567',
          code: '000000',
          newPassword: 'newpassword123',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'This code is invalid or expired.'),
        ),
      );
    });
  });
}
