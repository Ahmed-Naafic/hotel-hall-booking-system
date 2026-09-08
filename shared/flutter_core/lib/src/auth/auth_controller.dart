import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import 'app_user.dart';
import 'auth_repository.dart';
import 'session_store.dart';

enum AuthStatus {
  /// Session restoration in progress (app start) — show a splash/loading state.
  unknown,
  unauthenticated,
  authenticated,
}

/// Owns authentication session state for one app (Customer or Hotel
/// Manager) — a `ChangeNotifier` consumed via `provider`
/// (`ChangeNotifierProvider`), the shared state-management choice both
/// apps use (no second framework introduced). Both apps construct their
/// own instance (each has its own session), sharing only this class's
/// implementation, per FE-06's "shares FE-03/FE-04's components... not
/// rebuilt from scratch."
///
/// Verification status is never modeled as a separate `AuthStatus` value —
/// it is read directly from `currentUser.isVerified` (the real API field,
/// `PublicUser`), never invented as a client-side lifecycle state
/// (Business Specification §5.1 vs. the actual `isActive`/`isVerified`
/// flags this module's Technical Design implements).
class AuthController extends ChangeNotifier {
  AuthController({required this.repository, required this.sessionStore});

  final AuthRepository repository;
  final SessionStore sessionStore;

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  bool isBusy = false;
  String? errorMessage;

  /// Called once at app start (`main.dart`) — restores a session from
  /// secure storage, if one exists, by re-fetching the current user
  /// (`GET /auth/me`) rather than trusting a possibly-stale cached copy.
  Future<void> restoreSession() async {
    final token = await sessionStore.accessToken;
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      currentUser = await repository.getCurrentUser();
      status = AuthStatus.authenticated;
    } on ApiException {
      // Expired/invalid session (BR-AUTH-11) — treat as unauthenticated,
      // never show an error for this background check.
      await sessionStore.clear();
      status = AuthStatus.unauthenticated;
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Register (C2/H1), then log in with the same credentials and request a
  /// verification code — the actual chained flow the implemented API
  /// requires (`register` alone issues no token; verification endpoints
  /// require authentication). Returns `true` on success.
  Future<bool> registerAndRequestVerification({
    required String mobileNumber,
    required String password,
    required String accountType,
    String? fullName,
  }) => _run(() async {
    await repository.register(
      mobileNumber: mobileNumber,
      password: password,
      accountType: accountType,
      fullName: fullName,
    );
    await _authenticate(mobileNumber: mobileNumber, password: password);
    await repository.requestVerification();
  });

  /// `POST /auth/login` — C4, H7, A1.
  Future<bool> login({
    required String mobileNumber,
    required String password,
  }) =>
      _run(() => _authenticate(mobileNumber: mobileNumber, password: password));

  Future<void> _authenticate({
    required String mobileNumber,
    required String password,
  }) async {
    final result = await repository.login(
      mobileNumber: mobileNumber,
      password: password,
    );
    await sessionStore.save(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    currentUser = result.user;
    status = AuthStatus.authenticated;
  }

  /// `POST /auth/verifications` — resend, reusing the same request the
  /// initial registration flow already calls.
  Future<bool> resendVerificationCode() =>
      _run(() => repository.requestVerification());

  /// `POST /auth/verifications/confirm` — C3.
  Future<bool> confirmVerification(String code) => _run(() async {
    currentUser = await repository.confirmVerification(code);
  });

  /// `POST /auth/logout` — C5, A2, BR-AUTH-13. Clears local session state
  /// regardless of the request's outcome — logout must be effective
  /// client-side even if the network call fails.
  Future<void> logout() async {
    try {
      await repository.logout();
    } catch (_) {
      // Best-effort — the session is cleared locally either way.
    }
    await sessionStore.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> expireSession() async {
    await sessionStore.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isBusy = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isBusy = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      isBusy = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
