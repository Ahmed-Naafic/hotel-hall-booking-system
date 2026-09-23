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

  /// True between proving the password and entering the texted code — the
  /// window where the backend has issued no token at all.
  ///
  /// Deliberately not a fourth [AuthStatus]: the account is simply not
  /// signed in yet, and every screen that switches on status already treats
  /// that correctly. This only tells the sign-in screens which step to show.
  bool get awaitingLoginCode => _pendingLogin != null;

  /// The number the code went to, for the "we sent a code to…" line.
  String? get pendingMobileNumber => _pendingLogin?.mobileNumber;

  /// Held only for the life of the sign-in attempt, so "Resend" can ask for
  /// a new code without making the Customer type their password again —
  /// re-running login is the only way to get one, and requiring the password
  /// is what stops the endpoint being an SMS-flood button. Cleared the
  /// moment a session exists, and on logout.
  ({String mobileNumber, String password, bool rememberMe})? _pendingLogin;

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
    // Registering never shows a "Remember me" choice — always remembered,
    // same as every session before this feature existed.
    await _authenticate(mobileNumber: mobileNumber, password: password, rememberMe: true);
  });

  /// `POST /auth/login` — C4, H7, A1. Succeeding here does not necessarily
  /// mean signed in: check [awaitingLoginCode], which is set when the
  /// backend texted a code instead of issuing a session.
  ///
  /// [rememberMe] (Login screen's own checkbox) controls whether the session
  /// survives a cold start: unchecked, the tokens stay in memory only for
  /// this run and the next launch lands back on the Login screen.
  Future<bool> login({
    required String mobileNumber,
    required String password,
    bool rememberMe = true,
  }) =>
      _run(() => _authenticate(mobileNumber: mobileNumber, password: password, rememberMe: rememberMe));

  Future<void> _authenticate({
    required String mobileNumber,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await repository.login(
      mobileNumber: mobileNumber,
      password: password,
    );
    if (result == null) {
      _pendingLogin = (mobileNumber: mobileNumber, password: password, rememberMe: rememberMe);
      return;
    }
    await _adoptSession(result, rememberMe: rememberMe);
  }

  Future<void> _adoptSession(
    ({String accessToken, String refreshToken, AppUser user}) result, {
    required bool rememberMe,
  }) async {
    await sessionStore.save(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      remember: rememberMe,
    );
    currentUser = result.user;
    status = AuthStatus.authenticated;
    _pendingLogin = null;
  }

  /// Asks for another code. Which call that is depends on where the code was
  /// owed from: signing in has no token to present, so it re-runs login;
  /// an already-signed-in account uses the C3 endpoint.
  Future<bool> resendVerificationCode() => _run(() async {
    final pending = _pendingLogin;
    if (pending != null) {
      await _authenticate(
        mobileNumber: pending.mobileNumber,
        password: pending.password,
        rememberMe: pending.rememberMe,
      );
      return;
    }
    await repository.requestVerification();
  });

  /// Confirms a texted code, from whichever flow asked for one — the two
  /// are the same code to the person typing it, so the screens do not have
  /// to know which endpoint applies.
  Future<bool> confirmVerification(String code) => _run(() async {
    final pending = _pendingLogin;
    if (pending != null) {
      await _adoptSession(
        await repository.completeLogin(mobileNumber: pending.mobileNumber, code: code),
        rememberMe: pending.rememberMe,
      );
      return;
    }
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
    // Any half-finished sign-in belongs to the session that just ended.
    _pendingLogin = null;
    notifyListeners();
  }

  Future<void> expireSession() async {
    await sessionStore.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    // Any half-finished sign-in belongs to the session that just ended.
    _pendingLogin = null;
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
