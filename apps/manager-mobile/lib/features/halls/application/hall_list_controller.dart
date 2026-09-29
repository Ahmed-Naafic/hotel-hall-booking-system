import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../../../core/sync/local_replica.dart';
import '../data/hall_models.dart';
import '../data/hall_repository.dart';
import '../data/local_hall_repository.dart';

enum HallListStatus { loading, empty, ready, error }

/// Loads one Hotel's Halls (own-Hotel management view — every Hall
/// regardless of visibility, WBS-05), optionally narrowed by [search] text
/// or an Active/Inactive [statusFilter].
///
/// **Local-first when it can be** (ADR-0009, Local-First Technical Design §3).
/// Once the [replica] holds this Hotel's Halls, the list, the search and the
/// chip counts are answered from it — instantly, and offline — and a sync runs
/// behind them; when it brings changes, the list re-reads. Filtering a local
/// replica is sound here where it would not be for a Customer: a Manager's
/// replica holds *every* one of their Hotel's Halls, so it sees exactly the
/// rows the server would (`LocalHallRepository`).
///
/// Until the replica has synced — first launch, or a platform with no local
/// database — every read goes to the server exactly as it always did:
/// `GET /hotels/:hotelId/halls?search=&status=`, never a client-side filter
/// over an already-loaded, possibly-incomplete page.
///
/// Commands never go through the replica. Activating a Hall is still a `PATCH`
/// the server validates; the replica only learns the result by syncing.
class HallListController extends ChangeNotifier {
  HallListController({required this.repository, required this.hotelId, this.replica}) {
    replica?.addListener(_onReplicaChanged);
  }

  final HallRepository repository;
  final String hotelId;
  final LocalReplica? replica;

  HallListStatus status = HallListStatus.loading;
  List<Hall> halls = [];
  String? errorMessage;
  bool hasNext = false;
  bool isLoadingMore = false;
  int _page = 1;
  static const _limit = 20;
  static const _searchDebounce = Duration(milliseconds: 400);

  String search = '';
  // null = "All", matching the mockup's default selected chip.
  String? statusFilter;
  Timer? _searchDebounceTimer;

  // Overview chip counts — "All (n)" / "Active (n)" / "Inactive (n)".
  // Non-essential (the list itself works without them), so a failure here
  // never surfaces as a screen-level error.
  int? allCount;
  int? activeCount;
  int? inactiveCount;

  /// The list on screen came from the replica, not from a response just now.
  bool isLocal = false;

  /// Local rows are showing and the last sync failed — offline, or any other
  /// reason — so the screen says the list may be out of date rather than
  /// pretending it is current.
  bool get showingSavedData => isLocal && replica?.lastError != null;

  /// Why [showingSavedData] — the device is offline, rather than the server
  /// having refused.
  bool get savedDataBecauseOffline => replica?.isOffline ?? false;

  bool get isFiltering => search.isNotEmpty || statusFilter != null;

  /// Stamps every load, so a slower response for a superseded query (typed
  /// "gu" then "guu") can never overwrite the newer one's result.
  int _generation = 0;
  int _renderedRevision = -1;
  bool _disposed = false;

  /// A [load] is running. A replica change arriving meanwhile is deferred to
  /// its end rather than rendered on top of it: taking a new generation for a
  /// background re-read would make the Manager's own load look superseded and
  /// return with nothing rendered.
  bool _loadInFlight = false;
  bool _replicaChangedDuringLoad = false;

  /// [forceSync]: the screen was just opened, or the Manager asked to retry —
  /// attempt a real sync, so an unreachable server is *detected* and the
  /// saved-data notice shown. Otherwise (a search or filter re-running) a sync
  /// is attempted only if the replica is stale, so typing does not cost a
  /// round trip per keystroke.
  Future<void> load({bool forceSync = false}) async {
    final generation = ++_generation;
    _loadInFlight = true;
    status = HallListStatus.loading;
    errorMessage = null;
    _page = 1;
    _notify();
    try {
      await _load(generation, forceSync: forceSync);
    } finally {
      if (generation == _generation) {
        _loadInFlight = false;
        if (_replicaChangedDuringLoad) {
          _replicaChangedDuringLoad = false;
          unawaited(_onReplicaChanged());
        }
      }
    }
  }

  Future<void> _load(int generation, {required bool forceSync}) async {
    final local = await _localRepository();
    if (generation != _generation) return;
    if (local != null) {
      // Local rows first, whatever the network is doing — then the sync, whose
      // outcome (fresh rows, or the offline notice) arrives by notification.
      await _renderLocal(local, generation);
      unawaited(forceSync ? replica!.sync() : replica!.syncIfStale());
      return;
    }

    try {
      final result = await repository.listHalls(
        hotelId: hotelId,
        page: _page,
        limit: _limit,
        search: search,
        status: statusFilter,
      );
      if (generation != _generation) return;
      halls = result.halls;
      hasNext = result.hasNext;
      isLocal = false;
      status = halls.isEmpty ? HallListStatus.empty : HallListStatus.ready;
    } on ApiException catch (e) {
      if (generation != _generation) return;
      errorMessage = e.message;
      status = HallListStatus.error;
    } on NetworkException catch (e) {
      if (generation != _generation) return;
      errorMessage = e.message;
      status = HallListStatus.error;
    }
    _notify();
    unawaited(loadCounts());
    // First launch: fill the replica, so the next read — triggered by the
    // replica's own notification — is local.
    if (replica != null) unawaited(replica!.sync());
  }

  /// The replica-backed repository, or null while the replica cannot answer
  /// for this Hotel yet.
  Future<LocalHallRepository?> _localRepository() async {
    final replica = this.replica;
    if (replica == null) return null;
    final db = await replica.ready();
    if (db == null || !await replica.hasSynced('hall')) return null;
    return LocalHallRepository(db);
  }

  Future<void> _renderLocal(LocalHallRepository local, int generation) async {
    final revision = replica!.revision;
    final rows = await local.listHalls(hotelId: hotelId, search: search, status: statusFilter);
    final counts = await local.counts(hotelId: hotelId);
    if (generation != _generation) return;
    halls = rows;
    // The replica holds the whole Hotel; there is no further page to fetch.
    hasNext = false;
    isLocal = true;
    errorMessage = null;
    allCount = counts.all;
    activeCount = counts.active;
    inactiveCount = counts.inactive;
    status = halls.isEmpty ? HallListStatus.empty : HallListStatus.ready;
    _renderedRevision = revision;
    _notify();
  }

  /// The replica changed (a sync landed, or it was wiped): re-read, without a
  /// loading flash, when this screen is the kind that reads from it.
  Future<void> _onReplicaChanged() async {
    if (_disposed) return;
    if (_loadInFlight) {
      _replicaChangedDuringLoad = true;
      return;
    }
    final replica = this.replica!;
    if (replica.revision == _renderedRevision) {
      // Only the offline flag may have moved; the rows did not.
      _notify();
      return;
    }
    // Captures the generation rather than taking a new one: a re-read in the
    // background must yield to a load the Manager started meanwhile — which
    // reads the same replica anyway — never supersede it.
    final generation = _generation;
    final local = await _localRepository();
    if (_disposed || generation != _generation) return;
    if (local == null) {
      // The replica was wiped (sign-out, another user) or became unreadable
      // while its rows were on screen. They must not stay there: fall back to
      // the network, as a first launch does.
      if (isLocal) {
        isLocal = false;
        halls = [];
        unawaited(load());
      }
      return;
    }
    await _renderLocal(local, generation);
  }

  Future<void> loadMore() async {
    if (!hasNext || isLoadingMore || isLocal) return;
    isLoadingMore = true;
    final generation = _generation;
    _notify();

    try {
      final result = await repository.listHalls(
        hotelId: hotelId,
        page: _page + 1,
        limit: _limit,
        search: search,
        status: statusFilter,
      );
      // A page for a query the Manager has since changed belongs to a result
      // set that is no longer on screen.
      if (generation == _generation) {
        halls = [...halls, ...result.halls];
        hasNext = result.hasNext;
        _page += 1;
      }
    } on ApiException catch (e) {
      if (generation == _generation) errorMessage = e.message;
    } on NetworkException catch (e) {
      if (generation == _generation) errorMessage = e.message;
    }
    isLoadingMore = false;
    _notify();
  }

  /// The "All (n)" / "Active (n)" / "Inactive (n)" chip counts — two cheap
  /// `limit: 1` calls (mirroring the same `page.total`-only trick the
  /// Dashboard's own Hall count already uses), never every Hall fetched
  /// just to count it. Inactive is derived (`all - active`) rather than a
  /// third call. Local reads count from the replica instead ([_renderLocal]).
  Future<void> loadCounts() async {
    if (isLocal) return;
    try {
      final results = await Future.wait([
        repository.listHalls(hotelId: hotelId, limit: 1),
        repository.listHalls(hotelId: hotelId, limit: 1, status: 'active'),
      ]);
      allCount = results[0].total;
      activeCount = results[1].total;
      inactiveCount = results[0].total - results[1].total;
      _notify();
    } on ApiException {
      // Chip counts are a non-essential nicety.
    } on NetworkException {
      // Same.
    }
  }

  /// Debounced (BDR-020-style — matches the established Hotel-search
  /// pattern), so every keystroke doesn't fire a request.
  void setSearch(String value) {
    search = value;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, load);
  }

  /// Chip taps are immediate — never debounced, unlike free-text search.
  void setStatusFilter(String? value) {
    if (statusFilter == value) return;
    statusFilter = value;
    load();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounceTimer?.cancel();
    replica?.removeListener(_onReplicaChanged);
    super.dispose();
  }

  /// Called after a successful create/edit so the list reflects it without
  /// a full reload. With a replica, a sync follows and the list re-reads from
  /// it; the local upsert only bridges the round trip.
  void upsert(Hall hall) {
    final index = halls.indexWhere((h) => h.id == hall.id);
    if (index == -1) {
      halls = [hall, ...halls];
    } else {
      halls = [...halls]..[index] = hall;
    }
    status = HallListStatus.ready;
    _notify();
    if (replica != null) {
      unawaited(replica!.sync());
    } else {
      unawaited(loadCounts());
    }
  }

  /// Reload after a command the server has just accepted (e.g. a Hall
  /// created). Syncs unconditionally first: the replica is known to be behind,
  /// so a freshness window must not skip it.
  Future<void> refreshAfterCommand() async {
    if (replica != null) await replica!.sync();
    await load();
  }

  /// The Manager's own Active/Inactive toggle — a server command, then a
  /// reload (rather than a local `upsert`) so a Hall that no longer matches
  /// the current status filter disappears immediately, exactly like a fresh
  /// fetch would show. With a replica, it syncs first so the reload reads the
  /// server's result rather than the replica's older copy.
  Future<void> setHallActive(Hall hall, bool isActive) async {
    await repository.setActive(hotelId: hotelId, id: hall.id, isActive: isActive);
    if (replica != null) await replica!.sync();
    await load();
  }
}
