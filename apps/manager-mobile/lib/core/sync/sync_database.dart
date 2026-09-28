import 'package:sqflite/sqflite.dart';

/// The on-device replica's schema (ADR-0009).
///
/// **One table for every collection, not eight.** Each row is the server's row
/// as JSON, keyed by `(collection, id)`, with the two scope keys the app
/// actually queries by — `hotel_id` and `hall_id` — lifted out at write time
/// into real, indexed columns.
///
/// That is a deliberate middle path. Eight typed tables would mean eight schema
/// definitions and eight migrations for a cache whose shape is dictated by the
/// server; a pure key-value store would mean loading rows and filtering them in
/// Dart, which is the pattern `BDR-020` rejected server-side and which
/// local-first should not relocate onto the device. Lifting the scope keys keeps
/// every query a real indexed `WHERE`, in SQL.
///
/// `sync_seq` is stored as TEXT: it is a PostgreSQL `BIGINT` and travels as a
/// decimal string precisely because it can exceed what a JavaScript — or Dart
/// `int` on the web — represents exactly. Ordering uses the numeric cast.
class SyncDatabase {
  SyncDatabase._(this.db);

  final Database db;

  /// 2 added `sync_owner`. Upgrades drop and resync (below), so bumping this
  /// costs one full sync, never data the server does not still hold.
  static const _version = 2;

  /// Opens (and migrates) the replica. `factory`/`path` are injectable so tests
  /// can run against an in-memory database through `sqflite_common_ffi`, which
  /// supplies the platform implementation `flutter test` otherwise lacks.
  static Future<SyncDatabase> open({
    DatabaseFactory? factory,
    String path = 'manager_sync.db',
  }) async {
    final opener = factory ?? databaseFactory;
    final db = await opener.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );
    return SyncDatabase._(db);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_records (
        collection TEXT NOT NULL,
        id         TEXT NOT NULL,
        sync_seq   TEXT NOT NULL,
        hotel_id   TEXT,
        hall_id    TEXT,
        data       TEXT NOT NULL,
        PRIMARY KEY (collection, id)
      )
    ''');
    // Every read is "this collection, for this scope" — so the index leads with
    // the collection and ends in the ordering key, the same shape the backend's
    // own sync indexes use.
    await db.execute(
      'CREATE INDEX idx_records_collection_hotel ON sync_records (collection, hotel_id)',
    );
    await db.execute(
      'CREATE INDEX idx_records_collection_hall ON sync_records (collection, hall_id)',
    );

    await db.execute('''
      CREATE TABLE sync_state (
        collection TEXT PRIMARY KEY,
        cursor     TEXT
      )
    ''');

    // A single row. Holds the `scopeId` the cursors above were fetched under:
    // if the server reports a different one, every cursor is meaningless and the
    // replica must be discarded (Local-First Technical Design §6).
    await db.execute('''
      CREATE TABLE sync_scope (
        id       INTEGER PRIMARY KEY CHECK (id = 1),
        scope_id TEXT NOT NULL
      )
    ''');

    // A single row: the user the replica belongs to. Persisted, not held in
    // memory, because the replica outlives the process — an app killed while
    // offline must still know whose rows these are when someone else signs in
    // next, before any sync has had a chance to compare scopes.
    await db.execute('''
      CREATE TABLE sync_owner (
        id      INTEGER PRIMARY KEY CHECK (id = 1),
        user_id TEXT NOT NULL
      )
    ''');
  }

  /// Every upgrade drops and resyncs. That is always a legal implementation —
  /// the replica is a cache, and a full resync is already required for a scope
  /// change or an over-old cursor.
  static Future<void> _upgrade(Database db, int from, int to) async {
    await db.execute('DROP TABLE IF EXISTS sync_records');
    await db.execute('DROP TABLE IF EXISTS sync_state');
    await db.execute('DROP TABLE IF EXISTS sync_scope');
    await db.execute('DROP TABLE IF EXISTS sync_owner');
    await _create(db, to);
  }

  Future<void> close() => db.close();
}
