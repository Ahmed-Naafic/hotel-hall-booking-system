import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/booking_list_tile.dart';
import '../../../../core/presentation/manager_formatters.dart';
import '../../../../core/presentation/stat_tile.dart';
import '../../../authentication/presentation/widgets/manager_drawer.dart';
import '../../../bookings/data/booking_models.dart';
import '../../../bookings/data/booking_repository.dart';
import '../../../halls/data/hall_repository.dart';
import '../../../hotel/application/hotel_context_controller.dart';
import '../../../hotel/presentation/widgets/hotel_onboarding.dart';
import '../../../chat/application/chat_badge_controller.dart';
import '../../../notifications/application/notification_controller.dart';
import '../../../notifications/presentation/screens/notification_center_screen.dart';

/// Manager → Home (Dashboard tab). Every value shown here already exists
/// on a screen elsewhere in the app, or is a real database-side aggregate
/// (`booking.repository.js#getSummary`) — this screen never invents a
/// stat.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenHotelTab,
    required this.onOpenHallsTab,
    required this.onOpenBookingsTab,
  });

  final VoidCallback onOpenHotelTab;
  final VoidCallback onOpenHallsTab;
  final VoidCallback onOpenBookingsTab;

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

/// Public so `HomeScreen` (the `IndexedStack` owner) can hold a `GlobalKey`
/// and call [refresh] explicitly when the Home tab is (re)selected — an
/// `IndexedStack` tab has no built-in "became visible again" callback, and
/// without this every value here would only ever be fetched once per Hotel
/// id and then silently go stale while Home stays alive in the background.
class DashboardScreenState extends State<DashboardScreen> {
  Future<int>? _hallCountFuture;
  String? _hallCountLoadedForHotelId;
  Future<BookingSummary>? _summaryFuture;
  String? _summaryLoadedForHotelId;
  Future<List<ManagerBooking>>? _recentBookingsFuture;
  String? _recentBookingsLoadedForHotelId;

  /// A single cheap `limit: 1` call read only for `HallPage.total` — never
  /// a hardcoded number, and never the full Hall list just to count it.
  void _maybeLoadHallCount(String? hotelId, {bool force = false}) {
    if (hotelId == null) {
      _hallCountFuture = null;
      _hallCountLoadedForHotelId = null;
      return;
    }
    if (!force && hotelId == _hallCountLoadedForHotelId) return;
    _hallCountLoadedForHotelId = hotelId;
    _hallCountFuture = HallRepository(context.read<ApiClient>())
        .listHalls(hotelId: hotelId, limit: 1)
        .then((page) => page.total);
  }

  /// Overview grid's Total Bookings / Total Revenue / Pending Requests —
  /// one real database-side aggregate (`GET /hotels/:hotelId/bookings/summary`),
  /// never every Booking fetched just to count/sum it client-side.
  void _maybeLoadSummary(String? hotelId, {bool force = false}) {
    if (hotelId == null) {
      _summaryFuture = null;
      _summaryLoadedForHotelId = null;
      return;
    }
    if (!force && hotelId == _summaryLoadedForHotelId) return;
    _summaryLoadedForHotelId = hotelId;
    _summaryFuture = ManagerBookingRepository(context.read<ApiClient>()).summary(hotelId);
  }

  /// The 3 newest Bookings for this Hotel, reusing the existing
  /// hotel-bookings list endpoint (already newest-first) — no dedicated
  /// "recent" endpoint needed.
  void _maybeLoadRecentBookings(String? hotelId, {bool force = false}) {
    if (hotelId == null) {
      _recentBookingsFuture = null;
      _recentBookingsLoadedForHotelId = null;
      return;
    }
    if (!force && hotelId == _recentBookingsLoadedForHotelId) return;
    _recentBookingsLoadedForHotelId = hotelId;
    _recentBookingsFuture = ManagerBookingRepository(context.read<ApiClient>()).list(hotelId, limit: 3);
  }

  /// Called by `HomeScreen` when the Home tab becomes selected again, and
  /// by this screen's own pull-to-refresh — always re-fetches, never relies
  /// on the per-Hotel-id cache.
  Future<void> refresh() async {
    final hotelContext = context.read<HotelContextController>();
    await hotelContext.load();
    if (!mounted) return;
    setState(() {
      _maybeLoadHallCount(hotelContext.hotel?.id, force: true);
      _maybeLoadSummary(hotelContext.hotel?.id, force: true);
      _maybeLoadRecentBookings(hotelContext.hotel?.id, force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotelContext = context.watch<HotelContextController>();
    _maybeLoadHallCount(hotelContext.hotel?.id);
    _maybeLoadSummary(hotelContext.hotel?.id);
    _maybeLoadRecentBookings(hotelContext.hotel?.id);

    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          _ChatBadgeAction(onOpenBookingsTab: widget.onOpenBookingsTab),
          _NotificationBellAction(onOpenBookingsTab: widget.onOpenBookingsTab, onOpenHotelTab: widget.onOpenHotelTab),
          const SizedBox(width: HHSpacing.space2),
        ],
      ),
      drawer: const ManagerDrawer(),
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
          iconColor: context.hh.danger700,
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
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(HHSpacing.space7),
            children: [
              _GreetingCard(name: context.watch<AuthController>().currentUser?.fullName),
              const SizedBox(height: HHSpacing.space6),
              _OverviewGrid(
                summaryFuture: _summaryFuture,
                hallCountFuture: _hallCountFuture,
                onOpenHallsTab: widget.onOpenHallsTab,
                onOpenBookingsTab: widget.onOpenBookingsTab,
              ),
              const SizedBox(height: HHSpacing.space7),
              _RecentBookingsSection(
                recentBookingsFuture: _recentBookingsFuture,
                onViewAll: widget.onOpenBookingsTab,
              ),
              const SizedBox(height: HHSpacing.space7),
              ...hotelOnboardingSteps(context, hotelContext, hotel),
            ],
          ),
        );
    }
  }
}

/// Purple/blue-mockup reskinned into the app's own navy→teal brand
/// gradient. Greets the real signed-in Manager by name (BDR-019) — falls
/// back to the mobile number for a pre-BDR-019 account with no Full Name
/// set, same fallback `ManagerDrawer`/the old `ProfileScreen` already use.
class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.name});

  final String? name;

  String get _timeOfDayGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HHSpacing.space6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HHColors.navy700, HHColors.teal700],
        ),
        borderRadius: BorderRadius.circular(HHRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_timeOfDayGreeting${name == null ? '' : ', $name'} 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HHTypeScale.textXl,
              fontWeight: HHTypeScale.weightSemibold,
            ),
          ),
          const SizedBox(height: HHSpacing.space2),
          Text(
            "Here's what's happening today.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: HHTypeScale.textSm),
          ),
        ],
      ),
    );
  }
}

/// Overview — Total Bookings / Total Revenue / Total Halls / Pending
/// Requests. "Active Halls" from the original mockup is deliberately
/// rendered as **Total** Halls: Hall Management has no active/inactive
/// concept (Hall Management Technical Design §6/§12 — visibility is
/// request-time, not Hall data), so this app never invents one.
class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({
    required this.summaryFuture,
    required this.hallCountFuture,
    required this.onOpenHallsTab,
    required this.onOpenBookingsTab,
  });

  final Future<BookingSummary>? summaryFuture;
  final Future<int>? hallCountFuture;
  final VoidCallback onOpenHallsTab;
  final VoidCallback onOpenBookingsTab;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookingSummary>(
      future: summaryFuture,
      builder: (context, summarySnap) {
        return FutureBuilder<int>(
          future: hallCountFuture,
          builder: (context, hallSnap) {
            final summary = summarySnap.data;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // A fixed height (rather than `childAspectRatio`) so the tile's
              // actual content — icon chip, value, label, card padding —
              // always fits regardless of the grid's width; an aspect ratio
              // derives height from width alone and was overflowing at
              // ordinary phone widths.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: HHSpacing.space4,
                crossAxisSpacing: HHSpacing.space4,
                mainAxisExtent: 140,
              ),
              children: [
                StatTile(
                  icon: Icons.calendar_today_outlined,
                  iconColor: context.hh.actionPrimary,
                  iconBg: context.hh.surfaceNavyTint,
                  label: 'Total Bookings',
                  value: statTileValueOf(summarySnap, summary?.totalBookings.toString()),
                  onTap: onOpenBookingsTab,
                ),
                StatTile(
                  icon: Icons.payments_outlined,
                  iconColor: context.hh.actionGold,
                  iconBg: context.hh.surfaceGoldTint,
                  label: 'Total Revenue',
                  value: statTileValueOf(
                    summarySnap,
                    summary == null ? null : ManagerFormatters.moneyCents(summary.totalRevenueCents),
                  ),
                  onTap: onOpenBookingsTab,
                ),
                StatTile(
                  icon: Icons.meeting_room_outlined,
                  iconColor: context.hh.actionAccent,
                  iconBg: context.hh.surfaceTealTint,
                  label: 'Total Halls',
                  value: statTileValueOf(hallSnap, hallSnap.data?.toString()),
                  onTap: onOpenHallsTab,
                ),
                StatTile(
                  icon: Icons.hourglass_top_outlined,
                  iconColor: context.hh.warning700,
                  iconBg: context.hh.warning100,
                  label: 'Pending Requests',
                  value: statTileValueOf(summarySnap, summary?.pendingCount.toString()),
                  onTap: onOpenBookingsTab,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RecentBookingsSection extends StatelessWidget {
  const _RecentBookingsSection({required this.recentBookingsFuture, required this.onViewAll});

  final Future<List<ManagerBooking>>? recentBookingsFuture;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Bookings',
                style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textLg),
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        FutureBuilder<List<ManagerBooking>>(
          future: recentBookingsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: HHSpacing.space5),
                  child: Text('Unable to load recent bookings.', style: TextStyle(color: context.hh.textMuted)),
                );
              }
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: HHSpacing.space6),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final bookings = snapshot.data!;
            if (bookings.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: HHSpacing.space5),
                child: Text('No bookings yet.', style: TextStyle(color: context.hh.textMuted)),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(top: HHSpacing.space4),
              child: Column(
                children: [
                  for (final booking in bookings) ...[
                    BookingListTile(booking: booking),
                    if (booking != bookings.last) const SizedBox(height: HHSpacing.space3),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Dashboard's own independent unread-message badge (Business Rule 8) — a
/// conversation only lives inside a Booking, so tapping this opens the
/// Bookings tab directly (the safest existing destination) rather than a
/// new, standalone chat-inbox screen.
class _ChatBadgeAction extends StatelessWidget {
  const _ChatBadgeAction({required this.onOpenBookingsTab});

  final VoidCallback onOpenBookingsTab;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<ChatBadgeController, int>((c) => c.unreadCount);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: onOpenBookingsTab,
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: context.hh.danger700,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

/// Dashboard's bell action, with an unread-count badge sourced from the
/// app-wide `NotificationController` (never a poll). Neither the Bookings
/// tab nor the Hotel tab is a pushable route — both live inside
/// `HomeScreen`'s `IndexedStack` — so the destination Notification Center
/// returns on pop is what triggers the matching `onOpen*Tab` callback, the
/// same push-and-react-on-return shape `HomeScreen`/`_HallsTab` already use.
class _NotificationBellAction extends StatelessWidget {
  const _NotificationBellAction({required this.onOpenBookingsTab, required this.onOpenHotelTab});

  final VoidCallback onOpenBookingsTab;
  final VoidCallback onOpenHotelTab;

  Future<void> _open(BuildContext context) async {
    final destination = await Navigator.of(context).push<NotificationDestination>(
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    );
    switch (destination) {
      case NotificationDestination.bookingsTab:
        onOpenBookingsTab();
      case NotificationDestination.hotelTab:
        onOpenHotelTab();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<NotificationController, int>((c) => c.unreadCount);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => _open(context),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: context.hh.danger700,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
