import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../dashboard/presentation/screens/bookings_coming_soon_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../halls/presentation/screens/hall_list_screen.dart';
import '../../../hotel/application/hotel_context_controller.dart';
import '../../../hotel/presentation/screens/my_hotel_screen.dart';
import 'profile_screen.dart';

/// Manager — the authenticated landing screen. Bottom-navigation shell
/// over the approved nav tree's five top-level areas: Home (Dashboard),
/// Hotel, Halls, Bookings, Profile. Each tab either hosts an existing
/// screen unchanged (`MyHotelScreen`, `HallListScreen`, `ProfileScreen`) or
/// a new screen that only ever surfaces data those existing
/// repositories/controllers already expose (`DashboardScreen`), plus a
/// static acknowledgement for the one area with no backend support yet
/// (`BookingsComingSoonScreen`). An `IndexedStack` keeps every tab's own
/// state (scroll position, in-flight loads) alive across switches, the
/// same way the previous single-screen `Navigator` stack preserved state
/// across pushes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

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

  void _openTab(int index) => setState(() => _tabIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          DashboardScreen(
            onOpenHotelTab: () => _openTab(1),
            onOpenHallsTab: () => _openTab(2),
          ),
          const MyHotelScreen(embedded: true),
          const _HallsTab(),
          const BookingsComingSoonScreen(),
          const ProfileScreen(),
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
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
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
  const _HallsTab();

  @override
  Widget build(BuildContext context) {
    final hotelContext = context.watch<HotelContextController>();

    switch (hotelContext.status) {
      case HotelContextStatus.unknown:
      case HotelContextStatus.loading:
        return Scaffold(
          backgroundColor: HHColors.surfacePage,
          appBar: AppBar(title: const Text('Halls'), automaticallyImplyLeading: false),
          body: const Center(child: CircularProgressIndicator()),
        );

      case HotelContextStatus.error:
        return Scaffold(
          backgroundColor: HHColors.surfacePage,
          appBar: AppBar(title: const Text('Halls'), automaticallyImplyLeading: false),
          body: HHEmptyState(
            icon: Icons.error_outline,
            message: hotelContext.errorMessage ?? 'Something went wrong.',
            iconColor: HHColors.danger700,
            actionLabel: 'Retry',
            onAction: hotelContext.load,
          ),
        );

      case HotelContextStatus.none:
        return Scaffold(
          backgroundColor: HHColors.surfacePage,
          appBar: AppBar(title: const Text('Halls'), automaticallyImplyLeading: false),
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
        return HallListScreen(hotelId: hotelContext.hotel!.id, embedded: true);
    }
  }
}
