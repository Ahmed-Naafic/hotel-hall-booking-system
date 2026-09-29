import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'sync_database.dart';
import 'sync_engine.dart';
import 'sync_store.dart';

/// The Manager's on-device replica, app-wide (ADR-0009, Local-First Technical
/// Design §16).
///
/// Owns the database, the store and the engine, and decides *when* to sync:
/// on sign-in, on returning to the foreground, and when a screen asks (after a
/// command it just sent, or when it opens). Screens listen to it and re-read
/// their local rows when [revision] moves.
///
/// Properties that matter more than the rest:
///
///   - **One queue.** Every sync, wipe and ownership check runs strictly one
///     after another. A wipe can never land between two pages of a sync — which
///     would leave the engine's advanced cursor pointing past rows that were
///     just deleted, a permanent hole — and a sync can never resurrect rows a
///     wipe removed.
///   - **A sync you ask for starts after you asked.** [sync] never hands back
///     a run that was already under way (its snapshot could predate the command
///     the caller just sent); it joins a run that is queued but not started, or
///     queues a new one.
///   - **It never blocks a screen on the network.** A screen reads what is
///     local and asks for a sync; if that fails, it keeps showing what it has
///     and [lastError] says why.
///   - **It is optional.** If the database cannot be opened on this platform,
///     [ready] returns null and every reader falls back to the network.
///   - **Rows are readable only by the user they belong to.** The owner is
///     persisted with the rows. Until the signed-in user is confirmed as that
///     owner — or the replica is wiped for them — [hasSynced] answers false, so
///     no screen reads it. The replica is unencrypted (ADR-0009).
class LocalReplica extends ChangeNotifier with WidgetsBindingObserver {
  LocalReplica({
    required this.apiClient,
    Future<SyncDatabase> Function()? openDatabase,
    this.collections = managerReplicatedCollections,
  }) : _openDatabase = openDatabase ?? SyncDatabase.open;

  final ApiClient apiClient;
  final List<String> collections;
  final Future<SyncDatabase> Function() _openDatabase;

  Future<SyncDatabase?>? _opening;
  SyncStore? _store;
  SyncEngine? _engine;

  /// Moves whenever the replica's contents may have changed. Readers compare it
  /// against the value they last rendered from.
  int revision = 0;

  /// The last sync's failure, or null after a success.
  Object? lastError;

  /// The last sync could not reach the server.
  bool get isOffline => lastError is NetworkException;

  bool _disposed = false;

  /// The opened database, or null if this platform cannot provide one. Opened
  /// once; a failure is remembered rather than retried on every read.
  Future<SyncDatabase?> ready() {
    return _opening ??= () async {
      try {
        final db = await _openDatabase();
        _store = SyncStore(db);
        _engine = SyncEngine(apiClient: apiClient, store: _store!, collections: collections);
        return db;
      } catch (error) {
        debugPrint('LocalReplica unavailable, reading from the network instead: $error');
        return null;
      }
    }();
  }

  /// Whether [collection] may be read locally: the database is open, the rows
  /// belong to the signed-in user, and the collection has synced at least once
  /// — until then an empty replica would look like an empty Hotel.
  Future<bool> hasSynced(String collection) async {
    if (await ready() == null) return false;
    if (_auth != null && _activeUserId == null) return false;
    return _store!.hasSynced(collection);
  }

  /// Every row of [collection], or null when the replica may not be read for
  /// it (see [hasSynced]).
  Future<List<Map<String, dynamic>>?> readAll(String collection) async {
    if (!await hasSynced(collection)) return null;
    return _store!.all(collection);
  }

  // ---------------------------------------------------------------------------
  // The queue
  // ---------------------------------------------------------------------------

  Future<void> _tail = Future.value();

  Future<void> _enqueue(Future<void> Function() operation) {
    final run = _tail.then((_) => operation());
    // The queue must survive a failed operation, or nothing after it would run.
    _tail = run.catchError((Object _) {});
    return run;
  }

  /// A sync that is queued but has not started — the only kind a new caller
  /// may join.
  Future<void>? _queuedSync;

  /// Brings the replica up to date with a run that starts no earlier than this
  /// call. Never throws: the outcome is in [lastError], and whatever is local
  /// stays readable.
  Future<void> sync() {
    return _queuedSync ??= _enqueue(() {
      _queuedSync = null;
      return _sync();
    });
  }

  /// [sync], unless the last successful one finished within [maxAge]. For
  /// reads — a screen opening, a search re-running — which should not cost a
  /// round trip each. After a command, call [sync]: the replica is known stale.
  Future<void> syncIfStale({Duration maxAge = const Duration(seconds: 30)}) {
    final last = _lastSuccessAt;
    if (last != null && DateTime.now().difference(last) < maxAge) return Future.value();
    return sync();
  }

  DateTime? _lastSuccessAt;

  Future<void> _sync() async {
    if (await ready() == null) return;
    if (_auth != null && _activeUserId == null) return;
    try {
      final outcome = await _engine!.syncAll();
      lastError = null;
      _lastSuccessAt = DateTime.now();
      if (outcome.changedAnything) revision += 1;
    } catch (error) {
      // Anything — offline, a server error, a local database failure. A sync is
      // an optimisation of reads; it must never surface as an unhandled error.
      lastError = error;
      if (error is! ApiException && error is! NetworkException) {
        debugPrint('LocalReplica sync failed: $error');
      }
    }
    _notify();
  }

  /// Discards everything, in turn with any sync.
  Future<void> clear() => _enqueue(_wipe);

  Future<void> _wipe() async {
    if (await ready() == null) return;
    await _store!.wipe();
    lastError = null;
    _lastSuccessAt = null;
    revision += 1;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Session binding
  // ---------------------------------------------------------------------------

  AuthController? _auth;

  /// The signed-in user the replica has been confirmed to belong to, or null
  /// while nobody is — during which nothing reads it and nothing syncs it.
  String? _activeUserId;

  /// Follows the session: sync when a verified Manager is signed in, wipe when
  /// the session is gone or the rows belong to someone else.
  void bindAuth(AuthController auth) {
    _auth = auth;
    auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  /// Auth changes are handled strictly one after another, on the same queue as
  /// syncs and wipes, so a sign-out wipe and the next sign-in's sync cannot
  /// interleave.
  Future<void> _authWork = Future.value();

  /// Completes once every auth change seen so far has been fully handled.
  Future<void> get settled => _authWork;

  void _onAuthChanged() {
    _authWork = _authWork.then((_) => _handleAuth()).catchError((Object error) {
      // A broken link would stop every later change — including a sign-out
      // wipe — from ever being handled.
      debugPrint('LocalReplica could not follow an auth change: $error');
    });
  }

  Future<void> _handleAuth() async {
    final auth = _auth!;
    final user = auth.currentUser;
    switch (auth.status) {
      case AuthStatus.unknown:
        return;
      case AuthStatus.unauthenticated:
        // Nobody may read the replica while signed out.
        _activeUserId = null;
        // `restoreSession` also lands here when the device is offline at
        // start-up — and then the stored session is intact. Only a session that
        // is actually gone (sign-out, expiry, refresh rejected) wipes. The
        // owner check at the next sign-in protects the rows either way.
        if (await auth.sessionStore.accessToken == null) {
          await clear();
        }
      case AuthStatus.authenticated:
        if (user == null || !user.isVerified) return;
        if (_activeUserId == user.id) return;
        await _enqueue(() => _adopt(user.id));
        _notify();
        await sync();
    }
  }

  /// Confirms the replica belongs to [userId], wiping it first if it belonged
  /// to anyone else — including a user from a previous run of the app.
  Future<void> _adopt(String userId) async {
    if (await ready() == null) {
      _activeUserId = userId;
      return;
    }
    final owner = await _store!.ownerUserId();
    if (owner != null && owner != userId) await _wipe();
    await _store!.setOwnerUserId(userId);
    _activeUserId = userId;
  }

  /// Registers for foreground notifications, so returning to the app syncs.
  void attachLifecycle() => WidgetsBinding.instance.addObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _activeUserId != null) {
      unawaited(sync());
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth?.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
