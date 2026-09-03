import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/application/image_picker_service.dart';
import 'package:manager_mobile/features/hotel/data/hotel_models.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/hotel_profile_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../../test_support.dart';

Map<String, dynamic> _hotelJson({
  String status = 'REGISTERED',
  Map<String, dynamic>? profileData,
}) => {
  'id': 'h1',
  'registeredByUserId': 'u1',
  'status': status,
  'profileData': profileData,
  'createdAt': '2026-08-25T00:00:00.000Z',
  'updatedAt': '2026-08-25T00:00:00.000Z',
};

Finder _submitButton() =>
    find.widgetWithText(ElevatedButton, 'Save & Continue');

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.tap(_submitButton());
  await tester.pumpAndSettle();
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Hotel Name'),
    'The Grand Hall Hotel',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Description'),
    'A premium event venue.',
  );
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
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Contact Phone'),
    '+254700000000',
  );
}

/// The screen also loads Hotel Media (`GET .../media`) on mount, via its own
/// independent `HotelMediaController` — unrelated to the profile-field
/// tests in this file, which only care about the `PATCH` under test.
/// Answering it here with an empty collection keeps every other test
/// focused on its own concern, without needing to special-case the media
/// request itself.
Future<http.Response> _withMediaStub(
  http.Request r,
  Future<http.Response> Function(http.Request) handler,
) {
  if (r.method == 'GET' && r.url.path.endsWith('/media')) {
    return Future.value(successResponse({'logo': null, 'photos': []}));
  }
  if (r.method == 'POST' && r.url.path.endsWith('/location/reverse-geocode')) {
    return Future.value(
      successResponse({'available': true, 'address': 'Nairobi, Kenya'}),
    );
  }
  return handler(r);
}

Widget _wrap(
  Future<http.Response> Function(http.Request) handler, {
  Map<String, dynamic>? existingProfileData,
  String hotelStatus = 'REGISTERED',
  ImagePickerFn pickImage = _defaultTestPicker,
}) {
  final apiClient = ApiClient(
    httpClient: MockClient((r) => _withMediaStub(r, handler)),
    baseUrl: 'http://test/api/v1',
  );
  final hotelContext =
      HotelContextController(
          repository: HotelRepository(apiClient),
          storage: InMemoryTokenStorage(),
        )
        ..hotel = Hotel.fromJson(
          _hotelJson(status: hotelStatus, profileData: existingProfileData),
        );
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<HotelContextController>.value(value: hotelContext),
    ],
    child: MaterialApp(
      home: HotelProfileFormScreen(
        pickImage: pickImage,
        showLocationMapTiles: false,
      ),
    ),
  );
}

Future<PickedImageData?> _defaultTestPicker() async =>
    const PickedImageData(bytes: [0xff, 0xd8, 0xff], filename: 'photo.jpg');

void main() {
  // This form (structured fields + media placeholders + Additional
  // Information) is taller than the default 800x600 test surface, which
  // would leave the submit button off-screen and unable to receive a real
  // tap. Enlarging the surface for this file's tests is simpler and more
  // robust than scrolling before every tap.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  group('Required field validation (BR-HOTEL-02, BDR-015)', () {
    testWidgets(
      'submitting with nothing filled shows all four required-field errors and never calls the API',
      (tester) async {
        var called = false;
        await tester.pumpWidget(
          _wrap((r) async {
            called = true;
            throw StateError('should not be called');
          }),
        );

        await _tapSubmit(tester);

        expect(called, false);
        expect(find.text('Hotel Name is required.'), findsOneWidget);
        expect(find.text('Description is required.'), findsOneWidget);
        expect(find.text('Location is required.'), findsOneWidget);
        expect(find.text('Contact Phone is required.'), findsOneWidget);
      },
    );

    testWidgets(
      'Email has no required-field validator — no error shown when left blank',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            (r) async =>
                successResponse(_hotelJson(status: 'PROFILE_COMPLETE')),
          ),
        );

        await _tapSubmit(tester);

        expect(find.text('Email is required.'), findsNothing);
      },
    );
  });

  group('Saving the profile', () {
    testWidgets(
      'all four required fields plus optional email are sent as an unwrapped PATCH body',
      (tester) async {
        Map<String, dynamic>? sent;
        late HotelContextController capturedContext;
        final apiClient = ApiClient(
          httpClient: MockClient(
            (r) => _withMediaStub(r, (r) async {
              sent = {'method': r.method, 'path': r.url.path, 'body': r.body};
              return successResponse(
                _hotelJson(
                  status: 'PROFILE_COMPLETE',
                  profileData: {
                    'name': 'The Grand Hall Hotel',
                    'description': 'A premium event venue.',
                    'location': {
                      'latitude': -1.286389,
                      'longitude': 36.817223,
                      'address': 'Nairobi, Kenya',
                    },
                    'contactPhone': '+254700000000',
                    'email': 'contact@grandhall.example',
                  },
                ),
              );
            }),
          ),
          baseUrl: 'http://test/api/v1',
        );
        final hotelContext = HotelContextController(
          repository: HotelRepository(apiClient),
          storage: InMemoryTokenStorage(),
        )..hotel = Hotel.fromJson(_hotelJson());
        capturedContext = hotelContext;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<ApiClient>.value(value: apiClient),
              ChangeNotifierProvider<HotelContextController>.value(
                value: hotelContext,
              ),
            ],
            child: const MaterialApp(
              home: HotelProfileFormScreen(showLocationMapTiles: false),
            ),
          ),
        );

        await _fillRequiredFields(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email (optional)'),
          'contact@grandhall.example',
        );
        await _tapSubmit(tester);

        expect(sent!['method'], 'PATCH');
        expect(sent!['path'], '/api/v1/hotels/h1');
        final body = sent!['body'] as String;
        expect(body, contains('"name":"The Grand Hall Hotel"'));
        expect(body, contains('"description":"A premium event venue."'));
        expect(body, contains('"location":{'));
        expect(body, contains('"address":"Nairobi, Kenya"'));
        expect(body, contains('"contactPhone":"+254700000000"'));
        expect(body, contains('"email":"contact@grandhall.example"'));
        expect(capturedContext.hotel?.status, 'PROFILE_COMPLETE');
      },
    );

    testWidgets(
      'leaving Email blank omits the email key entirely (never sent as an empty string)',
      (tester) async {
        Map<String, dynamic>? sent;
        await tester.pumpWidget(
          _wrap((r) async {
            sent = {'body': r.body};
            return successResponse(_hotelJson(status: 'PROFILE_COMPLETE'));
          }),
        );

        await _fillRequiredFields(tester);
        await _tapSubmit(tester);

        expect(sent!['body'], isNot(contains('"email"')));
      },
    );

    testWidgets('shows a loading state while saving', (tester) async {
      await tester.pumpWidget(
        _wrap((r) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return successResponse(_hotelJson(status: 'PROFILE_COMPLETE'));
        }),
      );

      await _fillRequiredFields(tester);
      await tester.ensureVisible(_submitButton());
      await tester.pumpAndSettle();
      await tester.tap(_submitButton());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('Existing profile data', () {
    testWidgets(
      'pre-fills existing standard fields and existing custom fields separately',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            (r) async => successResponse(
              _hotelJson(
                profileData: {
                  'name': 'Original Name',
                  'description': 'Original description.',
                  'location': {
                    'latitude': -1.2,
                    'longitude': 36.8,
                    'address': 'Original Location',
                  },
                  'contactPhone': '+10000000000',
                  'amenities': 'Pool, Spa',
                },
              ),
            ),
            existingProfileData: {
              'name': 'Original Name',
              'description': 'Original description.',
              'location': {
                'latitude': -1.2,
                'longitude': 36.8,
                'address': 'Original Location',
              },
              'contactPhone': '+10000000000',
              'amenities': 'Pool, Spa',
            },
          ),
        );

        expect(find.text('Original Name'), findsOneWidget);
        expect(find.text('Original description.'), findsOneWidget);
        expect(find.text('Original Location'), findsOneWidget);
        expect(find.text('+10000000000'), findsOneWidget);
        // The custom field ("amenities") appears in Additional Information,
        // not duplicated into a standard field.
        expect(find.text('amenities'), findsOneWidget);
        expect(find.text('Pool, Spa'), findsOneWidget);
      },
    );
  });

  group('Custom (Additional Information) fields', () {
    testWidgets('a custom field is sent alongside the standard fields', (
      tester,
    ) async {
      Map<String, dynamic>? sent;
      await tester.pumpWidget(
        _wrap((r) async {
          sent = {'body': r.body};
          return successResponse(_hotelJson(status: 'PROFILE_COMPLETE'));
        }),
      );

      await _fillRequiredFields(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Field name'),
        'amenities',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Value'),
        'Pool, Spa',
      );
      await _tapSubmit(tester);

      expect(sent!['body'], contains('"amenities":"Pool, Spa"'));
      expect(sent!['body'], contains('"name":"The Grand Hall Hotel"'));
    });

    testWidgets(
      'an empty custom-field row is silently skipped, not sent as an empty key',
      (tester) async {
        Map<String, dynamic>? sent;
        await tester.pumpWidget(
          _wrap((r) async {
            sent = {'body': r.body};
            return successResponse(_hotelJson(status: 'PROFILE_COMPLETE'));
          }),
        );

        await _fillRequiredFields(tester);
        // The Additional Information editor starts with one empty row by
        // default — left untouched here.
        await _tapSubmit(tester);

        expect(sent!['body'], isNot(contains('""')));
      },
    );

    testWidgets(
      'a custom field reusing a reserved standard name is rejected — never sent, never substitutes for the real field',
      (tester) async {
        var called = false;
        await tester.pumpWidget(
          _wrap((r) async {
            called = true;
            return successResponse(_hotelJson(status: 'PROFILE_COMPLETE'));
          }),
        );

        await _fillRequiredFields(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Field name'),
          'name',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'),
          'A sneaky override',
        );
        await _tapSubmit(tester);

        expect(called, false);
        expect(
          find.textContaining('cannot reuse a standard field name'),
          findsOneWidget,
        );
      },
    );
  });

  group('API failures', () {
    testWidgets(
      'an unauthorized (401) API failure is shown and the form stays open',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            (r) async => errorResponse(
              'AUTHENTICATION_ERROR',
              'Missing, invalid, or expired access token.',
              401,
            ),
          ),
        );

        await _fillRequiredFields(tester);
        await _tapSubmit(tester);

        expect(
          find.text('Missing, invalid, or expired access token.'),
          findsOneWidget,
        );
        expect(find.byType(HotelProfileFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      'a cross-tenant/not-found (404) API failure surfaces the server message without crashing',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            (r) async => errorResponse(
              'NOT_FOUND',
              'Not found, or belongs to a different Hotel Manager.',
              404,
            ),
          ),
        );

        await _fillRequiredFields(tester);
        await _tapSubmit(tester);

        expect(
          find.text('Not found, or belongs to a different Hotel Manager.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Status-aware wording (APPROVED_ACTIVE / REJECTED edit, not onboarding)', () {
    testWidgets(
      'an APPROVED_ACTIVE Hotel shows "Edit Hotel Profile" / "Save Changes" instead of onboarding wording',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            (r) async => successResponse(_hotelJson(status: 'APPROVED_ACTIVE')),
            hotelStatus: 'APPROVED_ACTIVE',
          ),
        );

        expect(find.text('Edit Hotel Profile'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget);
        expect(find.text('Complete Hotel Profile'), findsNothing);
        expect(find.widgetWithText(ElevatedButton, 'Save & Continue'), findsNothing);
      },
    );

    testWidgets(
      'a REJECTED Hotel also shows edit wording, not onboarding wording',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            (r) async => successResponse(_hotelJson(status: 'REJECTED')),
            hotelStatus: 'REJECTED',
          ),
        );

        expect(find.text('Edit Hotel Profile'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget);
      },
    );

    testWidgets(
      'saving an APPROVED_ACTIVE Hotel correctly parses the nested {applied, hotel, criticalChangeRequestId} PATCH response',
      (tester) async {
        late HotelContextController capturedContext;
        final apiClient = ApiClient(
          httpClient: MockClient(
            (r) => _withMediaStub(r, (r) async {
              return successResponse({
                'applied': true,
                'hotel': _hotelJson(
                  status: 'APPROVED_ACTIVE',
                  profileData: {
                    'name': 'The Grand Hall Hotel',
                    'description': 'A premium event venue.',
                    'location': {
                      'latitude': -1.286389,
                      'longitude': 36.817223,
                      'address': 'Nairobi, Kenya',
                    },
                    'contactPhone': '+254700000000',
                  },
                ),
                'criticalChangeRequestId': null,
              });
            }),
          ),
          baseUrl: 'http://test/api/v1',
        );
        final hotelContext = HotelContextController(
          repository: HotelRepository(apiClient),
          storage: InMemoryTokenStorage(),
        )..hotel = Hotel.fromJson(_hotelJson(status: 'APPROVED_ACTIVE'));
        capturedContext = hotelContext;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<ApiClient>.value(value: apiClient),
              ChangeNotifierProvider<HotelContextController>.value(
                value: hotelContext,
              ),
            ],
            child: const MaterialApp(
              home: HotelProfileFormScreen(showLocationMapTiles: false),
            ),
          ),
        );

        await _fillRequiredFields(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
        await tester.pumpAndSettle();

        // No crash from the nested response shape, the screen closed
        // (popped(true)) on success, and the shared HotelContextController
        // was updated from the unwrapped `hotel` key, not the envelope.
        expect(find.byType(HotelProfileFormScreen), findsNothing);
        expect(capturedContext.hotel?.status, 'APPROVED_ACTIVE');
        expect(capturedContext.hotel?.profileData?['name'], 'The Grand Hall Hotel');
      },
    );
  });

  group('Own-Hotel scoping', () {
    testWidgets(
      'the PATCH always targets the Hotel resolved by HotelContextController, never a manually-entered id',
      (tester) async {
        Map<String, dynamic>? sent;
        await tester.pumpWidget(
          _wrap((r) async {
            sent = {'path': r.url.path};
            return successResponse(_hotelJson(status: 'PROFILE_COMPLETE'));
          }),
        );

        await _fillRequiredFields(tester);
        await _tapSubmit(tester);

        expect(sent!['path'], '/api/v1/hotels/h1');
      },
    );
  });

  group('Hotel Media (BDR-015, ADR-0006)', () {
    Widget wrapWithMediaHandler(
      Future<http.Response> Function(http.Request) handler, {
      ImagePickerFn? pickImage,
    }) {
      final apiClient = ApiClient(
        httpClient: MockClient(handler),
        baseUrl: 'http://test/api/v1',
      );
      final hotelContext = HotelContextController(
        repository: HotelRepository(apiClient),
        storage: InMemoryTokenStorage(),
      )..hotel = Hotel.fromJson(_hotelJson());
      return MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider<HotelContextController>.value(
            value: hotelContext,
          ),
        ],
        child: MaterialApp(
          home: HotelProfileFormScreen(
            pickImage: pickImage ?? _defaultTestPicker,
          ),
        ),
      );
    }

    testWidgets(
      'shows "Upload Logo" when no logo exists yet, and uploading switches it to "Replace Logo"',
      (tester) async {
        var uploadCalled = false;
        await tester.pumpWidget(
          wrapWithMediaHandler((r) async {
            if (r.method == 'GET')
              return successResponse({'logo': null, 'photos': []});
            uploadCalled = true;
            return successResponse({
              'id': 'logo1',
              'hotelId': 'h1',
              'type': 'LOGO',
              'url':
                  'https://mock-storage.local/hotel-media/hotels/h1/logo/logo1.jpg',
              'createdAt': '2026-08-26T00:00:00.000Z',
              'updatedAt': '2026-08-26T00:00:00.000Z',
            }, status: 201);
          }),
        );
        await tester.pump();

        expect(
          find.widgetWithText(OutlinedButton, 'Upload Logo'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(OutlinedButton, 'Upload Logo'));
        await tester.pump();
        await tester.pump();

        expect(uploadCalled, true);
        expect(
          find.widgetWithText(OutlinedButton, 'Replace Logo'),
          findsOneWidget,
        );
      },
    );

    testWidgets('loads and displays an existing logo and photos', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMediaHandler(
          (r) async => successResponse({
            'logo': {
              'id': 'logo1',
              'hotelId': 'h1',
              'type': 'LOGO',
              'url':
                  'https://mock-storage.local/hotel-media/hotels/h1/logo/logo1.jpg',
              'createdAt': '2026-08-26T00:00:00.000Z',
              'updatedAt': '2026-08-26T00:00:00.000Z',
            },
            'photos': [
              {
                'id': 'p1',
                'hotelId': 'h1',
                'type': 'PHOTO',
                'url':
                    'https://mock-storage.local/hotel-media/hotels/h1/photos/p1.jpg',
                'createdAt': '2026-08-26T00:00:00.000Z',
                'updatedAt': '2026-08-26T00:00:00.000Z',
              },
            ],
          }),
        ),
      );
      await tester.pump();

      expect(
        find.widgetWithText(OutlinedButton, 'Replace Logo'),
        findsOneWidget,
      );
      // Two Image.network widgets: the logo thumbnail and the one photo thumbnail.
      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets(
      'deleting the logo removes it and reverts the button to "Upload Logo"',
      (tester) async {
        var deleteCalled = false;
        await tester.pumpWidget(
          wrapWithMediaHandler((r) async {
            if (r.method == 'DELETE') {
              deleteCalled = true;
              return http.Response('', 204);
            }
            return successResponse({
              'logo': {
                'id': 'logo1',
                'hotelId': 'h1',
                'type': 'LOGO',
                'url':
                    'https://mock-storage.local/hotel-media/hotels/h1/logo/logo1.jpg',
                'createdAt': '2026-08-26T00:00:00.000Z',
                'updatedAt': '2026-08-26T00:00:00.000Z',
              },
              'photos': [],
            });
          }),
        );
        await tester.pump();
        expect(
          find.widgetWithText(OutlinedButton, 'Replace Logo'),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Delete logo'));
        await tester.pump();
        await tester.pump();

        expect(deleteCalled, true);
        expect(
          find.widgetWithText(OutlinedButton, 'Upload Logo'),
          findsOneWidget,
        );
      },
    );

    testWidgets('an upload API failure shows the server message', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMediaHandler((r) async {
          if (r.method == 'GET')
            return successResponse({'logo': null, 'photos': []});
          return errorResponse(
            'VALIDATION_ERROR',
            'Unsupported file type. Allowed formats: JPEG, PNG, WebP.',
            400,
          );
        }),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Upload Logo'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Unsupported file type. Allowed formats: JPEG, PNG, WebP.'),
        findsOneWidget,
      );
    });

    testWidgets('cancelling the picker never sends an upload request', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        wrapWithMediaHandler((r) async {
          called = true;
          return successResponse({'logo': null, 'photos': []});
        }, pickImage: () async => null),
      );
      await tester.pump();
      called = false; // reset after the initial GET /media load

      await tester.tap(find.widgetWithText(OutlinedButton, 'Upload Logo'));
      await tester.pump();
      await tester.pump();

      expect(called, false);
    });
  });
}
