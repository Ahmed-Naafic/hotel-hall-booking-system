import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/notification_preference_controller.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/manager_settings_screen.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:provider/provider.dart';

http.Response _envelope(dynamic data) => http.Response(
  '{"status":"success","message":"ok","data":${data == null ? 'null' : '"$data"'}}',
  200,
);

Widget _wrap({Future<http.Response> Function(http.Request)? handler}) {
  final apiClient = ApiClient(
    httpClient: MockClient(handler ?? (_) async => _envelope(null)),
    baseUrl: 'http://test/api/v1',
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeController(storage: InMemoryTokenStorage())),
      ChangeNotifierProvider(create: (_) => NotificationController(NotificationRepository(apiClient))),
      ChangeNotifierProvider(create: (_) => NotificationPreferenceController(storage: InMemoryTokenStorage())),
    ],
    child: const MaterialApp(home: ManagerSettingsScreen()),
  );
}

class InMemoryTokenStorage implements TokenStorage {
  final Map<String, String> _values = {};
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> delete(String key) async => _values.remove(key);
}

void main() {
  testWidgets('shows the Appearance toggle and a Push notifications switch, on by default', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, true);
  });

  testWidgets('turning the switch off flips it, and back on flips it back', (tester) async {
    // `PushNotificationService.getToken()` returns null without real
    // Firebase configuration (this test environment), so
    // register/unregisterDeviceToken both no-op before any HTTP call — the
    // real device-token side effect is exercised on a configured device.
    // This asserts the preference itself, which is what this screen owns.
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, true);
  });
}
