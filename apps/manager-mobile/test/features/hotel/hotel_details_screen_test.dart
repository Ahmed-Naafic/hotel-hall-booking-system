import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_models.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/hotel_details_screen.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/hotel_photo_viewer_screen.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/hotel_profile_form_screen.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Map<String, dynamic> _hotelJson({String status = 'APPROVED_ACTIVE', Map<String, dynamic>? profileData}) => {
      'id': 'h1',
      'registeredByUserId': 'u1',
      'status': status,
      'profileData': profileData,
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

Map<String, dynamic> _mediaJson({Map<String, dynamic>? logo, List<Map<String, dynamic>>? photos}) => {
      'logo': logo,
      'photos': photos ?? [],
    };

Map<String, dynamic> _mediaItem(String id, String url) => {
      'id': id,
      'hotelId': 'h1',
      'type': 'PHOTO',
      'url': url,
      'createdAt': '2026-08-26T00:00:00.000Z',
      'updatedAt': '2026-08-26T00:00:00.000Z',
    };

Widget _wrap(Future<http.Response> Function(http.Request) handler, {String hotelStatus = 'APPROVED_ACTIVE'}) {
  final apiClient = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: InMemoryTokenStorage())
    ..hotel = Hotel.fromJson(_hotelJson(status: hotelStatus));
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<HotelContextController>.value(value: hotelContext),
    ],
    child: const MaterialApp(home: HotelDetailsScreen(hotelId: 'h1')),
  );
}

void main() {
  // HotelProfileFormScreen (structured fields + media placeholders +
  // Additional Information) is taller than the default 800x600 test
  // surface, which would leave its submit button off-screen.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('shows a loading indicator, then the Hotel\'s status and profile fields', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/media')) return successResponse(_mediaJson());
      return successResponse(_hotelJson(profileData: {
        'name': 'Liido Beach Hotel',
        'description': 'A beachfront venue in Mogadishu.',
        'location': {'latitude': 2.045611, 'longitude': 45.370024, 'address': 'Karaan, Muqdisho'},
        'contactPhone': '+252611234567',
        'email': 'contact@liidobeach.example',
      }));
    }));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Liido Beach Hotel'), findsOneWidget);
    expect(find.text('Approved Active'), findsOneWidget);
    expect(find.text('A beachfront venue in Mogadishu.'), findsOneWidget);
    expect(find.text('Karaan, Muqdisho'), findsOneWidget);
    expect(find.text('+252611234567'), findsOneWidget);
    expect(find.text('contact@liidobeach.example'), findsOneWidget);
  });

  testWidgets('a custom (non-standard) field is shown under Additional Information, by its own key', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/media')) return successResponse(_mediaJson());
      return successResponse(_hotelJson(profileData: {'name': 'Liido Beach Hotel', 'amenities': 'Pool, Spa'}));
    }));
    await tester.pumpAndSettle();

    expect(find.text('ADDITIONAL INFORMATION'), findsOneWidget);
    expect(find.text('Amenities'), findsOneWidget);
    expect(find.text('Pool, Spa'), findsOneWidget);
  });

  testWidgets('shows "no profile information" for an empty Hotel, never invented content', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/media')) return successResponse(_mediaJson());
      return successResponse(_hotelJson());
    }));
    await tester.pumpAndSettle();

    expect(find.text('No profile information yet.'), findsOneWidget);
  });

  testWidgets('shows an error state with retry on a fetch failure', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/media')) return successResponse(_mediaJson());
      callCount += 1;
      if (callCount == 1) return errorResponse('NOT_FOUND', 'Hotel not found.', 404);
      return successResponse(_hotelJson(profileData: {'name': 'Recovered'}));
    }));
    await tester.pumpAndSettle();

    expect(find.text('Hotel not found.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets(
    'the Hotel Logo is shown in its own labeled section, never mixed into the Hotel Photos carousel',
    (tester) async {
      await tester.pumpWidget(_wrap((r) async {
        if (r.url.path.endsWith('/media')) {
          return successResponse(_mediaJson(
            logo: {'id': 'logo1', 'hotelId': 'h1', 'type': 'LOGO', 'url': 'https://example.com/logo.jpg', 'createdAt': '2026-08-26T00:00:00.000Z', 'updatedAt': '2026-08-26T00:00:00.000Z'},
            photos: [_mediaItem('p1', 'https://example.com/1.jpg')],
          ));
        }
        return successResponse(_hotelJson(profileData: {'name': 'Liido Beach Hotel'}));
      }));
      await tester.pumpAndSettle();

      expect(find.text('Hotel Logo'), findsOneWidget);
      expect(find.text('Hotel Photos'), findsOneWidget);
      expect(find.byType(HHNetworkImage), findsNWidgets(2));

      // Tapping the Logo opens the viewer scoped to just the Logo — a
      // one-photo viewer, not the Photos carousel's list.
      await tester.tap(find.byType(HHNetworkImage).first);
      await tester.pumpAndSettle();
      final logoViewer = tester.widget<HotelPhotoViewerScreen>(find.byType(HotelPhotoViewerScreen));
      expect(logoViewer.photos, hasLength(1));
      expect(logoViewer.photos.single.url, 'https://example.com/logo.jpg');
    },
  );

  testWidgets(
    'tapping a Hotel Photo opens the photo viewer scoped to the Photos list only, at the tapped index',
    (tester) async {
      await tester.pumpWidget(_wrap((r) async {
        if (r.url.path.endsWith('/media')) {
          return successResponse(_mediaJson(
            logo: {'id': 'logo1', 'hotelId': 'h1', 'type': 'LOGO', 'url': 'https://example.com/logo.jpg', 'createdAt': '2026-08-26T00:00:00.000Z', 'updatedAt': '2026-08-26T00:00:00.000Z'},
            photos: [_mediaItem('p1', 'https://example.com/1.jpg'), _mediaItem('p2', 'https://example.com/2.jpg')],
          ));
        }
        return successResponse(_hotelJson(profileData: {'name': 'Liido Beach Hotel'}));
      }));
      await tester.pumpAndSettle();

      // Second HHNetworkImage overall is the first Photos-carousel thumbnail
      // (the first is the Logo's own thumbnail).
      await tester.tap(find.byType(HHNetworkImage).at(1));
      await tester.pumpAndSettle();

      final viewer = tester.widget<HotelPhotoViewerScreen>(find.byType(HotelPhotoViewerScreen));
      expect(viewer.photos, hasLength(2));
      expect(viewer.photos.every((p) => p.url != 'https://example.com/logo.jpg'), true);
      expect(viewer.initialIndex, 0);
    },
  );

  testWidgets('a Hotel with no Logo shows only the Hotel Photos section', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/media')) {
        return successResponse(_mediaJson(photos: [_mediaItem('p1', 'https://example.com/1.jpg')]));
      }
      return successResponse(_hotelJson(profileData: {'name': 'Liido Beach Hotel'}));
    }));
    await tester.pumpAndSettle();

    expect(find.text('Hotel Logo'), findsNothing);
    expect(find.text('Hotel Photos'), findsOneWidget);
  });

  testWidgets('an APPROVED_ACTIVE Hotel shows an Edit action', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/media')) return successResponse(_mediaJson());
      return successResponse(_hotelJson(status: 'APPROVED_ACTIVE', profileData: {'name': 'Liido Beach Hotel'}));
    }, hotelStatus: 'APPROVED_ACTIVE'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('a REJECTED Hotel also shows an Edit action', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/media')) return successResponse(_mediaJson());
      return successResponse(_hotelJson(status: 'REJECTED', profileData: {'name': 'Liido Beach Hotel'}));
    }, hotelStatus: 'REJECTED'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets(
    'a REGISTERED or UNDER_REVIEW Hotel shows no Edit action — the backend does not permit editing then',
    (tester) async {
      await tester.pumpWidget(_wrap((r) async {
        if (r.url.path.endsWith('/media')) return successResponse(_mediaJson());
        return successResponse(_hotelJson(status: 'UNDER_REVIEW', profileData: {'name': 'Liido Beach Hotel'}));
      }, hotelStatus: 'UNDER_REVIEW'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    },
  );

  testWidgets('tapping Edit opens the profile form, and saving reloads this screen with the fresh values and a confirmation', (tester) async {
    var patched = false;
    Map<String, dynamic> currentProfileData() => patched
        ? {
            'name': 'The Grand Hall Hotel',
            'description': 'A premium event venue.',
            'location': {'latitude': -1.286389, 'longitude': 36.817223, 'address': 'Nairobi, Kenya'},
            'contactPhone': '+254700000000',
          }
        : {'name': 'Liido Beach Hotel'};

    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/media')) return successResponse(_mediaJson());
      if (r.method == 'POST' && r.url.path.endsWith('/location/reverse-geocode')) {
        return successResponse({'available': true, 'address': 'Nairobi, Kenya'});
      }
      if (r.method == 'PATCH') {
        patched = true;
        return successResponse(_hotelJson(profileData: currentProfileData()));
      }
      return successResponse(_hotelJson(profileData: currentProfileData()));
    }));
    await tester.pumpAndSettle();

    expect(find.text('Liido Beach Hotel'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(HotelProfileFormScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Hotel Name'), 'The Grand Hall Hotel');
    await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'A premium event venue.');
    await tester.tap(find.text('Open map and place pin'));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    map.options.onTap!(const TapPosition(Offset.zero, Offset.zero), const LatLng(-1.286389, 36.817223));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Contact Phone'), '+254700000000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.byType(HotelProfileFormScreen), findsNothing);
    expect(find.text('Hotel profile updated.'), findsOneWidget);
    expect(find.text('The Grand Hall Hotel'), findsWidgets);
    expect(find.text('A premium event venue.'), findsOneWidget);
    expect(find.text('Nairobi, Kenya'), findsOneWidget);
    expect(find.text('+254700000000'), findsOneWidget);
  });
}
