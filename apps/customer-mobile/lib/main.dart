import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import 'core/auth_gate.dart';

void main() {
  runApp(const CustomerMobileApp());
}

class CustomerMobileApp extends StatelessWidget {
  const CustomerMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>(
      create: (_) {
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
        return authController;
      },
      child: MaterialApp(
        title: 'Customer Mobile',
        theme: buildHotelHallTheme(),
        home: const AuthGate(),
      ),
    );
  }
}
