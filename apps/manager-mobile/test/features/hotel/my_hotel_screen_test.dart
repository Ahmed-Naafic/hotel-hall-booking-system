import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_list_screen.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/hotel_details_screen.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/hotel_profile_form_screen.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/my_hotel_screen.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Map<String, dynamic> _hotelJson({String status = 'REGISTERED', Map<String, dynamic>? profileData}) => {
      'id': 'h1',
      'registeredByUserId': 'u1',
      'status': status,
      'profileData': profileData,
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

/// `GET /hotels/me`'s actual response shape (`HotelContextController.load`
/// always resolves through this endpoint, never `GET /hotels/:id`) — the
/// Hotel keyed under `hotel` (`null` when the Manager has none yet), never a
/// bare Hotel object.
Map<String, dynamic> _myHotelJson({
  String status = 'REGISTERED',
  Map<String, dynamic>? profileData,
  double? averageRating,
  int reviewCount = 0,
}) => {
  'hotel': _hotelJson(status: status, profileData: profileData),
  'latestApplication': null,
  'reviewSummary': {'average': averageRating, 'count': reviewCount},
};

/// The Manager has no Hotel yet — `GET /hotels/me` still returns `200`, with
/// `hotel: null` (`hotelController.getMyHotel`), never a `404`.
const _noHotelJson = {'hotel': null, 'latestApplication': null};

/// `GET /hotels/:id/halls?limit=1`'s paginated envelope, shaped exactly
/// like `HallRepository.listHalls` expects (`pagination` a sibling of
/// `data`, never nested inside it) — an empty Hall list by default.
http.Response _hallsPageResponse({int total = 0}) => http.Response(
      '{"status":"success","message":"ok","data":[],'
      '"pagination":{"page":1,"limit":1,"total":$total,"hasNext":false,"hasPrevious":false}}',
      200,
    );

/// `GET /hotels/:id/bookings/summary`'s response — zero Bookings by
/// default, the real database-side aggregate `MyHotelScreen`'s stat grid
/// reads, never a client-side count.
http.Response _summaryResponse({int totalBookings = 0, int totalRevenueCents = 0, int pendingCount = 0}) =>
    successResponse({'totalBookings': totalBookings, 'totalRevenueCents': totalRevenueCents, 'pendingCount': pendingCount});

/// Every test below reaches `MyHotelScreen`'s `ready` state at some point,
/// which now always fetches Hall count and Booking summary for its stat
/// grid (`HotelProfileHeader`) regardless of the Hotel's own status — Halls
/// may be created before full approval (`BR-HALL-02`). Wrapping every
/// test's own handler with this intercepts those two endpoints uniformly
/// rather than repeating the same two `if` branches in each test.
Future<http.Response> Function(http.Request) _withStats(Future<http.Response> Function(http.Request) handler) {
  return (request) async {
    if (request.method == 'GET' && request.url.path.endsWith('/halls')) return _hallsPageResponse();
    if (request.method == 'GET' && request.url.path.endsWith('/bookings/summary')) return _summaryResponse();
    return handler(request);
  };
}

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final apiClient = ApiClient(httpClient: MockClient(_withStats(handler)), baseUrl: 'http://test/api/v1');
  final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: InMemoryTokenStorage());
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<HotelContextController>.value(value: hotelContext),
    ],
    child: const MaterialApp(home: MyHotelScreen()),
  );
}

void main() {
  // The Hotel Profile Completion screen (structured fields + media
  // placeholders + Additional Information) is taller than the default
  // 800x600 test surface — enlarge it so the end-to-end test's submit
  // button is actually tappable, not off-screen.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('shows "Set up your Hotel" when no Hotel is connected yet', (tester) async {
    await tester.pumpWidget(_wrap((r) async => successResponse(_noHotelJson)));
    await tester.pumpAndSettle();

    expect(find.text('Set up your Hotel'), findsOneWidget);
  });

  testWidgets('shows the real Hotel status once one is set up', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'POST') return successResponse(_hotelJson(status: 'REGISTERED'), status: 201);
      if (r.method == 'GET' && r.url.path == '/api/v1/hotels/me') return successResponse(_noHotelJson);
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set up my Hotel'));
    await tester.pumpAndSettle();

    // Status is displayed formatted (ManagerFormatters.status), never the
    // raw backend enum casing — the underlying value is still the real one.
    expect(find.text('Registered'), findsOneWidget);
    expect(find.text('Manage Halls'), findsOneWidget);
    // Onboarding (HM2, BR-HOTEL-02): a REGISTERED Hotel's profile is
    // incomplete — the profile-completion step must be offered, and Halls
    // preparation remains available regardless (BR-HOTEL-04).
    expect(find.text('Complete your Hotel profile'), findsOneWidget);
  });

  testWidgets(
    'the stat grid never overflows on a narrow phone, even for the longest real Hotel status (RESTRICTED_UNDER_REVIEW)',
    (tester) async {
      // A real, narrow phone width — the 800x2400 surface `setUp` sets for
      // the profile-form tests elsewhere in this file would hide a
      // width-dependent text-wrap overflow like this one.
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(360, 800);
      addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);

      await tester.pumpWidget(_wrap((r) async => successResponse(_myHotelJson(
            status: 'RESTRICTED_UNDER_REVIEW',
            profileData: {'name': 'Liido Beach Hotel'},
          ))));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the profile header shows name, location, and About Hotel directly — but never Contact Phone/Email (those stay one tap away, at Hotel Details)',
    (tester) async {
      await tester.pumpWidget(_wrap((r) async {
        if (r.method == 'GET' && r.url.path.endsWith('/media')) {
          return successResponse({'logo': null, 'photos': []});
        }
        return successResponse(_myHotelJson(
          status: 'APPROVED_ACTIVE',
          profileData: {
            'name': 'Liido Beach Hotel',
            'description': 'A beachfront venue in Mogadishu.',
            'location': {
              'latitude': 2.045611,
              'longitude': 45.370024,
              'address': 'Karaan, Muqdisho, Banaadir, Soomaaliya',
            },
            'contactPhone': '+252611234567',
            'email': 'contact@liidobeach.example',
          },
        ));
      }));
      await tester.pumpAndSettle();

      expect(find.text('Liido Beach Hotel'), findsOneWidget);
      expect(find.text('Karaan, Muqdisho, Banaadir, Soomaaliya'), findsOneWidget);
      expect(find.text('A beachfront venue in Mogadishu.'), findsOneWidget);
      expect(find.text('+252611234567'), findsNothing);
      expect(find.text('contact@liidobeach.example'), findsNothing);
    },
  );

  testWidgets('shows a Verified badge only for an APPROVED_ACTIVE Hotel, never for any other status', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'GET' && r.url.path.endsWith('/media')) {
        return successResponse({'logo': null, 'photos': []});
      }
      return successResponse(_myHotelJson(status: 'APPROVED_ACTIVE', profileData: {'name': 'Liido Beach Hotel'}));
    }));
    await tester.pumpAndSettle();

    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('shows no Verified badge for a REJECTED Hotel', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'GET' && r.url.path.endsWith('/media')) {
        return successResponse({'logo': null, 'photos': []});
      }
      if (r.method == 'GET' && r.url.path == '/api/v1/hotels/h1') {
        return successResponse(_hotelJson(status: 'REJECTED', profileData: {'name': 'Liido Beach Hotel'}));
      }
      return successResponse(_myHotelJson(status: 'REJECTED', profileData: {'name': 'Liido Beach Hotel'}));
    }));
    await tester.pumpAndSettle();

    expect(find.text('Verified'), findsNothing);
  });

  testWidgets('shows the real average rating and review count once the Hotel has reviews', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'GET' && r.url.path.endsWith('/media')) {
        return successResponse({'logo': null, 'photos': []});
      }
      return successResponse(_myHotelJson(
        status: 'APPROVED_ACTIVE',
        profileData: {'name': 'Liido Beach Hotel'},
        averageRating: 4.6,
        reviewCount: 128,
      ));
    }));
    await tester.pumpAndSettle();

    expect(find.text('4.6 (128 reviews)'), findsOneWidget);
  });

  testWidgets('shows no rating row while the Hotel has zero reviews — never a fabricated 0.0', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'GET' && r.url.path.endsWith('/media')) {
        return successResponse({'logo': null, 'photos': []});
      }
      return successResponse(_myHotelJson(status: 'APPROVED_ACTIVE', profileData: {'name': 'Liido Beach Hotel'}));
    }));
    await tester.pumpAndSettle();

    expect(find.textContaining('reviews)'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('the bottom "Edit Profile" button opens the edit form, same as the AppBar icon', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'GET' && r.url.path.endsWith('/media')) {
        return successResponse({'logo': null, 'photos': []});
      }
      return successResponse(_myHotelJson(status: 'APPROVED_ACTIVE', profileData: {'name': 'Liido Beach Hotel'}));
    }));
    await tester.pumpAndSettle();

    // The AppBar's own edit `IconButton` has a "Edit Profile" tooltip,
    // whose (offscreen-until-hovered) `Text` also matches a plain
    // `find.text` — target the bottom button specifically instead. No
    // scroll needed: this file's `setUp` already enlarges the test
    // surface (800x2400) so the button is on-screen without it.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(HotelProfileFormScreen), findsOneWidget);
  });

  testWidgets('the bottom "Edit Profile" button is absent for a Hotel that cannot be edited (UNDER_REVIEW)', (tester) async {
    await tester.pumpWidget(_wrap((r) async => successResponse(_myHotelJson(status: 'UNDER_REVIEW'))));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsNothing);
  });

  testWidgets(
    'tapping the Hotel identity card opens the read-only Hotel Details screen, never the edit form directly',
    (tester) async {
      await tester.pumpWidget(_wrap((r) async {
        if (r.method == 'GET' && r.url.path.endsWith('/media')) {
          return successResponse({'logo': null, 'photos': []});
        }
        // GET /hotels/h1 (HotelDetailsScreen's own fetch) returns a bare
        // Hotel; GET /hotels/me (HotelContextController's) returns it
        // wrapped — the two must never be conflated.
        if (r.method == 'GET' && r.url.path == '/api/v1/hotels/h1') {
          return successResponse(_hotelJson(
            status: 'APPROVED_ACTIVE',
            profileData: {'name': 'Liido Beach Hotel'},
          ));
        }
        return successResponse(_myHotelJson(
          status: 'APPROVED_ACTIVE',
          profileData: {'name': 'Liido Beach Hotel'},
        ));
      }));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Liido Beach Hotel'));
      await tester.pumpAndSettle();

      final details = tester.widget<HotelDetailsScreen>(find.byType(HotelDetailsScreen));
      expect(details.hotelId, 'h1');
      expect(find.byType(HotelProfileFormScreen), findsNothing);
    },
  );

  testWidgets('"Manage Halls" navigates to HallListScreen with the resolved hotelId', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient(_withStats((r) async => successResponse(_myHotelJson(status: 'APPROVED_ACTIVE')))),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: storage);

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<HotelContextController>.value(value: hotelContext),
      ],
      child: const MaterialApp(home: MyHotelScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage Halls'));
    await tester.pumpAndSettle();

    expect(find.byType(HallListScreen), findsOneWidget);
    // Approved/Active is the normal Manager Home — no onboarding step shown.
    expect(find.text('Complete your Hotel profile'), findsNothing);
    expect(find.text('Ready to submit'), findsNothing);
    expect(find.text('Under review'), findsNothing);
  });

  Widget wrapWithContext(HotelContextController hotelContext, ApiClient apiClient) => MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider<HotelContextController>.value(value: hotelContext),
        ],
        child: const MaterialApp(home: MyHotelScreen()),
      );

  testWidgets('a REGISTERED Hotel: tapping "Complete Hotel Profile" opens the profile-completion screen', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient(_withStats((r) async {
        // HotelProfileFormScreen fetches its own Hotel Media independently
        // as soon as it mounts (HotelMediaController) — unrelated to this
        // test's own assertion, stubbed the same way
        // hotel_profile_form_screen_test.dart's _withMediaStub does.
        if (r.method == 'GET' && r.url.path.endsWith('/media')) {
          return successResponse({'logo': null, 'photos': []});
        }
        return successResponse(_myHotelJson(status: 'REGISTERED'));
      })),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: storage);

    await tester.pumpWidget(wrapWithContext(hotelContext, apiClient));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Complete Hotel Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(HotelProfileFormScreen), findsOneWidget);
  });

  testWidgets('a PROFILE_COMPLETE Hotel: "Submit Application" calls the endpoint and reaches UNDER_REVIEW', (tester) async {
    var applicationPosted = false;
    final apiClient = ApiClient(
      httpClient: MockClient(_withStats((r) async {
        if (r.method == 'POST' && r.url.path == '/api/v1/hotels/h1/applications') {
          applicationPosted = true;
          return successResponse({
            'id': 'app1',
            'hotelId': 'h1',
            'status': 'OPEN',
            'decidedByUserId': null,
            'decidedAt': null,
            'submittedAt': '2026-08-26T00:00:00.000Z',
          }, status: 201);
        }
        return successResponse(_myHotelJson(status: applicationPosted ? 'UNDER_REVIEW' : 'PROFILE_COMPLETE'));
      })),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: storage);

    await tester.pumpWidget(wrapWithContext(hotelContext, apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Ready to submit'), findsOneWidget);

    await tester.tap(find.text('Submit Application'));
    await tester.pumpAndSettle();

    expect(applicationPosted, true);
    expect(find.text('Under Review'), findsOneWidget);
    expect(find.text('Application submitted for review.'), findsOneWidget);
  });

  testWidgets(
    'tapping the identity card for a REJECTED Hotel also opens Hotel Details (not directly editable from here either)',
    (tester) async {
      final apiClient = ApiClient(
        httpClient: MockClient(_withStats((r) async {
          if (r.method == 'GET' && r.url.path.endsWith('/media')) {
            return successResponse({'logo': null, 'photos': []});
          }
          if (r.method == 'GET' && r.url.path == '/api/v1/hotels/h1') {
            return successResponse(_hotelJson(status: 'REJECTED', profileData: {'name': 'Liido Beach Hotel'}));
          }
          return successResponse(_myHotelJson(status: 'REJECTED', profileData: {'name': 'Liido Beach Hotel'}));
        })),
        baseUrl: 'http://test/api/v1',
      );
      final storage = InMemoryTokenStorage();
      final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: storage);

      await tester.pumpWidget(wrapWithContext(hotelContext, apiClient));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Liido Beach Hotel'));
      await tester.pumpAndSettle();

      expect(find.byType(HotelDetailsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'a full edit round trip (card -> Hotel Details -> Edit -> save) updates the identity card name once back on My Hotel, live off the shared HotelContextController',
    (tester) async {
      var patched = false;
      Map<String, dynamic> currentProfileData() => patched
          ? {
              'name': 'The Grand Hall Hotel',
              'description': 'A premium event venue.',
              'location': {
                'latitude': -1.286389,
                'longitude': 36.817223,
                'address': 'Nairobi, Kenya',
              },
              'contactPhone': '+254700000000',
            }
          : {'name': 'Liido Beach Hotel'};

      final apiClient = ApiClient(
        httpClient: MockClient(_withStats((r) async {
          if (r.method == 'GET' && r.url.path.endsWith('/media')) {
            return successResponse({'logo': null, 'photos': []});
          }
          if (r.method == 'POST' && r.url.path.endsWith('/location/reverse-geocode')) {
            return successResponse({'available': true, 'address': 'Nairobi, Kenya'});
          }
          if (r.method == 'PATCH') {
            patched = true;
            return successResponse(_hotelJson(status: 'APPROVED_ACTIVE', profileData: currentProfileData()));
          }
          if (r.method == 'GET' && r.url.path == '/api/v1/hotels/h1') {
            return successResponse(_hotelJson(status: 'APPROVED_ACTIVE', profileData: currentProfileData()));
          }
          return successResponse(_myHotelJson(status: 'APPROVED_ACTIVE', profileData: currentProfileData()));
        })),
        baseUrl: 'http://test/api/v1',
      );
      final storage = InMemoryTokenStorage();
      final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: storage);

      await tester.pumpWidget(wrapWithContext(hotelContext, apiClient));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Liido Beach Hotel'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Hotel Name'), 'The Grand Hall Hotel');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'A premium event venue.');
      await tester.tap(find.text('Open map and place pin'));
      await tester.pumpAndSettle();
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      map.options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(-1.286389, 36.817223),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm location'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Contact Phone'), '+254700000000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      // Back on Hotel Details, with a confirmation and the fresh values —
      // the still-open detail view reflects the just-saved data, not stale
      // pre-edit values (the original "updated but nothing shows" bug).
      expect(find.byType(HotelProfileFormScreen), findsNothing);
      expect(find.text('Hotel profile updated.'), findsOneWidget);
      expect(find.text('A premium event venue.'), findsOneWidget);
      expect(find.text('Nairobi, Kenya'), findsOneWidget);
      expect(find.text('+254700000000'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Back on My Hotel — the identity card's name reflects the edit too,
      // sourced from the same shared HotelContextController.
      expect(find.byType(HotelDetailsScreen), findsNothing);
      expect(find.text('The Grand Hall Hotel'), findsOneWidget);
    },
  );

  testWidgets('an UNDER_REVIEW Hotel shows the waiting/review state, with no action button', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient(_withStats((r) async => successResponse(_myHotelJson(status: 'UNDER_REVIEW')))),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: storage);

    await tester.pumpWidget(wrapWithContext(hotelContext, apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Complete Hotel Profile'), findsNothing);
    expect(find.text('Submit Application'), findsNothing);
  });

  testWidgets('end-to-end onboarding: completing the profile updates the still-open My Hotel screen to the next step', (tester) async {
    var profileCompleted = false;
    final apiClient = ApiClient(
      httpClient: MockClient(_withStats((r) async {
        // HotelProfileFormScreen loads its own Hotel Media independently
        // (HotelMediaController) as soon as it mounts, and the Location
        // picker's "Confirm location" step reverse-geocodes the placed pin
        // through the backend — both are unrelated to the onboarding-status
        // assertions below, so they're stubbed the same way
        // hotel_profile_form_screen_test.dart's _withMediaStub does.
        if (r.method == 'GET' && r.url.path.endsWith('/media')) {
          return successResponse({'logo': null, 'photos': []});
        }
        if (r.method == 'POST' && r.url.path.endsWith('/location/reverse-geocode')) {
          return successResponse({'available': true, 'address': 'Nairobi, Kenya'});
        }
        if (r.method == 'PATCH') {
          profileCompleted = true;
          return successResponse(_hotelJson(
            status: 'PROFILE_COMPLETE',
            profileData: {'name': 'The Grand Hall Hotel'},
          ));
        }
        return successResponse(_myHotelJson(status: profileCompleted ? 'PROFILE_COMPLETE' : 'REGISTERED'));
      })),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: storage);

    await tester.pumpWidget(wrapWithContext(hotelContext, apiClient));
    await tester.pumpAndSettle();
    expect(find.text('Registered'), findsOneWidget);

    await tester.tap(find.text('Complete Hotel Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Hotel Name'), 'The Grand Hall Hotel');
    await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'A premium event venue.');
    // Location (BDR-017, ADR-0008) is a map pin + confirmed address, not a
    // free-text field — same interaction hotel_profile_form_screen_test.dart
    // already exercises for this screen.
    await tester.tap(find.text('Open map and place pin'));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    map.options.onTap!(
      const TapPosition(Offset.zero, Offset.zero),
      const LatLng(-1.286389, 36.817223),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Contact Phone'), '+254700000000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save & Continue'));
    await tester.pumpAndSettle();

    // Back on MyHotelScreen — the onboarding state now reflects the real,
    // backend-confirmed PROFILE_COMPLETE status, not a client-side guess.
    expect(find.byType(HotelProfileFormScreen), findsNothing);
    expect(find.text('Profile Complete'), findsOneWidget);
    expect(find.text('Ready to submit'), findsOneWidget);
    expect(find.text('Hotel profile saved.'), findsOneWidget);
  });
}
