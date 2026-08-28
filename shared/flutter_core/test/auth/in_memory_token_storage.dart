import 'package:hotel_hall_core/hotel_hall_core.dart';

/// Test double for `TokenStorage` — no platform channel involved, safe for
/// plain `flutter test`.
class InMemoryTokenStorage implements TokenStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> delete(String key) async => _values.remove(key);
}
