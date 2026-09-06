import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import 'core/auth_gate.dart';
import 'core/pending_action_controller.dart';
import 'features/discovery/application/discovery_controller.dart';
import 'features/discovery/data/discovery_repository.dart';
import 'features/favorites/application/favorites_controller.dart';
import 'features/favorites/data/favorites_repository.dart';

void main() {
  runApp(const CustomerMobileApp());
}

class CustomerMobileApp extends StatelessWidget {
  const CustomerMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    late AuthController authController;
    return MultiProvider(
      providers: [
        Provider<SessionStore>(create: (_) => SessionStore()),
        Provider<ApiClient>(
          create: (context) {
            final sessionStore = context.read<SessionStore>();
            final apiClient = ApiClient(
              accessTokenProvider: () => sessionStore.accessToken,
              refreshTokenProvider: () => sessionStore.refreshToken,
              tokenPairSaver: sessionStore.save,
              sessionExpiredHandler: () => authController.expireSession(),
            );
            return apiClient;
          },
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) {
            final apiClient = context.read<ApiClient>();
            final sessionStore = context.read<SessionStore>();
            authController = AuthController(
              repository: AuthRepository(apiClient),
              sessionStore: sessionStore,
            );
            return authController;
          },
        ),
        ChangeNotifierProvider(create: (_) => PendingActionController()),
        ChangeNotifierProvider(
          create: (context) => DiscoveryController(
            DiscoveryRepository(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FavoritesController(
            FavoritesRepository(context.read<ApiClient>()),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Customer Mobile',
        theme: buildHotelHallTheme(),
        home: const AuthGate(),
      ),
    );
  }
}
