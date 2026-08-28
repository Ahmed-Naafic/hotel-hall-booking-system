import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_list_screen.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
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

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final apiClient = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
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
    await tester.pumpWidget(_wrap((r) async => errorResponse('NOT_FOUND', 'unused', 404)));
    await tester.pumpAndSettle();

    expect(find.text('Set up your Hotel'), findsOneWidget);
  });

  testWidgets('shows the real Hotel status once one is set up', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'POST') return successResponse(_hotelJson(status: 'REGISTERED'), status: 201);
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set up my Hotel'));
    await tester.pumpAndSettle();

    expect(find.text('REGISTERED'), findsOneWidget);
    expect(find.text('Manage Halls'), findsOneWidget);
    // Onboarding (HM2, BR-HOTEL-02): a REGISTERED Hotel's profile is
    // incomplete — the profile-completion step must be offered, and Halls
    // preparation remains available regardless (BR-HOTEL-04).
    expect(find.text('Complete your Hotel profile'), findsOneWidget);
  });

  testWidgets('"Manage Halls" navigates to HallListScreen with the resolved hotelId', (tester) async {
    // Simulate an already-cached hotel by wiring the controller directly.
    final apiClient = ApiClient(
      httpClient: MockClient((r) async {
        if (r.url.path.endsWith('/halls')) {
          return http.Response('{"status":"success","message":"ok","data":[],"pagination":{"page":1,"limit":20,"total":0,"hasNext":false,"hasPrevious":false}}', 200);
        }
        return successResponse(_hotelJson(status: 'APPROVED_ACTIVE'));
      }),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    await storage.write('hh_hotel_id', 'h1');
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
      httpClient: MockClient((r) async => successResponse(_hotelJson(status: 'REGISTERED'))),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    await storage.write('hh_hotel_id', 'h1');
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
      httpClient: MockClient((r) async {
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
        return successResponse(_hotelJson(status: applicationPosted ? 'UNDER_REVIEW' : 'PROFILE_COMPLETE'));
      }),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    await storage.write('hh_hotel_id', 'h1');
    final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: storage);

    await tester.pumpWidget(wrapWithContext(hotelContext, apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Ready to submit'), findsOneWidget);

    await tester.tap(find.text('Submit Application'));
    await tester.pumpAndSettle();

    expect(applicationPosted, true);
    expect(find.text('UNDER_REVIEW'), findsOneWidget);
    expect(find.text('Application submitted for review.'), findsOneWidget);
  });

  testWidgets('an UNDER_REVIEW Hotel shows the waiting/review state, with no action button', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient((r) async => successResponse(_hotelJson(status: 'UNDER_REVIEW'))),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    await storage.write('hh_hotel_id', 'h1');
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
      httpClient: MockClient((r) async {
        if (r.method == 'PATCH') {
          profileCompleted = true;
          return successResponse(_hotelJson(status: 'PROFILE_COMPLETE', profileData: {'name': 'The Grand Hall Hotel'}));
        }
        return successResponse(_hotelJson(status: profileCompleted ? 'PROFILE_COMPLETE' : 'REGISTERED'));
      }),
      baseUrl: 'http://test/api/v1',
    );
    final storage = InMemoryTokenStorage();
    await storage.write('hh_hotel_id', 'h1');
    final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: storage);

    await tester.pumpWidget(wrapWithContext(hotelContext, apiClient));
    await tester.pumpAndSettle();
    expect(find.text('REGISTERED'), findsOneWidget);

    await tester.tap(find.text('Complete Hotel Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Hotel Name'), 'The Grand Hall Hotel');
    await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'A premium event venue.');
    await tester.enterText(find.widgetWithText(TextFormField, 'Location'), 'Nairobi, Kenya');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contact Phone'), '+254700000000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save & Continue'));
    await tester.pumpAndSettle();

    // Back on MyHotelScreen — the onboarding state now reflects the real,
    // backend-confirmed PROFILE_COMPLETE status, not a client-side guess.
    expect(find.byType(HotelProfileFormScreen), findsNothing);
    expect(find.text('PROFILE_COMPLETE'), findsOneWidget);
    expect(find.text('Ready to submit'), findsOneWidget);
    expect(find.text('Hotel profile saved.'), findsOneWidget);
  });
}
