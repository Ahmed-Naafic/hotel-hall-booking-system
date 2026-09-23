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
  /// `fullName` is required by the backend when `accountType` is
  /// `CUSTOMER` (BDR-018) and ignored otherwise — omitted from the request
  /// body entirely when `null` rather than sent as an empty/absent field.
  Future<AppUser> register({
    required String mobileNumber,
    required String password,
    required String accountType,
    String? fullName,
  }) async {
    final data = await _client.post('/auth/register', body: {
      'mobileNumber': mobileNumber,
      'password': password,
      'accountType': accountType,
      if (fullName != null) 'fullName': fullName,
    });
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /auth/login` — C4, H7, A1.
  ///
  /// Returns `null` when the backend answered with a texted code instead of
  /// a session: a Customer or Hotel Manager owes that code before any token
  /// exists, and [completeLogin] is what exchanges it. An account that signs
  /// in without one (a Platform Administrator) gets its session here.
  Future<({String accessToken, String refreshToken, AppUser user})?> login({
    required String mobileNumber,
    required String password,
  }) async {
    final data = await _client.post('/auth/login', body: {
      'mobileNumber': mobileNumber,
      'password': password,
    }) as Map<String, dynamic>;
    if (data['verificationRequired'] == true) return null;
    return _session(data);
  }

  /// `POST /auth/login/verify` — exchanges the texted code for a session.
  /// Unauthenticated: the first step deliberately issued no token, so the
  /// mobile number is what says who is signing in.
  Future<({String accessToken, String refreshToken, AppUser user})> completeLogin({
    required String mobileNumber,
    required String code,
  }) async {
    final data = await _client.post('/auth/login/verify', body: {
      'mobileNumber': mobileNumber,
      'code': code,
    }) as Map<String, dynamic>;
    return _session(data);
  }

  ({String accessToken, String refreshToken, AppUser user}) _session(Map<String, dynamic> data) => (
    accessToken: data['accessToken'] as String,
    refreshToken: data['refreshToken'] as String,
    user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
  );

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

  /// `POST /auth/password-resets` — C6, BR-AUTH-09. Texts a reset code to
  /// the account's mobile number if one exists; the backend replies with the
  /// same success message either way, so this never reveals whether the
  /// number is registered.
  Future<void> requestPasswordReset(String mobileNumber) =>
      _client.post('/auth/password-resets', body: {'mobileNumber': mobileNumber});

  /// `PATCH /auth/password-resets` — C6, BR-AUTH-09. Unauthenticated by
  /// necessity, like [completeLogin]: there is no session yet to prove who
  /// this is, only the number the code was texted to.
  Future<void> confirmPasswordReset({
    required String mobileNumber,
    required String code,
    required String newPassword,
  }) => _client.patch('/auth/password-resets', body: {
    'mobileNumber': mobileNumber,
    'code': code,
    'newPassword': newPassword,
  });
}
