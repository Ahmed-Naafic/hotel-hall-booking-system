import '../api/api_client.dart';
import 'app_user.dart';

/// One function per `Authentication` endpoint actually implemented
/// (`openapi.json`) — no endpoint invented, no endpoint skipped that this
/// package's screens need. Pure request/response translation; no session
/// state lives here (`AuthController` owns that).
class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  /// `POST /auth/register` — C2, H1, BR-AUTH-02/03. Only `CUSTOMER` and
  /// `HOTEL_MANAGER` are self-registerable (authentication.validation.js).
  Future<AppUser> register({
    required String mobileNumber,
    required String password,
    required String accountType,
  }) async {
    final data = await _client.post('/auth/register', body: {
      'mobileNumber': mobileNumber,
      'password': password,
      'accountType': accountType,
    });
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /auth/login` — C4, H7, A1.
  Future<({String accessToken, String refreshToken, AppUser user})> login({
    required String mobileNumber,
    required String password,
  }) async {
    final data = await _client.post('/auth/login', body: {
      'mobileNumber': mobileNumber,
      'password': password,
    }) as Map<String, dynamic>;
    return (
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// `POST /auth/logout` — C5, A2, BR-AUTH-13. Requires the caller's own
  /// access token (already attached by `ApiClient`'s token provider).
  Future<void> logout() => _client.post('/auth/logout');

  /// `GET /auth/me` — C8. Used to restore a session on app start and to
  /// refresh the cached user (e.g. after verification).
  Future<AppUser> getCurrentUser() async {
    final data = await _client.get('/auth/me');
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /auth/verifications` — C3, BR-AUTH-02. Requests a new
  /// verification code; also used for "resend code."
  Future<void> requestVerification() => _client.post('/auth/verifications');

  /// `POST /auth/verifications/confirm` — C3, BR-AUTH-02.
  Future<AppUser> confirmVerification(String code) async {
    final data = await _client.post('/auth/verifications/confirm', body: {'code': code});
    return AppUser.fromJson(data as Map<String, dynamic>);
  }
}
