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
  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  int _selectedFilter = 0;

  final List<String> _filters = const [
    'Near You',
    'Popular',
    'Large Halls',
    'All Hotels',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryController>().loadHotels();
      _resumePendingAction();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resumePendingAction() {
    final auth = context.read<AuthController>();
    final pending = context.read<PendingActionController>();

    if (auth.status == AuthStatus.authenticated &&
        auth.currentUser?.isVerified == true &&
        pending.hall != null) {
      final hall = pending.takeHall()!;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HallDetailScreen(hall: hall),
        ),
      );
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: discovery.loadHotels,
          child: _buildBody(discovery, auth),
        ),
      ),
    );
  }

  Widget _buildBody(
    DiscoveryController discovery,
    AuthController auth,
  ) {
    if (discovery.isLoading && discovery.hotels.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (discovery.errorMessage != null && discovery.hotels.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 220),
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              discovery.errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: discovery.loadHotels,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    final hotels = discovery.hotels.where((hotel) {
      if (_search.trim().isEmpty) return true;

      final query = _search.toLowerCase();

      return hotel.name.toLowerCase().contains(query) ||
          hotel.location.toLowerCase().contains(query);
    }).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              HHSpacing.space5,
              HHSpacing.space4,
              HHSpacing.space5,
              0,
            ),
            child: _TopHeader(
              auth: auth,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              HHSpacing.space5,
              HHSpacing.space5,
              HHSpacing.space5,
              0,
            ),
            child: _SearchField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _search = value);
              },
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 66,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: HHSpacing.space5,
                vertical: 12,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _FilterChip(
                  label: _filters[index],
                  selected: _selectedFilter == index,
                  onTap: () {
                    setState(() => _selectedFilter = index);
                  },
                );
              },
            ),
          ),
        ),

        if (hotels.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                HHSpacing.space5,
                6,
                HHSpacing.space5,
                14,
              ),
              child: _SectionHeader(
                title: 'Featured hotels',
                action: 'See all',
                onTap: () {
                  setState(() => _selectedFilter = 3);
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 255,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: HHSpacing.space5,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: hotels.length > 5 ? 5 : hotels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return _FeaturedHotelCard(
                    hotel: hotels[index],
                  );
                },
              ),
            ),
          ),
        ],

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              HHSpacing.space5,
              HHSpacing.space7,
              HHSpacing.space5,
              14,
            ),
            child: const _SectionHeader(
              title: 'Hotels for you',
            ),
          ),
        ),

        if (hotels.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('No hotels found.'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              HHSpacing.space5,
              0,
              HHSpacing.space5,
              HHSpacing.space7,
            ),
            sliver: SliverList.separated(
              itemCount: hotels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _HotelListTile(
                  hotel: hotels[index],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.auth,
  });

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Find your perfect venue',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _HeaderButton(
          icon: auth.status == AuthStatus.authenticated
              ? Icons.person_outline_rounded
              : Icons.login_rounded,
          onTap: () {
            if (auth.status == AuthStatus.authenticated) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerProfileScreen(),
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(17),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                hintText: 'Search hotel or location...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: scheme.onPrimary,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? scheme.primary
          : scheme.surfaceContainerHighest.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.action,
    this.onTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(action!),
          ),
      ],
    );
  }
}

class _FeaturedHotelCard extends StatelessWidget {
  const _FeaturedHotelCard({
    required this.hotel,
  });

  final HotelSummary hotel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 220,
      child: Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        color: scheme.surface,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HotelDetailScreen(
                  hotelId: hotel.id,
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkImage(
                url: hotel.logo?.url,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .12),
                      Colors.black.withValues(alpha: .80),
                    ],
                    stops: const [0.30, 0.55, 1],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .88),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_border_rounded,
                    size: 20,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hotel.location.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hotel.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotelListTile extends StatelessWidget {
  const _HotelListTile({
    required this.hotel,
  });

  final HotelSummary hotel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HotelDetailScreen(
                hotelId: hotel.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: _NetworkImage(
                    url: hotel.logo?.url,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hotel.location.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hotel.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (hotel.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hotel.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HotelDetailScreen extends StatefulWidget {
  const HotelDetailScreen({
    required this.hotelId,
    super.key,
  });

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
    final repository = DiscoveryRepository(
      context.read<ApiClient>(),
    );

    return (
      await repository.getHotel(widget.hotelId),
      await repository.getHalls(widget.hotelId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      body: FutureBuilder<(HotelSummary, List<HallSummary>)>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() => future = _load());
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            );
          }

          final (hotel, halls) = snapshot.data!;

          return _HotelDetailContent(
            hotel: hotel,
            halls: halls,
          );
        },
      ),
    );
  }
}

class _HotelDetailContent extends StatelessWidget {
  const _HotelDetailContent({
    required this.hotel,
    required this.halls,
  });

  final HotelSummary hotel;
  final List<HallSummary> halls;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.22,
                child: _NetworkImage(
                  url: hotel.logo?.url,
                ),
              ),
              Positioned(
                left: 18,
                top: MediaQuery.paddingOf(context).top + 12,
                child: _FloatingCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                right: 18,
                top: MediaQuery.paddingOf(context).top + 12,
                child: _FloatingCircleButton(
                  icon: Icons.bookmark_border_rounded,
                  onTap: () {},
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .55),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hotel.location.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hotel.location,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            HHSpacing.space5,
            HHSpacing.space6,
            HHSpacing.space5,
            HHSpacing.space7,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                if (hotel.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hotel.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Available halls',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    if (halls.isNotEmpty)
                      Text(
                        '${halls.length} halls',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                if (halls.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'No visible halls are available.',
                      ),
                    ),
                  )
                else
                  ...halls.map(
                    (hall) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HallCard(
                        hall: hall,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HallCard extends StatelessWidget {
  const _HallCard({
    required this.hall,
  });

  final HallSummary hall;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HallDetailScreen(hall: hall),
            ),
          );
        },
        child: Row(
          children: [
            SizedBox(
              width: 125,
              height: 125,
              child: _NetworkImage(
                url: hall.photos.isNotEmpty
                    ? hall.photos.first.url
                    : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hall.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (hall.location.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hall.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (hall.capacity.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.groups_2_outlined,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Capacity ${hall.capacity}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'View details',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HallDetailScreen extends StatelessWidget {
  const HallDetailScreen({
    required this.hall,
    super.key,
  });

  final HallSummary hall;

  Future<void> _book(BuildContext context) async {
    final auth = context.read<AuthController>();

    context.read<PendingActionController>().preserveBookingHall(hall);

    if (auth.status != AuthStatus.authenticated) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } else if (auth.currentUser?.isVerified != true) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const VerifyScreen(),
        ),
      );
    }

    if (context.mounted &&
        auth.currentUser?.isVerified == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking will be available in the Booking module.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: _NetworkImage(
                    url: hall.photos.isNotEmpty
                        ? hall.photos.first.url
                        : null,
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 12,
                  left: 18,
                  child: _FloatingCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              HHSpacing.space5,
              HHSpacing.space6,
              HHSpacing.space5,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Text(
                    hall.name,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                  ),

                  if (hall.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: scheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            hall.location,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (hall.capacity.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _InfoBox(
                      icon: Icons.groups_2_outlined,
                      label: 'Capacity',
                      value: hall.capacity,
                    ),
                  ],

                  if (hall.description.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Description',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hall.description,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.55,
                                color: scheme.onSurfaceVariant,
                              ),
                    ),
                  ],

                  if (hall.photos.length > 1) ...[
                    const SizedBox(height: 30),
                    Text(
                      'Gallery',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: hall.photos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 130,
                              child: _NetworkImage(
                                url: hall.photos[index].url,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: () => _book(context),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available_outlined),
                SizedBox(width: 9),
                Text(
                  'Book Hall',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({
    this.url,
  });

  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (url == null || url!.trim().isEmpty) {
      return Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.apartment_rounded,
          size: 42,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Image.network(
      url!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: scheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .90),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 19,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

