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

  // "Remember me" unchecked (Login screen) — the session must still work for
  // the rest of this run (every request reads it back through this same
  // class), it just must not survive a cold start. Kept in memory instead of
  // OS secure storage so the next launch finds nothing to restore.
  bool _persist = true;
  String? _memoryAccessToken;
  String? _memoryRefreshToken;

  /// [remember] is `null` on a token-refresh save (`ApiClient.tokenPairSaver`
  /// rotates tokens without knowing the original choice) — omitting it
  /// reuses whatever the last real login/register call decided.
  Future<void> save({required String accessToken, required String refreshToken, bool? remember}) async {
    if (remember != null) _persist = remember;
    if (_persist) {
      await _storage.write(_accessTokenKey, accessToken);
      await _storage.write(_refreshTokenKey, refreshToken);
    } else {
      _memoryAccessToken = accessToken;
      _memoryRefreshToken = refreshToken;
      // Never leave a previously-remembered session behind once this run
      // has chosen not to persist.
      await _storage.delete(_accessTokenKey);
      await _storage.delete(_refreshTokenKey);
    }
  }

  Future<String?> get accessToken => _persist ? _storage.read(_accessTokenKey) : Future.value(_memoryAccessToken);
  Future<String?> get refreshToken => _persist ? _storage.read(_refreshTokenKey) : Future.value(_memoryRefreshToken);

  Future<void> clear() async {
    _persist = true;
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    await _storage.delete(_accessTokenKey);
    await _storage.delete(_refreshTokenKey);
  }
}
