import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../halls/presentation/screens/hall_list_screen.dart';
import '../../application/hotel_context_controller.dart';
import '../widgets/hotel_onboarding.dart';

/// Manager → My Hotel — the minimal navigation level between Home and
/// Halls the requested nav tree calls for. Shows the Hotel's own real
/// `status` field verbatim (no client-side translation into a Visible/
/// Hidden judgment — that stays server-computed, Hall Management Technical
/// Design §6).
class MyHotelScreen extends StatefulWidget {
  const MyHotelScreen({super.key, this.embedded = false});

  /// True when hosted as the Hotel tab of the bottom-navigation shell
  /// ([HomeScreen]) rather than pushed on top of another screen — hides
  /// the back affordance and, since the shell already triggers the shared
  /// [HotelContextController]'s initial load, skips firing a second one.
  final bool embedded;

  @override
  State<MyHotelScreen> createState() => _MyHotelScreenState();
}

class _MyHotelScreenState extends State<MyHotelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hotelContext = context.read<HotelContextController>();
      if (!widget.embedded || hotelContext.status == HotelContextStatus.unknown) {
        hotelContext.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotelContext = context.watch<HotelContextController>();

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(
        title: const Text('My Hotel'),
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: SafeArea(child: _body(hotelContext)),
    );
  }

  Widget _body(HotelContextController hotelContext) {
    switch (hotelContext.status) {
      case HotelContextStatus.unknown:
      case HotelContextStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case HotelContextStatus.error:
        return HHEmptyState(
          icon: Icons.error_outline,
          message: hotelContext.errorMessage ?? 'Something went wrong.',
          iconColor: HHColors.danger700,
          actionLabel: 'Retry',
          onAction: hotelContext.load,
        );

      case HotelContextStatus.none:
        return HHEmptyState(
          icon: Icons.apartment_outlined,
          title: 'Set up your Hotel',
          message: "You haven't connected a Hotel to your account yet.",
          actionLabel: 'Set up my Hotel',
          onAction: hotelContext.createHotel,
          isLoading: false,
        );

      case HotelContextStatus.ready:
        final hotel = hotelContext.hotel!;
        return RefreshIndicator(
          onRefresh: hotelContext.load,
          child: ListView(
            padding: const EdgeInsets.all(HHSpacing.space7),
            children: [
              HotelIdentityCard(hotel: hotel),
              if (hotelContext.errorMessage != null) ...[
                const SizedBox(height: HHSpacing.space5),
                HHErrorBanner(message: hotelContext.errorMessage!),
              ],
              ...hotelOnboardingSteps(context, hotelContext, hotel),
              const SizedBox(height: HHSpacing.space7),
              HHPrimaryButton(
                label: 'Manage Halls',
                isLoading: false,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HallListScreen(hotelId: hotel.id),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
