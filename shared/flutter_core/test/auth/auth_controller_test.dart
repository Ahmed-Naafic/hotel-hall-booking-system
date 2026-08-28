import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'in_memory_token_storage.dart';

Map<String, dynamic> _user({bool isVerified = false}) => {
      'id': 'u1',
      'mobileNumber': '+15551234567',
      'accountType': 'CUSTOMER',
      'isVerified': isVerified,
      'isActive': true,
    };

http.Response _success(Object data, {int status = 200}) =>
    http.Response(jsonEncode({'status': 'success', 'message': 'ok', 'data': data}), status);

http.Response _error(String error, String message, int status) => http.Response(
      jsonEncode({'status': 'error', 'error': error, 'message': message, 'timestamp': '', 'requestId': 'r'}),
      status,
    );

AuthController _buildController(Future<http.Response> Function(http.Request) handler) {
  final storage = InMemoryTokenStorage();
  final sessionStore = SessionStore(storage: storage);
  final client = ApiClient(
    httpClient: MockClient(handler),
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => sessionStore.accessToken,
  );
  return AuthController(repository: AuthRepository(client), sessionStore: sessionStore);
}

void main() {
  group('AuthController.restoreSession', () {
    test('no stored token -> unauthenticated, no API call made', () async {
      var called = false;
      final controller = _buildController((request) async {
        called = true;
        return _success({});
      });

      await controller.restoreSession();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(called, false);
    });
  });

  group('AuthController.login', () {
    test('success sets authenticated status and currentUser', () async {
      final controller = _buildController((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _success({'accessToken': 'a', 'refreshToken': 'b', 'user': _user()});
        }
        throw StateError('unexpected call: ${request.url.path}');
      });

      final result = await controller.login(mobileNumber: '+15551234567', password: 'password123');

      expect(result, true);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.currentUser?.mobileNumber, '+15551234567');
      expect(controller.isBusy, false);
      expect(controller.errorMessage, isNull);
    });

    test('invalid credentials sets errorMessage from the server, never authenticated', () async {
      final controller = _buildController((request) async => _error('AUTHENTICATION_ERROR', 'Invalid credentials.', 401));

      final result = await controller.login(mobileNumber: '+15551234567', password: 'wrong');

      expect(result, false);
      expect(controller.status, isNot(AuthStatus.authenticated));
      expect(controller.errorMessage, 'Invalid credentials.');
    });

    test('a deactivated account shows the distinct inactive-account message (BR-AUTH-06)', () async {
      final controller = _buildController((request) async => _error('AUTHENTICATION_ERROR', 'This account is inactive.', 401));

      final result = await controller.login(mobileNumber: '+15551234567', password: 'password123');

      expect(result, false);
      expect(controller.errorMessage, 'This account is inactive.');
    });
  });

  group('AuthController.registerAndRequestVerification', () {
    test('registers, logs in, and requests a verification code with the new session\'s token', () async {
      final calls = <String>[];
      final controller = _buildController((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/auth/register')) {
          return _success(_user(), status: 201);
        }
        if (request.url.path.endsWith('/auth/login')) {
          return _success({'accessToken': 'tok', 'refreshToken': 'ref', 'user': _user()});
        }
        if (request.url.path.endsWith('/auth/verifications')) {
          expect(request.headers['Authorization'], 'Bearer tok');
          return _success({});
        }
        throw StateError('unexpected call: ${request.url.path}');
      });

      final result = await controller.registerAndRequestVerification(
        mobileNumber: '+15551234567',
        password: 'password123',
        accountType: 'CUSTOMER',
      );

      expect(result, true);
      expect(calls, [
        'POST /api/v1/auth/register',
        'POST /api/v1/auth/login',
        'POST /api/v1/auth/verifications',
      ]);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.currentUser?.isVerified, false);
    });
  });

  group('AuthController.confirmVerification', () {
    test('success updates currentUser.isVerified to true', () async {
      final controller = _buildController((request) async {
        if (request.url.path.endsWith('/auth/verifications/confirm')) {
          expect(jsonDecode(request.body), {'code': '482913'});
          return _success(_user(isVerified: true));
        }
        throw StateError('unexpected call: ${request.url.path}');
      });

      final result = await controller.confirmVerification('482913');

      expect(result, true);
      expect(controller.currentUser?.isVerified, true);
    });
  });

  group('AuthController.logout', () {
    test('clears session state even if the network call fails', () async {
      final storage = InMemoryTokenStorage();
      await storage.write('hh_access_token', 'tok');
      final sessionStore = SessionStore(storage: storage);
      final client = ApiClient(
        httpClient: MockClient((request) async => throw Exception('network down')),
        baseUrl: 'http://test/api/v1',
        accessTokenProvider: () => sessionStore.accessToken,
      );
      final controller = AuthController(repository: AuthRepository(client), sessionStore: sessionStore)
        ..currentUser = AppUser.fromJson(_user())
        ..status = AuthStatus.authenticated;

      await controller.logout();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.currentUser, isNull);
      expect(await storage.read('hh_access_token'), isNull);
    });
  });
}
