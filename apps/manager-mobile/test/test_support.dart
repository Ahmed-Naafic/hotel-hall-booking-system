import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hotel_hall_core/hotel_hall_core.dart';

/// Test double for `TokenStorage` — no platform channel, safe for plain
/// `flutter test`. Duplicated from `apps/customer-mobile`'s identical
/// helper — small enough that a dedicated shared-test-utils package isn't
/// warranted (`folder-structure.md` §5).
class InMemoryTokenStorage implements TokenStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> delete(String key) async => _values.remove(key);
}

http.Response successResponse(Object data, {int status = 200}) =>
    http.Response(jsonEncode({'status': 'success', 'message': 'ok', 'data': data}), status);

http.Response errorResponse(String error, String message, int status) => http.Response(
      jsonEncode({'status': 'error', 'error': error, 'message': message, 'timestamp': '', 'requestId': 'r'}),
      status,
    );

Map<String, dynamic> testUser({bool isVerified = true, String accountType = 'HOTEL_MANAGER'}) => {
      'id': 'u1',
      'mobileNumber': '+15559876543',
      'accountType': accountType,
      'isVerified': isVerified,
      'isActive': true,
    };
