import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import 'core/auth_gate.dart';
import 'features/chat/application/chat_badge_controller.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/hotel/application/hotel_context_controller.dart';
import 'features/hotel/data/hotel_repository.dart';
import 'features/notifications/application/notification_controller.dart';
import 'features/notifications/data/notification_repository.dart';

void main() {
  runApp(const ManagerMobileApp());
}

class ManagerMobileApp extends StatelessWidget {
  const ManagerMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionStore = SessionStore();
    late final AuthController authController;
    final apiClient = ApiClient(
      accessTokenProvider: () => sessionStore.accessToken,
      refreshTokenProvider: () => sessionStore.refreshToken,
      tokenPairSaver: sessionStore.save,
      sessionExpiredHandler: () => authController.expireSession(),
    );
    authController = AuthController(
      repository: AuthRepository(apiClient),
      sessionStore: sessionStore,
    );

    return MultiProvider(
      providers: [
        // App-wide: the chosen theme applies to every screen, including
        // the ones shown before sign-in.
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        // Shared, stateless — Hotel/Hall repositories are built from this
        // wherever they're needed, never a second HTTP client instance.
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthController>(create: (_) => authController),
        // Hotel context is Manager-Mobile-only (Customer Mobile never has
        // one) — its own cached id, independent of the shared SessionStore
        // (`HotelContextController`'s own doc comment explains why).
        ChangeNotifierProvider<HotelContextController>(
          create: (_) => HotelContextController(
            repository: HotelRepository(apiClient),
            storage: const SecureTokenStorage(),
          ),
        ),
        // App-wide so the Dashboard's unread badge and the Notification
        // Center screen always agree — same rationale as Customer Mobile's
        // own app-wide controllers this session.
        ChangeNotifierProvider(
          create: (_) => NotificationController(NotificationRepository(apiClient)),
        ),
        // App-wide, same rationale as NotificationController above — a
        // second, independent unread badge (Business Rule 8) that must
        // agree wherever it's shown.
        ChangeNotifierProvider(
          create: (_) => ChatBadgeController(ChatRepository(apiClient)),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp(
          title: 'Hotel Manager Mobile',
          debugShowCheckedModeBanner: false,
          theme: buildHotelHallTheme(),
          darkTheme: buildHotelHallTheme(brightness: Brightness.dark),
          themeMode: themeController.mode,
          home: const AuthGate(),
        ),
      ),
    );
  }
}
