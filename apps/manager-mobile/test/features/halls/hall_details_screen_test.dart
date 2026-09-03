import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/availability/presentation/screens/hall_availability_screen.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_details_screen.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_form_screen.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_photo_viewer_screen.dart';
import 'package:manager_mobile/features/hotel/application/image_picker_service.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Map<String, dynamic> _hallJson({
  Map<String, dynamic>? profileData,
  List<Map<String, dynamic>>? photos,
}) => {
  'id': 'hall-1',
  'hotelId': 'h1',
  'profileData': profileData,
  'photos': photos ?? [],
  'createdAt': '2026-08-25T00:00:00.000Z',
  'updatedAt': '2026-08-25T00:00:00.000Z',
};

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final client = ApiClient(
    httpClient: MockClient(handler),
    baseUrl: 'http://test/api/v1',
  );
  return Provider<ApiClient>.value(
    value: client,
    child: const MaterialApp(
      home: HallDetailsScreen(hotelId: 'h1', hallId: 'hall-1'),
    ),
  );
}

void main() {
  // The edit action navigates into HallFormScreen (structured fields + Hall
  // Photos placeholder + Additional Information), taller than the default
  // 800x600 test surface, which would leave its submit button off-screen.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets(
    'shows a loading indicator, then the Hall\'s profile fields with friendly labels',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          (r) async => successResponse(
            _hallJson(
              profileData: {
                'name': 'The Ivory Room',
                'capacity': '200',
                'location': 'Second floor',
                'description': 'A bright, airy room.',
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      // The Hall Name is the AppBar title, not a repeated body field.
      expect(find.text('The Ivory Room'), findsOneWidget);
      expect(find.text('Capacity'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.text('Location / Area'), findsOneWidget);
      expect(find.text('Second floor'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('A bright, airy room.'), findsOneWidget);
    },
  );

  testWidgets(
    'a custom (non-standard) field is shown under Additional Information, by its own key',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          (r) async => successResponse(
            _hallJson(
              profileData: {
                'name': 'The Ivory Room',
                'capacity': 200,
                'amenities': 'Stage',
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADDITIONAL INFORMATION'), findsOneWidget);
      // Custom-field keys are shown humanized (ManagerFormatters.label),
      // e.g. 'amenities' -> 'Amenities' — the underlying key is unchanged.
      expect(find.text('Amenities'), findsOneWidget);
      expect(find.text('Stage'), findsOneWidget);
      // Standard fields are never re-listed as if they were custom ones —
      // 'Name' has no standard row at all (the Hall Name is the AppBar
      // title), and 'Capacity' appears exactly once (its own standard
      // row), never a second time from the custom-fields dump.
      expect(find.text('Name'), findsNothing);
      expect(find.text('Capacity'), findsOneWidget);
    },
  );

  testWidgets(
    'shows "no profile information" for an empty Hall, never invented content',
    (tester) async {
      await tester.pumpWidget(_wrap((r) async => successResponse(_hallJson())));
      await tester.pumpAndSettle();

      expect(find.text('No profile information yet.'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an error state with retry for a nonexistent/not-owned Hall (404)',
    (tester) async {
      var callCount = 0;
      await tester.pumpWidget(
        _wrap((r) async {
          callCount += 1;
          if (callCount == 1)
            return errorResponse('NOT_FOUND', 'Hall not found.', 404);
          return successResponse(_hallJson(profileData: {'name': 'Recovered'}));
        }),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hall not found.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered'), findsWidgets);
    },
  );

  testWidgets(
    'the View Availability action navigates to HallAvailabilityScreen with the resolved hotel/hall id',
    (tester) async {
      await tester.pumpWidget(
        _wrap((r) async {
          if (r.url.path.contains('/availability/')) {
            return successResponse(<Map<String, dynamic>>[]);
          }
          return successResponse(
            _hallJson(profileData: {'name': 'The Ivory Room'}),
          );
        }),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.event_available_outlined));
      await tester.pumpAndSettle();

      final screen = tester.widget<HallAvailabilityScreen>(
        find.byType(HallAvailabilityScreen),
      );
      expect(screen.hotelId, 'h1');
      expect(screen.hallId, 'hall-1');
    },
  );

  testWidgets(
    'the edit action navigates to HallFormScreen pre-filled with the Hall',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          (r) async => successResponse(
            _hallJson(profileData: {'name': 'The Ivory Room'}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(HallFormScreen), findsOneWidget);
      expect(find.text('The Ivory Room'), findsWidgets);
    },
  );

  testWidgets(
    'saving an edit shows a success snackbar and returns to the refreshed details',
    (tester) async {
      // A stateful mock: the subsequent GET (details reload) reflects the
      // earlier PATCH, the same way a real server would persist it.
      var currentName = 'The Ivory Room';
      await tester.pumpWidget(
        _wrap((r) async {
          if (r.method == 'PATCH') {
            currentName = 'Renamed';
            return successResponse(
              _hallJson(profileData: {'name': currentName, 'capacity': 80}),
            );
          }
          return successResponse(
            _hallJson(profileData: {'name': currentName, 'capacity': 80}),
          );
        }),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Hall updated.'), findsOneWidget);
      expect(find.text('Renamed'), findsWidgets);
    },
  );

  testWidgets(
    'tapping a photo thumbnail opens the full-screen photo viewer on that photo',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          (r) async => successResponse(
            _hallJson(
              profileData: {'name': 'The Ivory Room'},
              photos: [
                {
                  'id': 'p1',
                  'type': 'PHOTO',
                  'url': 'https://example.com/1.jpg',
                },
                {
                  'id': 'p2',
                  'type': 'PHOTO',
                  'url': 'https://example.com/2.jpg',
                },
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(HHNetworkImage).first);
      await tester.pumpAndSettle();

      final viewer = tester.widget<HallPhotoViewerScreen>(
        find.byType(HallPhotoViewerScreen),
      );
      expect(viewer.photos, hasLength(2));
      expect(viewer.initialIndex, 0);
      expect(find.text('1 / 2'), findsOneWidget);
    },
  );

  testWidgets('Add Photos uploads every image selected in one picker action', (
    tester,
  ) async {
    var uploadCount = 0;
    final client = ApiClient(
      httpClient: MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/media/photos')) {
          uploadCount += 1;
          return successResponse({
            'id': 'p$uploadCount',
            'hallId': 'hall-1',
            'url': 'https://example.test/$uploadCount.jpg',
          }, status: 201);
        }
        return successResponse(
          _hallJson(profileData: {'name': 'The Ivory Room'}),
        );
      }),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(
      Provider<ApiClient>.value(
        value: client,
        child: MaterialApp(
          home: HallDetailsScreen(
            hotelId: 'h1',
            hallId: 'hall-1',
            pickImages: () async => const [
              PickedImageData(bytes: [1], filename: 'one.jpg'),
              PickedImageData(bytes: [2], filename: 'two.jpg'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add Photos'));
    await tester.pumpAndSettle();

    expect(uploadCount, 2);
    expect(find.text('2 photos added.'), findsOneWidget);
  });
}
