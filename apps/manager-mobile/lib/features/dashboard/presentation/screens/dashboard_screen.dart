import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../halls/data/hall_repository.dart';
import '../../../hotel/application/hotel_context_controller.dart';
import '../../../hotel/presentation/widgets/hotel_onboarding.dart';

/// Manager → Home (Dashboard tab). Every value shown here already exists
/// on a screen elsewhere in the app (`MyHotelScreen`, `HallListScreen`) —
/// this screen surfaces it as an at-a-glance summary, it never invents a
/// stat (no bookings/revenue/rating — none of that is backed by a real
/// API yet).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenHotelTab,
    required this.onOpenHallsTab,
  });

  final VoidCallback onOpenHotelTab;
  final VoidCallback onOpenHallsTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<int>? _hallCountFuture;
  String? _hallCountLoadedForHotelId;

  /// A single cheap `limit: 1` call read only for `HallPage.total` — never
  /// a hardcoded number, and never the full Hall list just to count it.
  /// Re-fires only when the resolved Hotel id actually changes (e.g. after
  /// `createHotel()`), not on every rebuild.
  void _maybeLoadHallCount(String? hotelId) {
    if (hotelId == null) {
      _hallCountFuture = null;
      _hallCountLoadedForHotelId = null;
      return;
    }
    if (hotelId == _hallCountLoadedForHotelId) return;
    _hallCountLoadedForHotelId = hotelId;
    _hallCountFuture = HallRepository(context.read<ApiClient>())
        .listHalls(hotelId: hotelId, limit: 1)
        .then((page) => page.total);
  }

  @override
  Widget build(BuildContext context) {
    final hotelContext = context.watch<HotelContextController>();
    _maybeLoadHallCount(hotelContext.hotel?.id);

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(child: _body(context, hotelContext)),
    );
  }

  Widget _body(BuildContext context, HotelContextController hotelContext) {
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
              HotelIdentityCard(hotel: hotel, onTap: widget.onOpenHotelTab),
              const SizedBox(height: HHSpacing.space5),
              _HallCountCard(
                hallCountFuture: _hallCountFuture,
                onTap: widget.onOpenHallsTab,
              ),
              ...hotelOnboardingSteps(context, hotelContext, hotel),
            ],
          ),
        );
    }
  }
}

class _HallCountCard extends StatelessWidget {
  const _HallCountCard({required this.hallCountFuture, required this.onTap});

  final Future<int>? hallCountFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HHCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: HHColors.surfaceNavyTint,
              borderRadius: BorderRadius.circular(HHRadii.control),
            ),
            child: Icon(Icons.meeting_room_outlined, color: HHColors.actionPrimary, size: 20),
          ),
          const SizedBox(width: HHSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halls',
                  style: TextStyle(
                    fontWeight: HHTypeScale.weightSemibold,
                    fontSize: HHTypeScale.textLg,
                  ),
                ),
                const SizedBox(height: 2),
                FutureBuilder<int>(
                  future: hallCountFuture,
                  builder: (context, snapshot) {
                    final text = switch (snapshot.connectionState) {
                      ConnectionState.done when snapshot.hasData => '${snapshot.data} Hall${snapshot.data == 1 ? '' : 's'} total',
                      ConnectionState.done when snapshot.hasError => 'Unable to load Hall count.',
                      _ => 'Loading…',
                    };
                    return Text(
                      text,
                      style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textSm),
                    );
                  },
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: HHColors.textSubtle),
        ],
      ),
    );
  }
}
