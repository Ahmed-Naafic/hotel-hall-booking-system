import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/sync/sync_database.dart';
import 'hall_models.dart';

/// Answers the Hall list's queries from the local replica instead of the
/// network (ADR-0009, Local-First Technical Design §3).
///
/// **Why local search is complete here, and would not be for a Customer.** A
/// Manager's working set is one Hotel — every one of its Halls is replicated
/// (Technical Design §13), so filtering locally sees the same rows the server
/// would. `HallListController`'s existing comment warns against "a client-side
/// filter over an already-loaded, possibly-incomplete page", and that reasoning
/// is sound: it just does not apply to a complete replica. `BDR-020` governs
/// *Hotel* search in Discover, where a Customer's replica genuinely is partial,
/// and nothing here touches it.
///
/// Filtering happens in SQL via `json_extract`, not by loading rows into Dart —
/// the same rule the backend follows, for the same reason.
class LocalHallRepository {
  LocalHallRepository(this._database);

  final SyncDatabase _database;
  Database get _db => _database.db;

  static const _collection = 'hall';

  /// One Hotel's Halls, narrowed and ordered the way the server narrows and
  /// orders them (`hall.repository.js#listByHotelId`): case-insensitive partial
  /// match on Hall Name, the Manager's own Active/Inactive filter, newest
  /// *created* first. Not `sync_seq` order — that is when a row last changed,
  /// and would jump an edited Hall to the top of a list the server keeps in
  /// creation order. `id` breaks ties so the order is deterministic.
  ///
  /// `status` accepts the same `'active'`/`'inactive'` values the endpoint does,
  /// so a caller can be switched between this and the network repository without
  /// translating anything.
  Future<List<Hall>> listHalls({
    required String hotelId,
    String search = '',
    String? status,
  }) async {
    final where = <String>['collection = ?', 'hotel_id = ?'];
    final args = <Object?>[_collection, hotelId];

    if (search.trim().isNotEmpty) {
      // LIKE is case-insensitive for ASCII in SQLite by default, which matches
      // the backend's `mode: 'insensitive'` for the same field.
      where.add("json_extract(data, '\$.profileData.name') LIKE ?");
      args.add('%${search.trim()}%');
    }
    if (status == 'active') {
      where.add("json_extract(data, '\$.isActive') = 1");
    } else if (status == 'inactive') {
      where.add("json_extract(data, '\$.isActive') = 0");
    }

    final rows = await _db.rawQuery(
      'SELECT data FROM sync_records WHERE ${where.join(' AND ')} '
      // ISO-8601 UTC timestamps from one serializer sort correctly as text.
      "ORDER BY json_extract(data, '\$.createdAt') DESC, id DESC",
      args,
    );
    return rows
        .map((row) => Hall.fromJson(
              (jsonDecode(row['data'] as String) as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  /// The "All (n)" / "Active (n)" / "Inactive (n)" chip counts.
  ///
  /// Three SQL counts over the replica, replacing two network round trips the
  /// controller currently makes on every load. Inactive is counted rather than
  /// derived, because over a replica it costs the same and cannot drift.
  Future<({int all, int active, int inactive})> counts({required String hotelId}) async {
    Future<int> countWhere(String? extra) async {
      final rows = await _db.rawQuery(
        'SELECT count(*) AS n FROM sync_records '
        'WHERE collection = ? AND hotel_id = ?${extra == null ? '' : ' AND $extra'}',
        [_collection, hotelId],
      );
      return rows.first['n'] as int;
    }

    return (
      all: await countWhere(null),
      active: await countWhere("json_extract(data, '\$.isActive') = 1"),
      inactive: await countWhere("json_extract(data, '\$.isActive') = 0"),
    );
  }

  /// Whether the replica holds anything for this Hotel yet — the difference
  /// between "this Hotel has no Halls" and "we have never synced", which the
  /// screen must not confuse: the first is an empty state, the second is a
  /// reason to sync before showing one.
  Future<bool> hasAnyFor({required String hotelId}) async {
    final rows = await _db.rawQuery(
      'SELECT 1 FROM sync_records WHERE collection = ? AND hotel_id = ? LIMIT 1',
      [_collection, hotelId],
    );
    return rows.isNotEmpty;
  }
}
