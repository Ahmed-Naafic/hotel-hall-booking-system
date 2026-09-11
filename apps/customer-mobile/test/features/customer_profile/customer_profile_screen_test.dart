import 'dart:convert';

import 'package:customer_mobile/features/customer_profile/application/image_picker_service.dart';
import 'package:customer_mobile/features/customer_profile/presentation/customer_profile_screen.dart';
import 'package:customer_mobile/features/notifications/application/notification_controller.dart';
import 'package:customer_mobile/features/notifications/data/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

http.Response _envelope(dynamic data) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data}),
  200,
);

Map<String, dynamic> _meJson({
  String? fullName,
  bool hasProfile = true,
  bool isVerified = true,
  String? avatarUrl,
}) => {
  'user': {'id': 'user-1', 'mobileNumber': '+15551234567', 'accountType': 'CUSTOMER', 'isVerified': isVerified, 'isActive': true},
  'profile': hasProfile
      ? {
          'id': 'profile-1',
          'profileData': fullName != null ? {'fullName': fullName} : {},
          'avatarUrl': avatarUrl,
          'createdAt': '2026-09-08T00:00:00.000Z',
          'updatedAt': '2026-09-08T00:00:00.000Z',
        }
      : null,
  'readiness': {'profileExists': hasProfile, 'isComplete': null, 'missingRequiredFields': null},
};

Widget _wrap(
  Future<http.Response> Function(http.Request) handler, {
  ImagePickerFn pickImage = pickImageFromGallery,
}) {
  final sessionStore = SessionStore(storage: InMemoryTokenStorage());
  final apiClient = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  final auth = AuthController(repository: AuthRepository(apiClient), sessionStore: sessionStore)
    ..currentUser = AppUser.fromJson(testUser())
    ..status = AuthStatus.authenticated;

  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider(create: (_) => NotificationController(NotificationRepository(apiClient))),
    ],
    child: MaterialApp(home: CustomerProfileScreen(pickImage: pickImage)),
  );
}

void main() {
  testWidgets("shows the Customer's real Full Name and Mobile Number (BDR-018), no editor open", (tester) async {
    await tester.pumpWidget(_wrap((_) async => _envelope(_meJson(fullName: 'Amina Yusuf'))));
    await tester.pumpAndSettle();

    expect(find.text('Amina Yusuf'), findsOneWidget);
    // Once as the header's subtitle, once again in the Account section.
    expect(find.text('+15551234567'), findsNWidgets(2));
    expect(find.text('Add your name'), findsNothing);
    expect(find.byType(TextFormField), findsNothing, reason: 'no need to prompt for a name that already exists');
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('a pre-BDR-018 Customer with no profile can set their Full Name (POST)', (tester) async {
    String? capturedBody;
    String? capturedMethod;
    var reloaded = false;
    await tester.pumpWidget(_wrap((request) async {
      if (request.method == 'POST' && request.url.path.endsWith('/customers/me/profile')) {
        capturedMethod = 'POST';
        capturedBody = request.body;
        reloaded = true;
        return _envelope({'profile': _meJson(fullName: 'Amina Yusuf')['profile'], 'readiness': _meJson(fullName: 'Amina Yusuf')['readiness']});
      }
      return _envelope(_meJson(hasProfile: false));
    }));
    await tester.pumpAndSettle();

    expect(find.text('Add your name'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Amina Yusuf');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(capturedMethod, 'POST');
    expect(capturedBody, contains('"fullName":"Amina Yusuf"'));
    expect(reloaded, true);
  });

  testWidgets('a Customer with a profile but no Full Name yet can set one (PATCH)', (tester) async {
    String? capturedMethod;
    await tester.pumpWidget(_wrap((request) async {
      if (request.method == 'PATCH' && request.url.path.endsWith('/customers/me/profile')) {
        capturedMethod = 'PATCH';
        return _envelope({'profile': _meJson(fullName: 'Amina Yusuf')['profile'], 'readiness': _meJson(fullName: 'Amina Yusuf')['readiness']});
      }
      return _envelope(_meJson(hasProfile: true));
    }));
    await tester.pumpAndSettle();

    expect(find.text('Add your name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Amina Yusuf');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(capturedMethod, 'PATCH');
  });

  testWidgets('the Save button is disabled until a non-empty name is entered', (tester) async {
    await tester.pumpWidget(_wrap((_) async => _envelope(_meJson(hasProfile: false))));
    await tester.pumpAndSettle();

    final buttonBefore = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(buttonBefore.onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), 'Amina Yusuf');
    await tester.pump();

    final buttonAfter = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(buttonAfter.onPressed, isNotNull);
  });

  testWidgets('an already-named Customer can re-open the editor, and Cancel discards the change', (tester) async {
    var patchCalled = false;
    await tester.pumpWidget(_wrap((request) async {
      if (request.method == 'PATCH' && request.url.path.endsWith('/customers/me/profile')) {
        patchCalled = true;
        return _envelope({'profile': _meJson(fullName: 'Someone Else')['profile'], 'readiness': _meJson(fullName: 'Someone Else')['readiness']});
      }
      return _envelope(_meJson(fullName: 'Amina Yusuf'));
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller?.text, 'Amina Yusuf', reason: 'the editor pre-fills the existing name');

    await tester.enterText(find.byType(TextFormField), 'Someone Else');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(patchCalled, false);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Amina Yusuf'), findsOneWidget);
  });

  testWidgets('shows Verification status and Member since in the Account section', (tester) async {
    await tester.pumpWidget(_wrap((_) async => _envelope(_meJson(fullName: 'Amina Yusuf', isVerified: true))));
    await tester.pumpAndSettle();

    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('2026-09-08'), findsOneWidget);
  });

  testWidgets('shows "Not verified" for an unverified Customer', (tester) async {
    await tester.pumpWidget(_wrap((_) async => _envelope(_meJson(fullName: 'Amina Yusuf', isVerified: false))));
    await tester.pumpAndSettle();

    expect(find.text('Not verified'), findsOneWidget);
  });

  testWidgets('a Customer with no avatar sees the initials fallback and a camera badge', (tester) async {
    await tester.pumpWidget(_wrap((_) async => _envelope(_meJson(fullName: 'Amina Yusuf'))));
    await tester.pumpAndSettle();

    expect(find.text('AY'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a Customer with an avatar sees it rendered instead of initials', (tester) async {
    await tester.pumpWidget(_wrap(
      (_) async => _envelope(_meJson(fullName: 'Amina Yusuf', avatarUrl: 'http://test/avatar.png')),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('tapping the avatar and choosing "Choose from gallery" uploads the picked photo', (tester) async {
    String? capturedMethod;
    String? capturedPath;
    await tester.pumpWidget(_wrap(
      (request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/customers/me/avatar')) {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          return _envelope({
            'profile': _meJson(fullName: 'Amina Yusuf', avatarUrl: 'http://test/avatar.png')['profile'],
            'readiness': _meJson(fullName: 'Amina Yusuf')['readiness'],
          });
        }
        return _envelope(_meJson(fullName: 'Amina Yusuf'));
      },
      pickImage: () async => PickedImageData(bytes: [1, 2, 3], filename: 'photo.jpg'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing, reason: 'no avatar yet, so nothing to remove');

    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(capturedMethod, 'POST');
    expect(capturedPath, endsWith('/customers/me/avatar'));
  });

  testWidgets('when the picker returns nothing (cancelled), no upload is made', (tester) async {
    var uploadCalled = false;
    await tester.pumpWidget(_wrap(
      (request) async {
        if (request.url.path.endsWith('/customers/me/avatar')) uploadCalled = true;
        return _envelope(_meJson(fullName: 'Amina Yusuf'));
      },
      pickImage: () async => null,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(uploadCalled, false);
  });

  testWidgets('a Customer with an avatar can remove it via the bottom sheet', (tester) async {
    String? capturedMethod;
    String? capturedPath;
    await tester.pumpWidget(_wrap((request) async {
      if (request.method == 'DELETE' && request.url.path.endsWith('/customers/me/avatar')) {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        return _envelope({
          'profile': _meJson(fullName: 'Amina Yusuf')['profile'],
          'readiness': _meJson(fullName: 'Amina Yusuf')['readiness'],
        });
      }
      return _envelope(_meJson(fullName: 'Amina Yusuf', avatarUrl: 'http://test/avatar.png'));
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    expect(find.text('Remove photo'), findsOneWidget);

    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();

    expect(capturedMethod, 'DELETE');
    expect(capturedPath, endsWith('/customers/me/avatar'));
  });

  testWidgets('an upload failure shows an error snackbar', (tester) async {
    await tester.pumpWidget(_wrap(
      (request) async {
        if (request.url.path.endsWith('/customers/me/avatar')) {
          return http.Response(jsonEncode({'status': 'error', 'message': 'failed'}), 500);
        }
        return _envelope(_meJson(fullName: 'Amina Yusuf'));
      },
      pickImage: () async => PickedImageData(bytes: [1, 2, 3], filename: 'photo.jpg'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Could not upload your photo.'), findsOneWidget);
  });

  testWidgets('tapping "Log out" clears the session and pops the screen', (tester) async {
    var logoutCalled = false;
    await tester.pumpWidget(_wrap((request) async {
      if (request.url.path.endsWith('/auth/logout')) {
        logoutCalled = true;
        return http.Response('', 204);
      }
      return _envelope(_meJson(fullName: 'Amina Yusuf'));
    }));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(CustomerProfileScreen));
    final auth = context.read<AuthController>();

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(logoutCalled, true);
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.currentUser, isNull);
  });
}
