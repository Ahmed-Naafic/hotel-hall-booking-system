import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/halls/data/hall_models.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_form_screen.dart';
import 'package:manager_mobile/features/hotel/application/image_picker_service.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Map<String, dynamic> _hallJson({
  String id = 'hall-1',
  Map<String, dynamic>? profileData,
}) => {
  'id': id,
  'hotelId': 'h1',
  'profileData': profileData,
  'createdAt': '2026-08-25T00:00:00.000Z',
  'updatedAt': '2026-08-25T00:00:00.000Z',
};

Widget _wrap(
  Widget child,
  Future<http.Response> Function(http.Request) handler,
) {
  final client = ApiClient(
    httpClient: MockClient((request) {
      if (request.method == 'GET' && request.url.path.endsWith('/media')) {
        return Future.value(successResponse({'photos': []}));
      }
      return handler(request);
    }),
    baseUrl: 'http://test/api/v1',
  );
  return Provider<ApiClient>.value(
    value: client,
    child: MaterialApp(home: child),
  );
}

/// `find.text('Create Hall')` is ambiguous — it matches both the AppBar
/// title and the submit button; this targets the button specifically.
Finder _submitButton(String label) =>
    find.widgetWithText(ElevatedButton, label);

Future<void> _fillRequiredFields(
  WidgetTester tester, {
  String name = 'The Gallery',
  String capacity = '80',
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Hall Name'), name);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Capacity'),
    capacity,
  );
}

void main() {
  // The structured form (standard fields + Hall Photos placeholder +
  // Additional Information) is taller than the default 800x600 test
  // surface, which would leave the submit button off-screen.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  group('Required field validation (BR-HALL-07, BDR-016)', () {
    testWidgets(
      'submitting with nothing filled shows Hall Name and Capacity errors, never calls the API',
      (tester) async {
        var called = false;
        await tester.pumpWidget(
          _wrap(const HallFormScreen(hotelId: 'h1'), (r) async {
            called = true;
            throw StateError('should not be called');
          }),
        );

        await tester.tap(_submitButton('Create Hall'));
        await tester.pumpAndSettle();

        expect(called, false);
        expect(find.text('Hall Name is required.'), findsOneWidget);
        expect(find.text('Capacity is required.'), findsOneWidget);
      },
    );

    testWidgets('rejects a non-numeric Capacity, never calls the API', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(const HallFormScreen(hotelId: 'h1'), (r) async {
          called = true;
          throw StateError('should not be called');
        }),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Hall Name'),
        'The Gallery',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Capacity'),
        'a lot',
      );
      await tester.tap(_submitButton('Create Hall'));
      await tester.pumpAndSettle();

      expect(called, false);
      expect(
        find.text('Capacity must be a valid positive number.'),
        findsOneWidget,
      );
    });

    testWidgets('Description and Location have no required-field validator', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const HallFormScreen(hotelId: 'h1'),
          (r) async => successResponse(
            _hallJson(profileData: {'name': 'The Gallery', 'capacity': 80}),
          ),
        ),
      );

      await _fillRequiredFields(tester);
      await tester.tap(_submitButton('Create Hall'));
      await tester.pumpAndSettle();

      expect(find.textContaining('is required.'), findsNothing);
    });
  });

  group('Create Hall', () {
    testWidgets('required fields are sent, wrapped in profileData', (
      tester,
    ) async {
      Map<String, dynamic>? sentBody;
      await tester.pumpWidget(
        _wrap(const HallFormScreen(hotelId: 'h1'), (r) async {
          sentBody = {'method': r.method, 'body': r.body};
          return successResponse(
            _hallJson(profileData: {'name': 'The Gallery', 'capacity': 80}),
            status: 201,
          );
        }),
      );

      await _fillRequiredFields(tester);
      await tester.tap(_submitButton('Create Hall'));
      await tester.pumpAndSettle();

      expect(sentBody!['method'], 'POST');
      final body = sentBody!['body'] as String;
      expect(body, contains('"profileData"'));
      expect(body, contains('"name":"The Gallery"'));
      expect(body, contains('"capacity":80'));
    });

    testWidgets(
      'optional Description and Location are included when filled, omitted when blank',
      (tester) async {
        Map<String, dynamic>? sentBody;
        await tester.pumpWidget(
          _wrap(const HallFormScreen(hotelId: 'h1'), (r) async {
            sentBody = {'body': r.body};
            return successResponse(
              _hallJson(profileData: {'name': 'The Gallery', 'capacity': 80}),
              status: 201,
            );
          }),
        );

        await _fillRequiredFields(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Description (optional)'),
          'A bright, airy room.',
        );
        await tester.tap(_submitButton('Create Hall'));
        await tester.pumpAndSettle();

        final body = sentBody!['body'] as String;
        expect(body, contains('"description":"A bright, airy room."'));
        expect(body, isNot(contains('"location"')));
      },
    );

    testWidgets(
      'adding a custom field submits it alongside the standard fields',
      (tester) async {
        Map<String, dynamic>? sentBody;
        await tester.pumpWidget(
          _wrap(const HallFormScreen(hotelId: 'h1'), (r) async {
            sentBody = {'body': r.body};
            return successResponse(
              _hallJson(
                profileData: {
                  'name': 'The Gallery',
                  'capacity': 80,
                  'amenities': 'Stage',
                },
              ),
              status: 201,
            );
          }),
        );

        await _fillRequiredFields(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Field name'),
          'amenities',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'),
          'Stage',
        );
        await tester.tap(_submitButton('Create Hall'));
        await tester.pumpAndSettle();

        final body = sentBody!['body'] as String;
        expect(body, contains('"amenities":"Stage"'));
        expect(body, contains('"name":"The Gallery"'));
      },
    );

    testWidgets(
      'a custom field reusing a reserved standard name is rejected — never sent',
      (tester) async {
        var called = false;
        await tester.pumpWidget(
          _wrap(const HallFormScreen(hotelId: 'h1'), (r) async {
            called = true;
            return successResponse(_hallJson(), status: 201);
          }),
        );

        await _fillRequiredFields(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Field name'),
          'capacity',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'),
          '9999',
        );
        await tester.tap(_submitButton('Create Hall'));
        await tester.pumpAndSettle();

        expect(called, false);
        expect(
          find.textContaining('cannot reuse a standard field name'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows a loading state while submitting', (tester) async {
      await tester.pumpWidget(
        _wrap(const HallFormScreen(hotelId: 'h1'), (r) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return successResponse(
            _hallJson(profileData: {'name': 'The Gallery', 'capacity': 80}),
            status: 201,
          );
        }),
      );

      await _fillRequiredFields(tester);
      await tester.tap(_submitButton('Create Hall'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'an API error is shown and the form stays open (success feedback is the caller\'s job, not this screen\'s)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const HallFormScreen(hotelId: 'h1'),
            (r) async => errorResponse('NOT_FOUND', 'Hotel not found.', 404),
          ),
        );

        await _fillRequiredFields(tester);
        await tester.tap(_submitButton('Create Hall'));
        await tester.pumpAndSettle();

        expect(find.text('Hotel not found.'), findsOneWidget);
        expect(find.byType(HallFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      'the request always targets the given hotelId, never an arbitrary one',
      (tester) async {
        Map<String, dynamic>? sent;
        await tester.pumpWidget(
          _wrap(const HallFormScreen(hotelId: 'h1'), (r) async {
            sent = {'path': r.url.path};
            return successResponse(
              _hallJson(profileData: {'name': 'The Gallery', 'capacity': 80}),
              status: 201,
            );
          }),
        );

        await _fillRequiredFields(tester);
        await tester.tap(_submitButton('Create Hall'));
        await tester.pumpAndSettle();

        expect(sent!['path'], '/api/v1/hotels/h1/halls');
      },
    );
  });

  group('Edit Hall', () {
    final existingHall = Hall(
      id: 'hall-1',
      hotelId: 'h1',
      profileData: const {
        'name': 'Original',
        'capacity': 50,
        'description': 'Cozy.',
        'location': 'First floor',
        'amenities': 'Projector',
      },
      createdAt: DateTime.parse('2026-08-25T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-08-25T00:00:00.000Z'),
    );

    testWidgets(
      'pre-fills existing standard fields and existing custom fields separately',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            HallFormScreen(hotelId: 'h1', existingHall: existingHall),
            (r) async => successResponse(
              _hallJson(profileData: existingHall.profileData),
            ),
          ),
        );

        expect(find.text('Original'), findsOneWidget);
        expect(find.text('50'), findsOneWidget);
        expect(find.text('Cozy.'), findsOneWidget);
        expect(find.text('First floor'), findsOneWidget);
        expect(find.text('amenities'), findsOneWidget);
        expect(find.text('Projector'), findsOneWidget);
      },
    );

    testWidgets(
      'sends a PATCH with the current standard-field values on save',
      (tester) async {
        Map<String, dynamic>? sentBody;
        await tester.pumpWidget(
          _wrap(HallFormScreen(hotelId: 'h1', existingHall: existingHall), (
            r,
          ) async {
            sentBody = {'method': r.method, 'path': r.url.path, 'body': r.body};
            return successResponse(
              _hallJson(
                profileData: {...existingHall.profileData!, 'name': 'Renamed'},
              ),
            );
          }),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Hall Name'),
          'Renamed',
        );
        await tester.tap(_submitButton('Save changes'));
        await tester.pumpAndSettle();

        expect(sentBody!['method'], 'PATCH');
        expect(sentBody!['path'], '/api/v1/hotels/h1/halls/hall-1');
        final body = sentBody!['body'] as String;
        expect(body, contains('"name":"Renamed"'));
        expect(body, contains('"capacity":50'));
      },
    );

    testWidgets('rejects clearing Hall Name to empty', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(HallFormScreen(hotelId: 'h1', existingHall: existingHall), (
          r,
        ) async {
          called = true;
          throw StateError('should not be called');
        }),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Hall Name'),
        '',
      );
      await tester.tap(_submitButton('Save changes'));
      await tester.pumpAndSettle();

      expect(called, false);
      expect(find.text('Hall Name is required.'), findsOneWidget);
    });

    testWidgets('an API error is shown, existing values remain editable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          HallFormScreen(hotelId: 'h1', existingHall: existingHall),
          (r) async => errorResponse('NOT_FOUND', 'Hall not found.', 404),
        ),
      );

      await tester.tap(_submitButton('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Hall not found.'), findsOneWidget);
      expect(find.text('Original'), findsOneWidget);
    });
  });

  group('Hall Photos', () {
    testWidgets(
      'explains that a Hall must be created before photos can be uploaded',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const HallFormScreen(hotelId: 'h1'),
            (r) async => successResponse(_hallJson()),
          ),
        );

        expect(
          find.text('Create the Hall first, then add photos from Edit Hall.'),
          findsOneWidget,
        );
        expect(find.widgetWithText(OutlinedButton, 'Add Photos'), findsNothing);
      },
    );

    testWidgets('edit mode uploads a selected Hall photo', (tester) async {
      var uploaded = false;
      final hall = Hall(
        id: 'hall-1',
        hotelId: 'h1',
        profileData: const {'name': 'The Gallery', 'capacity': 80},
        createdAt: DateTime.parse('2026-08-25T00:00:00.000Z'),
        updatedAt: DateTime.parse('2026-08-25T00:00:00.000Z'),
      );
      await tester.pumpWidget(
        _wrap(
          HallFormScreen(
            hotelId: 'h1',
            existingHall: hall,
            pickImage: () async => const PickedImageData(
              bytes: [0xff, 0xd8, 0xff],
              filename: 'hall.jpg',
            ),
          ),
          (request) async {
            uploaded =
                request.method == 'POST' &&
                request.url.path.endsWith('/media/photos');
            return successResponse({
              'id': 'photo-1',
              'hallId': 'hall-1',
              'type': 'PHOTO',
              'url': 'https://example.test/hall.jpg',
              'createdAt': '2026-08-31T00:00:00.000Z',
              'updatedAt': '2026-08-31T00:00:00.000Z',
            }, status: 201);
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add Photos'));
      await tester.pumpAndSettle();

      expect(uploaded, true);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
