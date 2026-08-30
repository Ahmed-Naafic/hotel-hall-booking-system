import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/pending_action_controller.dart';
import '../../authentication/presentation/screens/login_screen.dart';
import '../../authentication/presentation/screens/verify_screen.dart';
import '../application/discovery_controller.dart';
import '../data/discovery_models.dart';
import '../data/discovery_repository.dart';
import '../../customer_profile/presentation/customer_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryController>().loadHotels();
      _resumePendingAction();
    });
  }

  void _resumePendingAction() {
    final auth = context.read<AuthController>();
    final pending = context.read<PendingActionController>();
    if (auth.status == AuthStatus.authenticated &&
        auth.currentUser?.isVerified == true &&
        pending.hall != null) {
      final hall = pending.takeHall()!;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => HallDetailScreen(hall: hall)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryController>();
    final auth = context.watch<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => mounted ? _resumePendingAction() : null,
    );

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(
        title: const Text('Discover Hotels'),
        actions: [
          if (auth.status == AuthStatus.authenticated)
            IconButton(
              tooltip: 'My profile',
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerProfileScreen(),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Log in',
              icon: const Icon(Icons.login),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: discovery.loadHotels,
        child: _body(discovery),
      ),
    );
  }

  Widget _body(DiscoveryController discovery) {
    if (discovery.isLoading && discovery.hotels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (discovery.errorMessage != null && discovery.hotels.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 180),
          Center(child: Text(discovery.errorMessage!)),
          Center(
            child: TextButton(
              onPressed: discovery.loadHotels,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (discovery.hotels.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(child: Text('No Hotels are available yet.')),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(HHSpacing.space5),
      itemCount: discovery.hotels.length,
      separatorBuilder: (_, _) => const SizedBox(height: HHSpacing.space4),
      itemBuilder: (context, index) =>
          _HotelTile(hotel: discovery.hotels[index]),
    );
  }
}

class _HotelTile extends StatelessWidget {
  const _HotelTile({required this.hotel});
  final HotelSummary hotel;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HotelDetailScreen(hotelId: hotel.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hotel.logo != null)
            Image.network(
              hotel.logo!.url,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(HHSpacing.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hotel.name, style: Theme.of(context).textTheme.titleLarge),
                if (hotel.location.isNotEmpty) Text(hotel.location),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class HotelDetailScreen extends StatefulWidget {
  const HotelDetailScreen({required this.hotelId, super.key});
  final String hotelId;
  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  late Future<(HotelSummary, List<HallSummary>)> future;
  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<(HotelSummary, List<HallSummary>)> _load() async {
    final repository = DiscoveryRepository(context.read<ApiClient>());
    return (
      await repository.getHotel(widget.hotelId),
      await repository.getHalls(widget.hotelId),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hotel Details')),
    body: FutureBuilder<(HotelSummary, List<HallSummary>)>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() => future = _load()),
              child: const Text('Retry'),
            ),
          );
        }
        final (hotel, halls) = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(HHSpacing.space5),
          children: [
            Text(hotel.name, style: HHTypography.displaySm),
            if (hotel.location.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(hotel.location),
              ),
            if (hotel.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(hotel.description),
              ),
            const SizedBox(height: HHSpacing.space7),
            Text('Halls', style: Theme.of(context).textTheme.titleLarge),
            if (halls.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('No visible Halls are available.'),
              ),
            ...halls.map(
              (hall) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(hall.name),
                subtitle: Text(
                  [
                    if (hall.capacity.isNotEmpty) 'Capacity ${hall.capacity}',
                    if (hall.location.isNotEmpty) hall.location,
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HallDetailScreen(hall: hall),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class HallDetailScreen extends StatelessWidget {
  const HallDetailScreen({required this.hall, super.key});
  final HallSummary hall;

  Future<void> _book(BuildContext context) async {
    final auth = context.read<AuthController>();
    context.read<PendingActionController>().preserveBookingHall(hall);
    if (auth.status != AuthStatus.authenticated) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else if (auth.currentUser?.isVerified != true) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const VerifyScreen()));
    }
    if (context.mounted && auth.currentUser?.isVerified == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking will be available in the Booking module.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(hall.name)),
    body: ListView(
      padding: const EdgeInsets.all(HHSpacing.space5),
      children: [
        if (hall.photos.isNotEmpty)
          Image.network(hall.photos.first.url, height: 220, fit: BoxFit.cover),
        const SizedBox(height: HHSpacing.space5),
        Text(hall.name, style: HHTypography.displaySm),
        if (hall.capacity.isNotEmpty) Text('Capacity: ${hall.capacity}'),
        if (hall.location.isNotEmpty) Text(hall.location),
        if (hall.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(hall.description),
          ),
        const SizedBox(height: HHSpacing.space7),
        FilledButton.icon(
          onPressed: () => _book(context),
          icon: const Icon(Icons.event_available),
          label: const Text('Book'),
        ),
      ],
    ),
  );
}
