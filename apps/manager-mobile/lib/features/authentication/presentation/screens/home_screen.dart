import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../../halls/data/hall_models.dart';
import '../../../halls/data/hall_repository.dart';
import '../../../halls/presentation/screens/hall_list_screen.dart';
import '../../../hotel/application/hotel_context_controller.dart';
import '../../../hotel/data/hotel_models.dart';
import '../../../hotel/data/hotel_repository.dart';
import '../../../hotel/presentation/screens/my_hotel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextController = context.read<HotelContextController>();
      if (contextController.status == HotelContextStatus.unknown) {
        contextController.load();
      }
    });
  }

  Future<void> _logout() async {
    final auth = context.read<AuthController>();
    final hotelContext = context.read<HotelContextController>();
    await auth.logout();
    await hotelContext.clearOnLogout();
  }

  @override
  Widget build(BuildContext context) {
    final hotel = context.watch<HotelContextController>().hotel;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _Dashboard(
            onOpenHotel: () => setState(() => _tab = 1),
            onOpenHalls: () => setState(() => _tab = 2),
          ),
          const MyHotelScreen(embedded: true),
          hotel == null
              ? const _HotelRequired()
              : HallListScreen(hotelId: hotel.id, embedded: true),
          _ProfileView(onLogout: _logout),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Hotel',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Halls',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatefulWidget {
  const _Dashboard({required this.onOpenHotel, required this.onOpenHalls});
  final VoidCallback onOpenHotel;
  final VoidCallback onOpenHalls;
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  List<Hall> _halls = const [];
  HotelMediaCollection? _media;
  String? _loadedHotelId;

  Future<void> _loadSummary(String hotelId) async {
    if (_loadedHotelId == hotelId) {
      return;
    }
    _loadedHotelId = hotelId;
    final api = context.read<ApiClient>();
    try {
      final results = await Future.wait([
        HallRepository(api).listHalls(hotelId: hotelId, limit: 100),
        HotelRepository(api).getMedia(hotelId),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _halls = (results[0] as HallPage).halls;
        _media = results[1] as HotelMediaCollection;
      });
    } catch (_) {
      // Summary media and counts are supplementary to the primary Hotel flow.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HotelContextController>();
    final hotel = state.hotel;
    if (hotel != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadSummary(hotel.id),
      );
    }
    final name =
        ManagerFormatters.text(hotel?.profileData, 'name') ?? 'My Hotel';
    final address =
        ManagerFormatters.text(hotel?.profileData, 'address') ??
        'Complete your hotel location';
    final image = _media?.photos.isNotEmpty == true
        ? _media!.photos.first.url
        : _media?.logo?.url;
    final capacity = _halls.fold<int>(
      0,
      (total, hall) => total + (hall.capacity ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(
                color: HHColors.textOnNavy,
                fontSize: HHTypeScale.textSm,
              ),
            ),
            Text(
              'Hotel Manager',
              style: HHTypography.serifLg.copyWith(color: HHColors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadedHotelId = null;
          await state.load();
          if (state.hotel != null) await _loadSummary(state.hotel!.id);
        },
        child: ListView(
          padding: const EdgeInsets.all(HHSpacing.space6),
          children: [
            if (hotel == null)
              _LifecycleCard(status: state.status, onOpen: widget.onOpenHotel)
            else ...[
              _HotelHero(
                name: name,
                address: address,
                status: hotel.status,
                imageUrl: image,
                onTap: widget.onOpenHotel,
              ),
              const SizedBox(height: HHSpacing.space5),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      icon: Icons.meeting_room_outlined,
                      label: 'Total halls',
                      value: '${_halls.length}',
                    ),
                  ),
                  const SizedBox(width: HHSpacing.space4),
                  Expanded(
                    child: _Metric(
                      icon: Icons.groups_outlined,
                      label: 'Total capacity',
                      value: '$capacity',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HHSpacing.space7),
              Text(
                'Quick actions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: HHSpacing.space3),
              _ActionTile(
                icon: Icons.apartment_outlined,
                title: 'Manage Hotel',
                subtitle: 'Profile, location, and status',
                onTap: widget.onOpenHotel,
              ),
              const SizedBox(height: HHSpacing.space3),
              _ActionTile(
                icon: Icons.meeting_room_outlined,
                title: 'Manage Halls',
                subtitle: 'Create, edit, and view halls',
                onTap: widget.onOpenHalls,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HotelHero extends StatelessWidget {
  const _HotelHero({
    required this.name,
    required this.address,
    required this.status,
    required this.imageUrl,
    required this.onTap,
  });
  final String name, address, status;
  final String? imageUrl;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: HHColors.navy700,
    borderRadius: BorderRadius.circular(HHRadii.card),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _HotelPlaceholder(),
              )
            else
              const _HotelPlaceholder(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD906182F)],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HHTypography.serifLg.copyWith(color: HHColors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: HHColors.textOnNavy),
                  ),
                  const SizedBox(height: 10),
                  _StatusBadge(status: status),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HotelPlaceholder extends StatelessWidget {
  const _HotelPlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: HHColors.navy600,
    child: Center(
      child: Icon(Icons.apartment, size: 72, color: HHColors.navy200),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final approved = status == 'APPROVED_ACTIVE';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: approved ? HHColors.success500 : HHColors.warning500,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          ManagerFormatters.status(status),
          style: const TextStyle(
            color: HHColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HHColors.actionAccent),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: HHColors.textMuted)),
          Text(value, style: HHTypography.serifLg),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(12),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: HHColors.surfaceNavy,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: HHColors.white),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _LifecycleCard extends StatelessWidget {
  const _LifecycleCard({required this.status, required this.onOpen});
  final HotelContextStatus status;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.apartment_outlined,
            size: 48,
            color: HHColors.navy400,
          ),
          const SizedBox(height: 16),
          Text(
            status == HotelContextStatus.loading
                ? 'Loading your Hotel'
                : 'Set up your Hotel',
            style: HHTypography.displaySm,
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your Hotel setup to start managing halls.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (status == HotelContextStatus.loading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: onOpen,
              child: const Text('Open Hotel setup'),
            ),
        ],
      ),
    ),
  );
}

class _HotelRequired extends StatelessWidget {
  const _HotelRequired();
  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: _SimpleAppBar('Halls'),
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Set up your Hotel before managing halls.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SimpleAppBar(this.title);
  final String title;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(title: Text(title));
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.onLogout});
  final Future<void> Function() onLogout;
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: HHColors.navy100,
            child: Icon(Icons.person, size: 42, color: HHColors.navy700),
          ),
          const SizedBox(height: 18),
          Text(
            user?.mobileNumber ?? '',
            textAlign: TextAlign.center,
            style: HHTypography.serifLg,
          ),
          const SizedBox(height: 6),
          Text(
            ManagerFormatters.status(user?.accountType ?? 'HOTEL_MANAGER'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: HHColors.textMuted),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
