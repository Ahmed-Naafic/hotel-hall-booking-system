import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/chat/presentation/screens/chat_screen.dart';
import 'package:provider/provider.dart';

/// Communication V1 — Manager Mobile's `ChatScreen`. Covers the message
/// list (oldest first, sender-side bubble alignment), sending a new
/// message, mark-conversation-read on open, and the empty state — the
/// backend is mocked at the HTTP boundary, the same pattern
/// `notification_center_screen_test.dart` already uses.
http.Response _envelope(dynamic data, {Map<String, dynamic>? pagination}) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data, if (pagination != null) 'pagination': pagination}),
  200,
);

Map<String, dynamic> _messageJson({
  String id = 'm1',
  String senderUserId = 'manager-1',
  String body = 'Hello there',
}) => {
  'id': id,
  'senderUserId': senderUserId,
  'body': body,
  'readAt': null,
  'createdAt': '2026-09-14T00:00:00.000Z',
};

class _InMemoryTokenStorage implements TokenStorage {
  final Map<String, String> _values = {};
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> delete(String key) async => _values.remove(key);
}

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final apiClient = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  final authController = AuthController(
    repository: AuthRepository(apiClient),
    sessionStore: SessionStore(storage: _InMemoryTokenStorage()),
  );
  authController.currentUser = const AppUser(
    id: 'manager-1',
    mobileNumber: '+15550000000',
    accountType: 'HOTEL_MANAGER',
    isVerified: true,
    isActive: true,
  );
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<AuthController>.value(value: authController),
    ],
    child: const MaterialApp(home: ChatScreen(bookingId: 'b1')),
  );
}

void main() {
  testWidgets('renders messages oldest-first, aligning the caller\'s own on the right', (tester) async {
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/bookings/b1/messages') && request.method == 'GET') {
          return _envelope(
            [_messageJson(id: 'm1', senderUserId: 'customer-1', body: 'Can we add extra chairs?'), _messageJson(id: 'm2', senderUserId: 'manager-1', body: 'Sure, no problem.')],
            pagination: {'limit': 50, 'hasNext': false, 'nextCursor': null},
          );
        }
        if (request.url.path.endsWith('/read-all')) return _envelope(null);
        return _envelope({});
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Can we add extra chairs?'), findsOneWidget);
    expect(find.text('Sure, no problem.'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no messages yet', (tester) async {
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/bookings/b1/messages') && request.method == 'GET') {
          return _envelope([], pagination: {'limit': 50, 'hasNext': false, 'nextCursor': null});
        }
        if (request.url.path.endsWith('/read-all')) return _envelope(null);
        return _envelope({});
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('No messages yet'), findsOneWidget);
  });

  testWidgets('opening the conversation marks it read', (tester) async {
    var markedRead = false;
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/bookings/b1/messages') && request.method == 'GET') {
          return _envelope([_messageJson()], pagination: {'limit': 50, 'hasNext': false, 'nextCursor': null});
        }
        if (request.url.path.endsWith('/read-all')) {
          markedRead = true;
          return _envelope(null);
        }
        return _envelope({});
      }),
    );
    await tester.pumpAndSettle();

    expect(markedRead, true);
  });

  testWidgets('sending a message appends it to the list', (tester) async {
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/bookings/b1/messages') && request.method == 'GET') {
          return _envelope([], pagination: {'limit': 50, 'hasNext': false, 'nextCursor': null});
        }
        if (request.url.path.endsWith('/read-all')) return _envelope(null);
        if (request.url.path.endsWith('/bookings/b1/messages') && request.method == 'POST') {
          return _envelope(_messageJson(id: 'm-new', senderUserId: 'manager-1', body: 'New message'));
        }
        return _envelope({});
      }),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'New message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('New message'), findsOneWidget);
  });
}
