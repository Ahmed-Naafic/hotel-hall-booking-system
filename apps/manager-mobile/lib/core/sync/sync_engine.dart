import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'sync_store.dart';

/// Every collection the backend's Phase 1 registry serves
/// (`backend/src/modules/sync/sync.collections.js`), in dependency order.
///
/// The engine syncs whichever subset it is given. Manager Mobile passes
/// [managerReplicatedCollections] — only what a screen actually reads, because
/// a sync scan of rows nobody reads is pure load (Technical Design §13).
const syncCollections = <String>[
  'hotel',
  'hall',
  'hotelMedia',
  'hallMedia',
  'availabilityBlock',
  'booking',
  'notification',
  'hotelApplication',
];

/// What Manager Mobile replicates today: the Hall list reads locally
/// (`LocalHallRepository`). A synced Hall already carries its photos, with
/// server-derived URLs, so `hallMedia` is not needed alongside it. A collection
/// is added here when a screen starts reading it — never speculatively.
const managerReplicatedCollections = <String>['hall'];

/// What one sync run did, so a caller can report it without re-querying.
class SyncOutcome {
  const SyncOutcome({
    required this.changed,
    required this.deleted,
    required this.pages,
    required this.wiped,
  });

  final int changed;
  final int deleted;
  final int pages;

  /// The replica was discarded and rebuilt because the server reported a
  /// different `scopeId`.
  final bool wiped;

  bool get changedAnything => changed > 0 || deleted > 0 || wiped;

  static const none = SyncOutcome(changed: 0, deleted: 0, pages: 0, wiped: false);

  SyncOutcome operator +(SyncOutcome other) => SyncOutcome(
    changed: changed + other.changed,
    deleted: deleted + other.deleted,
    pages: pages + other.pages,
    wiped: wiped || other.wiped,
  );
}

/// The replica was discarded mid-run; every collection must start over.
class _ScopeChanged implements Exception {
  const _ScopeChanged();
}

/// Pulls changes from `GET /api/v1/sync/:collection` into the local replica
/// (Local-First Synchronization Technical Design §7, §16).
///
/// Deliberately **read-only**. Every mutation keeps its existing endpoint and the
/// database stays authoritative — this class has no write path, so no amount of
/// local state can create a Booking, confirm one, or block a Hall. That is the
/// design's central separation (§3, §12), enforced here by omission rather than
/// by a rule somebody has to remember.
///
/// The cursor is opaque: the engine stores exactly what the server returned as
/// `nextCursor` and sends it back. It never builds one, from a clock or from a
/// row's `syncSeq` — the server's cursor is a snapshot window, which is what
/// makes a transaction that commits out of order impossible to skip.
class SyncEngine {
  SyncEngine({
    required this.apiClient,
    required this.store,
    this.collections = syncCollections,
  });

  final ApiClient apiClient;
  final SyncStore store;
  final List<String> collections;

  /// Bounded per request by the server (default 20, max 100). Asking for the
  /// maximum keeps a cold start to fewer round trips; the server still decides.
  static const _pageSize = 100;

  /// Guards against a cursor that fails to advance. Without it a server bug
  /// returning `hasNext: true` with an unchanged cursor would spin forever on a
  /// device, draining battery and data.
  static const _maxPagesPerCollection = 500;

  /// A scope change restarts the run. Two restarts in one run means the scope
  /// is flapping; stop rather than loop, and let the next run try again.
  static const _maxRestarts = 2;

  /// Typed error meaning "your cursor is below the retention floor — resync
  /// this collection from nothing" (Technical Design §8).
  static const cursorExpiredError = 'SYNC_CURSOR_EXPIRED';

  Future<SyncOutcome>? _inFlight;

  /// Brings every collection up to date.
  ///
  /// Concurrent callers share one run rather than starting a second — two runs
  /// interleaving pages would advance each other's cursors. A caller that needs
  /// a run starting *after* its call (after a command) must not rely on this;
  /// `LocalReplica.sync` provides that guarantee by queueing.
  Future<SyncOutcome> syncAll() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<SyncOutcome> _run() async {
    var total = SyncOutcome.none;
    for (var attempt = 0; attempt <= _maxRestarts; attempt += 1) {
      try {
        for (final collection in collections) {
          total += await _syncCollection(collection);
        }
        return total;
      } on _ScopeChanged {
        // Everything synced earlier in this run was discarded with the rest of
        // the replica, so the run starts again from the first collection —
        // not just from the one that noticed.
        total += const SyncOutcome(changed: 0, deleted: 0, pages: 0, wiped: true);
      }
    }
    return total;
  }

  Future<SyncOutcome> _syncCollection(String collection) async {
    var changed = 0;
    var deleted = 0;
    var pages = 0;
    var cursor = await store.cursorFor(collection);

    for (var page = 0; page < _maxPagesPerCollection; page += 1) {
      final ({dynamic data, Map<String, dynamic>? pagination}) response;
      try {
        response = await apiClient.getPaginated(
          '/sync/$collection',
          query: {'limit': '$_pageSize', 'since': ?cursor},
        );
      } on ApiException catch (e) {
        // A 400 on `since` means the stored cursor can never be accepted again
        // — only a bug or a format change could produce one — and retrying it
        // would fail on every run forever. Recover exactly as for an expired one.
        final unusableCursor = e.isValidation && e.details.any((d) => d.field == 'since');
        if ((e.error != cursorExpiredError && !unusableCursor) || cursor == null) rethrow;
        // Never an empty success (§8): the rows this cursor would have needed
        // are gone, so the only correct replica is a fresh one.
        await store.resetCollection(collection);
        cursor = null;
        continue;
      }
      final data = (response.data as Map).cast<String, dynamic>();
      final pagination = response.pagination ?? const {};

      // Scope check first, before anything is written. A response fetched under
      // a scope we no longer hold must not be merged into the replica at all.
      final serverScopeId = data['scopeId'] as String?;
      if (serverScopeId != null && !await _scopeMatches(serverScopeId)) {
        await store.wipe();
        await store.setScopeId(serverScopeId);
        throw const _ScopeChanged();
      }

      final rows = ((data['changed'] as List?) ?? const [])
          .map((row) => (row as Map).cast<String, dynamic>())
          .toList();
      final tombstones =
          ((data['deleted'] as List?) ?? const []).map((id) => id as String).toList();
      final next = pagination['nextCursor'] as String?;

      await store.applyPage(
        collection: collection,
        changed: rows,
        deleted: tombstones,
        nextCursor: next ?? cursor,
      );

      changed += rows.length;
      deleted += tombstones.length;
      pages += 1;

      if (pagination['hasNext'] != true) break;
      if (next == null || next == cursor) {
        // `hasNext` with no usable cursor is a server contract violation.
        // Stopping is the only safe response: continuing would re-request the
        // same page forever.
        break;
      }
      cursor = next;
    }

    return SyncOutcome(changed: changed, deleted: deleted, pages: pages, wiped: false);
  }

  /// True when the stored scope matches, or when nothing has been synced yet —
  /// a first sync adopts whatever scope the server reports.
  Future<bool> _scopeMatches(String serverScopeId) async {
    final stored = await store.scopeId();
    if (stored == null) {
      await store.setScopeId(serverScopeId);
      return true;
    }
    return stored == serverScopeId;
  }
}
