import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key-value seam `SessionStore` depends on, so tests can supply an
/// in-memory implementation instead of touching the real secure-storage
/// platform channel.
abstract class TokenStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Persists the access/refresh token pair in OS-level secure storage
/// (Keychain/Keystore) — never `SharedPreferences` (plaintext), never
/// stored beyond what session restoration actually needs (no profile data
/// cached here; `AuthController` re-fetches the current user via `GET
/// /auth/me` on restore).
class SessionStore {
  SessionStore({TokenStorage? storage}) : _storage = storage ?? const SecureTokenStorage();

  final TokenStorage _storage;

  static const _accessTokenKey = 'hh_access_token';
  static const _refreshTokenKey = 'hh_refresh_token';

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await _storage.write(_accessTokenKey, accessToken);
    await _storage.write(_refreshTokenKey, refreshToken);
  }

  Future<String?> get accessToken => _storage.read(_accessTokenKey);
  Future<String?> get refreshToken => _storage.read(_refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(_accessTokenKey);
    await _storage.delete(_refreshTokenKey);
  }
}
