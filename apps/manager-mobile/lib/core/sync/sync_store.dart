import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'sync_database.dart';

/// The only place the replica is read or written (`coding-standards.md` §5's
/// rule, applied on the client: a repository, not queries scattered through
/// controllers).
///
/// Holds no business rules. It does not decide whether a Hall is visible or a
/// Booking may transition — those stay on the server, where they already are.
class SyncStore {
  SyncStore(this._database);

  final SyncDatabase _database;
  Database get _db => _database.db;

  /// The lifted column by which other collections' rows point at a row of this
  /// collection (see `SyncDatabase`).
  static const _childKeyOf = {'hotel': 'hotel_id', 'hall': 'hall_id'};

  // ---------------------------------------------------------------------------
  // Cursors and scope
  // ---------------------------------------------------------------------------

  /// The high-water mark for one collection, or `null` for "never synced" —
  /// which the engine sends as an absent `since`, i.e. initial sync.
  Future<String?> cursorFor(String collection) async {
    final rows = await _db.query(
      'sync_state',
      columns: ['cursor'],
      where: 'collection = ?',
      whereArgs: [collection],
    );
    return rows.isEmpty ? null : rows.first['cursor'] as String?;
  }

  Future<void> setCursor(String collection, String? cursor) async {
    await _db.insert(
      'sync_state',
      {'collection': collection, 'cursor': cursor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> scopeId() async {
    final rows = await _db.query('sync_scope', columns: ['scope_id'], where: 'id = 1');
    return rows.isEmpty ? null : rows.first['scope_id'] as String;
  }

  Future<void> setScopeId(String scopeId) async {
    await _db.insert(
      'sync_scope',
      {'id': 1, 'scope_id': scopeId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// The user whose rows these are, or null for an empty replica.
  Future<String?> ownerUserId() async {
    final rows = await _db.query('sync_owner', columns: ['user_id'], where: 'id = 1');
    return rows.isEmpty ? null : rows.first['user_id'] as String;
  }

  Future<void> setOwnerUserId(String userId) async {
    await _db.insert(
      'sync_owner',
      {'id': 1, 'user_id': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Whether [collection] has completed at least one page of sync — the
  /// difference between "nothing here" and "never fetched", which a reader must
  /// not confuse. A page with no rows still records its cursor.
  Future<bool> hasSynced(String collection) async {
    final rows = await _db.query(
      'sync_state',
      columns: ['collection'],
      where: 'collection = ?',
      whereArgs: [collection],
    );
    return rows.isNotEmpty;
  }

  /// Discards one collection and its cursor, so its next sync starts from
  /// nothing. The response to `SYNC_CURSOR_EXPIRED` (Technical Design §8).
  Future<void> resetCollection(String collection) async {
    await _db.transaction((txn) async {
      await txn.delete('sync_records', where: 'collection = ?', whereArgs: [collection]);
      await txn.delete('sync_state', where: 'collection = ?', whereArgs: [collection]);
    });
  }

  /// Discards the whole replica.
  ///
  /// Called when the server reports a `scopeId` other than the one the cursors
  /// were fetched under: the caller's permissions changed, so rows synced under
  /// the old scope may no longer be theirs to hold, and the cursors no longer
  /// describe a set they are allowed to see. Wiping is the only safe response —
  /// keeping data and resyncing forward would preserve exactly the rows that
  /// should disappear.
  Future<void> wipe() async {
    await _db.transaction((txn) async {
      await txn.delete('sync_records');
      await txn.delete('sync_state');
      await txn.delete('sync_scope');
      await txn.delete('sync_owner');
    });
  }

  // ---------------------------------------------------------------------------
  // Applying a page
  // ---------------------------------------------------------------------------

  /// Applies one page atomically: upserts every changed row, removes every
  /// tombstoned id, and advances the cursor — in a single transaction, so a
  /// crash mid-page cannot leave the cursor ahead of the rows it describes.
  ///
  /// Deletions are applied **after** the upserts. The server can report a row
  /// as both changed and deleted across a page boundary only if it was
  /// re-created, which cannot happen (ids are never reused), but ordering the
  /// two makes the outcome defined rather than incidental.
  Future<void> applyPage({
    required String collection,
    required List<Map<String, dynamic>> changed,
    required List<String> deleted,
    required String? nextCursor,
  }) async {
    await _db.transaction((txn) async {
      for (final row in changed) {
        await txn.insert(
          'sync_records',
          {
            'collection': collection,
            'id': row['id'] as String,
            'sync_seq': row['syncSeq'] as String,
            // Lifted out for indexed scope queries. `hallId` is absent on most
            // collections and `hotelId` on notifications — null is correct, not
            // a gap.
            'hotel_id': row['hotelId'] as String?,
            'hall_id': row['hallId'] as String?,
            'data': jsonEncode(row),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final id in deleted) {
        await txn.delete(
          'sync_records',
          where: 'collection = ? AND id = ?',
          whereArgs: [collection, id],
        );
        // A tombstoned parent takes its children with it. The server does not
        // tombstone a soft-deleted Hall's photos or blocks separately — they are
        // unreachable through it, not deleted — so without this they would stay
        // in the replica for good.
        final childKey = _childKeyOf[collection];
        if (childKey != null) {
          await txn.delete('sync_records', where: '$childKey = ?', whereArgs: [id]);
        }
      }
      await txn.insert(
        'sync_state',
        {'collection': collection, 'cursor': nextCursor},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> all(String collection) => _query(collection);

  /// Rows of one collection belonging to one Hotel.
  Future<List<Map<String, dynamic>>> forHotel(String collection, String hotelId) =>
      _query(collection, where: 'hotel_id = ?', args: [hotelId]);

  /// Rows of one collection belonging to one Hall.
  Future<List<Map<String, dynamic>>> forHall(String collection, String hallId) =>
      _query(collection, where: 'hall_id = ?', args: [hallId]);

  Future<Map<String, dynamic>?> byId(String collection, String id) async {
    final rows = await _query(collection, where: 'id = ?', args: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> count(String collection) async {
    final rows = await _db.rawQuery(
      'SELECT count(*) AS n FROM sync_records WHERE collection = ?',
      [collection],
    );
    return rows.first['n'] as int;
  }

  /// Ordered newest-first by `sync_seq`, cast to an integer because the column
  /// is TEXT — a lexicographic sort would put '9' after '10'.
  Future<List<Map<String, dynamic>>> _query(
    String collection, {
    String? where,
    List<Object?> args = const [],
  }) async {
    final rows = await _db.rawQuery(
      'SELECT data FROM sync_records WHERE collection = ?'
      '${where == null ? '' : ' AND $where'}'
      ' ORDER BY CAST(sync_seq AS INTEGER) DESC',
      [collection, ...args],
    );
    return rows
        .map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>)
        .toList();
  }
}
