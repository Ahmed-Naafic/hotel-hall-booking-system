import 'package:flutter_test/flutter_test.dart';
import 'package:manager_mobile/core/sync/sync_database.dart';
import 'package:manager_mobile/core/sync/sync_store.dart';
import 'package:manager_mobile/features/halls/data/local_hall_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Reading the Hall list from the local replica (ADR-0009).
///
/// The rows written here are the **mapped** shape the sync endpoint actually
/// returns — `bookingTerms` composed, `photos` carrying server-derived URLs —
/// not raw Prisma rows. That distinction was a real defect: a raw row parses
/// into a Hall with no photos and empty booking terms without raising anything,
/// so these fixtures exist partly to keep the client and the endpoint honest
/// about each other's shape.

Map<String, dynamic> _mappedHall(
  String id,
  String seq, {
  String hotelId = 'hotel-1',
  required String name,
  bool isActive = true,
  int capacity = 100,
  String createdAt = '2026-09-01T00:00:00.000Z',
}) => {
  'id': id,
  'syncSeq': seq,
  'hotelId': hotelId,
  'profileData': {'name': name, 'capacity': capacity},
  'isActive': isActive,
  'bookingTerms': {
    'currency': 'USD',
    'rentAmountCents': 250000,
    'rentDurationHours': 24,
    'advancePaymentPercent': 30,
    'customerServiceNumber': null,
    'paymentReceivingNumber': null,
  },
  'photos': [
    {'id': 'photo-$id', 'type': 'PHOTO', 'url': 'https://example.test/$id.jpg'},
  ],
  'createdAt': createdAt,
  'updatedAt': '2026-09-02T00:00:00.000Z',
};

Future<({LocalHallRepository repo, SyncStore store, SyncDatabase db})> _harness(
  List<Map<String, dynamic>> halls,
) async {
  final db = await SyncDatabase.open(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
  final store = SyncStore(db);
  await store.applyPage(
    collection: 'hall',
    changed: halls,
    deleted: const [],
    nextCursor: halls.isEmpty ? null : halls.last['syncSeq'] as String,
  );
  return (repo: LocalHallRepository(db), store: store, db: db);
}

void main() {
  setUpAll(sqfliteFfiInit);

  test('parses the mapped shape, keeping photos and booking terms', () async {
    final h = await _harness([_mappedHall('hall-1', '10', name: 'Grand Hall')]);

    final halls = await h.repo.listHalls(hotelId: 'hotel-1');

    expect(halls, hasLength(1));
    expect(halls.first.displayTitle, 'Grand Hall');
    expect(halls.first.photos, hasLength(1), reason: 'a raw row would have parsed to zero photos');
    expect(halls.first.photos.first.url, 'https://example.test/hall-1.jpg');
    expect(halls.first.bookingTerms['rentAmountCents'], 250000,
        reason: 'a raw row would have parsed to empty booking terms');
    await h.db.close();
  });

  test('returns only the requested Hotel’s Halls', () async {
    final h = await _harness([
      _mappedHall('mine', '10', hotelId: 'hotel-1', name: 'Mine'),
      _mappedHall('theirs', '11', hotelId: 'hotel-2', name: 'Theirs'),
    ]);

    final halls = await h.repo.listHalls(hotelId: 'hotel-1');

    expect(halls.map((hall) => hall.id), ['mine']);
    await h.db.close();
  });

  test('orders newest-created first, as the server does — not by last change', () async {
    // 'old' was created first but edited last, so it carries the highest
    // syncSeq. The server lists by createdAt desc
    // (hall.repository.js#listByHotelId); ordering by syncSeq would jump an
    // edited Hall to the top.
    final h = await _harness([
      _mappedHall('newest', '10', name: 'Newest', createdAt: '2026-09-03T00:00:00.000Z'),
      _mappedHall('middle', '11', name: 'Middle', createdAt: '2026-09-02T00:00:00.000Z'),
      _mappedHall('old', '99', name: 'Old, edited last', createdAt: '2026-09-01T00:00:00.000Z'),
    ]);

    final halls = await h.repo.listHalls(hotelId: 'hotel-1');

    expect(halls.map((hall) => hall.id), ['newest', 'middle', 'old']);
    await h.db.close();
  });

  group('search', () {
    test('matches a partial name, case-insensitively', () async {
      final h = await _harness([
        _mappedHall('grand', '10', name: 'Grand Ballroom'),
        _mappedHall('small', '11', name: 'Small Meeting Room'),
      ]);

      for (final query in ['ballroom', 'BALLROOM', 'allro']) {
        final halls = await h.repo.listHalls(hotelId: 'hotel-1', search: query);
        expect(halls.map((hall) => hall.id), ['grand'], reason: 'query "$query"');
      }
      await h.db.close();
    });

    test('a query matching nothing returns nothing, not everything', () async {
      final h = await _harness([_mappedHall('grand', '10', name: 'Grand Ballroom')]);

      final halls = await h.repo.listHalls(hotelId: 'hotel-1', search: 'zzzz');

      expect(halls, isEmpty);
      await h.db.close();
    });

    test('blank and whitespace-only searches are not treated as a filter', () async {
      final h = await _harness([_mappedHall('grand', '10', name: 'Grand Ballroom')]);

      expect(await h.repo.listHalls(hotelId: 'hotel-1', search: ''), hasLength(1));
      expect(await h.repo.listHalls(hotelId: 'hotel-1', search: '   '), hasLength(1));
      await h.db.close();
    });
  });

  group('status filter', () {
    test('narrows to active or inactive, using the same values the endpoint takes', () async {
      final h = await _harness([
        _mappedHall('on', '10', name: 'Active Hall'),
        _mappedHall('off', '11', name: 'Inactive Hall', isActive: false),
      ]);

      expect(
        (await h.repo.listHalls(hotelId: 'hotel-1', status: 'active')).map((hall) => hall.id),
        ['on'],
      );
      expect(
        (await h.repo.listHalls(hotelId: 'hotel-1', status: 'inactive')).map((hall) => hall.id),
        ['off'],
      );
      expect(await h.repo.listHalls(hotelId: 'hotel-1'), hasLength(2), reason: 'no filter = all');
      await h.db.close();
    });

    test('search and status compose', () async {
      final h = await _harness([
        _mappedHall('a', '10', name: 'Wedding Hall'),
        _mappedHall('b', '11', name: 'Wedding Annex', isActive: false),
        _mappedHall('c', '12', name: 'Meeting Room'),
      ]);

      final halls =
          await h.repo.listHalls(hotelId: 'hotel-1', search: 'wedding', status: 'active');

      expect(halls.map((hall) => hall.id), ['a']);
      await h.db.close();
    });
  });

  test('counts all, active and inactive', () async {
    final h = await _harness([
      _mappedHall('a', '10', name: 'A'),
      _mappedHall('b', '11', name: 'B'),
      _mappedHall('c', '12', name: 'C', isActive: false),
      _mappedHall('other', '13', hotelId: 'hotel-2', name: 'Other Hotel'),
    ]);

    final counts = await h.repo.counts(hotelId: 'hotel-1');

    expect(counts.all, 3, reason: 'another Hotel’s Halls must not be counted');
    expect(counts.active, 2);
    expect(counts.inactive, 1);
    await h.db.close();
  });

  test('distinguishes “never synced” from “this Hotel has no Halls”', () async {
    final empty = await _harness([]);
    expect(await empty.repo.hasAnyFor(hotelId: 'hotel-1'), isFalse);
    await empty.db.close();

    final synced = await _harness([_mappedHall('a', '10', name: 'A')]);
    expect(await synced.repo.hasAnyFor(hotelId: 'hotel-1'), isTrue);
    // A different Hotel, in a replica that has been synced: genuinely empty.
    expect(await synced.repo.hasAnyFor(hotelId: 'hotel-2'), isFalse);
    await synced.db.close();
  });

  test('a tombstone removes the Hall from every read', () async {
    final h = await _harness([
      _mappedHall('keep', '10', name: 'Keep'),
      _mappedHall('drop', '11', name: 'Drop'),
    ]);

    await h.store.applyPage(
      collection: 'hall',
      changed: const [],
      deleted: const ['drop'],
      nextCursor: '12',
    );

    final halls = await h.repo.listHalls(hotelId: 'hotel-1');
    expect(halls.map((hall) => hall.id), ['keep']);
    expect((await h.repo.counts(hotelId: 'hotel-1')).all, 1);
    await h.db.close();
  });
}
