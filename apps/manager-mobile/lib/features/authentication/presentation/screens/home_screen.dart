import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/dashboard_back_button.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../dashboard/presentation/screens/bookings_coming_soon_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../halls/presentation/screens/hall_list_screen.dart';
import '../../../hotel/application/hotel_context_controller.dart';
import '../../../hotel/presentation/screens/my_hotel_screen.dart';

/// Manager — the authenticated landing screen. Bottom-navigation shell
/// over five top-level areas: Home (Dashboard), Hotel, Halls, Bookings,
/// Calendar. Account/Profile is no longer a bottom-nav destination — it
/// moved into the Drawer reachable from Home's hamburger icon
/// (`ManagerDrawer`), keeping the bar to destinations a Manager reaches
/// often. Each tab either hosts an existing screen unchanged
/// (`MyHotelScreen`, `HallListScreen`) or a new screen that only ever
/// surfaces data those existing repositories/controllers already expose
/// (`DashboardScreen`, `CalendarScreen`), plus a static acknowledgement for
/// the one area with no backend support yet (`BookingsComingSoonScreen`).
/// An `IndexedStack` keeps every tab's own state (scroll position,
/// in-flight loads) alive across switches, the same way the previous
/// single-screen `Navigator` stack preserved state across pushes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _hotelKey = GlobalKey<MyHotelScreenState>();
  final _bookingsKey = GlobalKey<BookingsComingSoonScreenState>();

  @override
  void initState() {
    super.initState();
    // The one shared load this shell owns — every tab that needs the
    // Hotel Manager's Hotel (Home, Hotel, Halls) reads the same
    // `HotelContextController` instance instead of each tab triggering
    // its own `GET /hotels/me`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HotelContextController>().load();
    });
  }

  void _openTab(int index) {
    setState(() => _tabIndex = index);
    // `IndexedStack` has no "became visible again" callback of its own —
    // without this, the Dashboard's Hall count (fetched once per Hotel id)
    // would stay stale forever after a Hall is created/deleted on the
    // Halls tab while Home stays alive in the background. Bookings gets
    // the same treatment so a Booking created while this tab sat idle in
    // the background (e.g. the Manager was on Home) is never missed.
    if (index == 0) _dashboardKey.currentState?.refresh();
    if (index == 1) _hotelKey.currentState?.refresh();
    if (index == 3) _bookingsKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          DashboardScreen(
            key: _dashboardKey,
            onOpenHotelTab: () => _openTab(1),
            onOpenHallsTab: () => _openTab(2),
            onOpenBookingsTab: () => _openTab(3),
          ),
          MyHotelScreen(
            key: _hotelKey,
            embedded: true,
            onOpenDashboardTab: () => _openTab(0),
            onOpenHallsTab: () => _openTab(2),
            onOpenBookingsTab: () => _openTab(3),
          ),
          _HallsTab(onOpenDashboardTab: () => _openTab(0)),
          BookingsComingSoonScreen(
            key: _bookingsKey,
            hotelId: context.watch<HotelContextController>().hotel?.id,
            active: _tabIndex == 3,
            embedded: true,
            onOpenDashboardTab: () => _openTab(0),
          ),
          const CalendarScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: _openTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment), label: 'Hotel'),
          NavigationDestination(icon: Icon(Icons.meeting_room_outlined), selectedIcon: Icon(Icons.meeting_room), label: 'Halls'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
        ],
      ),
    );
  }
}

/// The Halls tab's body — `HallListScreen` needs a resolved `hotelId`, so
/// this mirrors the same status-driven empty/loading/error language the
/// Hotel tab and Dashboard already use rather than crashing on a null id
/// or inventing a different set of messages for the same underlying state.
class _HallsTab extends StatelessWidget {
  const _HallsTab({required this.onOpenDashboardTab});

  final VoidCallback onOpenDashboardTab;

  AppBar _appBar() => AppBar(
    title: const Text('Halls'),
    centerTitle: true,
    leading: DashboardBackButton(embedded: true, onOpenDashboardTab: onOpenDashboardTab),
  );

  @override
  Widget build(BuildContext context) {
    final hotelContext = context.watch<HotelContextController>();

    switch (hotelContext.status) {
      case HotelContextStatus.unknown:
      case HotelContextStatus.loading:
        return Scaffold(
          backgroundColor: context.hh.surfacePage,
          appBar: _appBar(),
          body: const Center(child: CircularProgressIndicator()),
        );

      case HotelContextStatus.error:
        return Scaffold(
          backgroundColor: context.hh.surfacePage,
          appBar: _appBar(),
          body: HHEmptyState(
            icon: Icons.error_outline,
            message: hotelContext.errorMessage ?? 'Something went wrong.',
            iconColor: context.hh.danger700,
            actionLabel: 'Retry',
            onAction: hotelContext.load,
          ),
        );

      case HotelContextStatus.none:
        return Scaffold(
          backgroundColor: context.hh.surfacePage,
          appBar: _appBar(),
          body: HHEmptyState(
            icon: Icons.apartment_outlined,
            title: 'Set up your Hotel',
            message: 'Halls belong to a Hotel — set up your Hotel first.',
            actionLabel: 'Set up my Hotel',
            onAction: hotelContext.createHotel,
            isLoading: false,
          ),
        );

      case HotelContextStatus.ready:
        return HallListScreen(hotelId: hotelContext.hotel!.id, embedded: true, onOpenDashboardTab: onOpenDashboardTab);
    }
  }
}
