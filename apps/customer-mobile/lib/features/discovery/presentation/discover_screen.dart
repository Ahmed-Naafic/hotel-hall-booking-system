import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/location_service.dart';
import '../../../../core/pending_action_controller.dart';
import '../../authentication/presentation/screens/login_screen.dart';
import '../../authentication/presentation/screens/verify_screen.dart';
import '../../availability/presentation/screens/book_hall_screen.dart';
import '../../bookings/data/booking_models.dart';
import '../../bookings/presentation/screens/booking_history_screen.dart';
import '../../bookings/presentation/widgets/payment_terms.dart';
import '../application/all_halls_controller.dart';
import '../application/discovery_controller.dart';
import '../application/large_halls_controller.dart';
import '../application/nearby_hotels_controller.dart';
import '../application/popular_hotels_controller.dart';
import '../data/browsable_hall.dart';
import '../data/discovery_models.dart';
import '../data/discovery_repository.dart';
import '../data/large_hall.dart';
import '../data/nearby_hotel.dart';
import '../data/popular_hotel.dart';
import '../../customer_profile/presentation/customer_profile_screen.dart';
import '../../favorites/application/favorites_controller.dart';
import '../../favorites/presentation/saved_hotels_screen.dart';
import '../../reviews/application/hotel_reviews_controller.dart';
import '../../reviews/data/review.dart';
import '../../reviews/data/review_repository.dart';
import '../../reviews/presentation/widgets/star_rating.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _search = '';
  // "All Hotels" (index 4) is the default landing content — it's what this
  // screen always showed before these became in-place filters, so keeping
  // it default here also fixes the previous inconsistency where "Near You"
  // looked selected on load while "All Hotels" content was what showed.
  int _selectedFilter = 4;

  final List<String> _filters = const [
    'Near You',
    'Popular',
    'Large Halls',
    'All Halls',
    'All Hotels',
  ];

  // Category selectors, not navigation destinations (approved requirement) —
  // each controller is created once, lazily, on first selecting that tab,
  // and kept alive for the lifetime of this screen so flipping between tabs
  // doesn't re-fetch already-loaded content.
  late final DiscoveryRepository _repository = DiscoveryRepository(
    context.read<ApiClient>(),
  );
  NearbyHotelsController? _nearbyController;
  LargeHallsController? _largeHallsController;
  AllHallsController? _allHallsController;
  // Unlike the others, Popular Hotels' controller is app-wide (registered
  // in main.dart) rather than owned here — a successful Booking made from
  // any screen marks it stale, so this only needs to track whether *this*
  // screen has triggered its first load yet.
  bool _popularEverLoaded = false;

  NearbyHotelsController get _nearby => _nearbyController ??=
      NearbyHotelsController(
        repository: _repository,
        locationService: const LocationService(),
      )..load();

  PopularHotelsController get _popular => context.read<PopularHotelsController>();

  // Deliberately not inside the `_popular` getter above: that getter is
  // also read during build (via `ListenableBuilder(listenable: _popular,
  // ...)`), and calling `load()` there would call the app-wide
  // PopularHotelsController's `notifyListeners()` — which now has a live
  // listener (the ChangeNotifierProvider itself) — synchronously during a
  // build, which Flutter forbids. This is called instead from the filter
  // chip's own `onTap`, a plain event handler, exactly the same event
  // that used to lazily construct+load a screen-local controller before
  // Popular Hotels became app-wide.
  void _ensurePopularLoaded() {
    final controller = context.read<PopularHotelsController>();
    if (!_popularEverLoaded || controller.isStale) {
      _popularEverLoaded = true;
      controller.load();
    }
  }

  LargeHallsController get _largeHalls =>
      _largeHallsController ??= LargeHallsController(_repository)..load();

  AllHallsController get _allHalls =>
      _allHallsController ??= AllHallsController(_repository)..load();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryController>().loadHotels();
      context.read<FavoritesController>().load();
      _resumePendingAction();
    });

    _scrollController.addListener(() {
      if (_selectedFilter == 3 &&
          _scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 400) {
        _allHalls.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _nearbyController?.dispose();
    _largeHallsController?.dispose();
    _allHallsController?.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(DiscoveryController discovery) {
    switch (_selectedFilter) {
      case 0:
        return _nearby.load();
      case 1:
        return _popular.load();
      case 2:
        return _largeHalls.load();
      case 3:
        return _allHalls.load();
      default:
        return discovery.loadHotels();
    }
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
          onRefresh: () => _handleRefresh(discovery),
          child: CustomScrollView(
            controller: _scrollController,
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
                  child: _TopHeader(auth: auth),
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
                        // Category selectors, not navigation destinations —
                        // every tab just switches which section renders
                        // below, in this same Discover screen.
                        onTap: () {
                          setState(() => _selectedFilter = index);
                          if (index == 1) _ensurePopularLoaded();
                        },
                      );
                    },
                  ),
                ),
              ),

              ..._buildSectionSlivers(discovery),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionSlivers(DiscoveryController discovery) {
    switch (_selectedFilter) {
      case 0:
        return _nearbySlivers();
      case 1:
        return _popularSlivers();
      case 2:
        return _largeHallsSlivers();
      case 3:
        return _allHallsSlivers();
      default:
        return _allHotelsSlivers(discovery);
    }
  }

  List<Widget> _nearbySlivers() {
    return [
      ListenableBuilder(
        listenable: _nearby,
        builder: (context, _) {
          final controller = _nearby;
          switch (controller.state) {
            case NearbyHotelsState.locating:
            case NearbyHotelsState.loading:
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              );
            case NearbyHotelsState.permissionDenied:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.location_disabled_outlined,
                  message:
                      'Nearby Hotels needs your location to show Hotels close to you.',
                  actionLabel: 'Allow Location',
                  onAction: controller.load,
                ),
              );
            case NearbyHotelsState.permissionDeniedForever:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.location_disabled_outlined,
                  message:
                      'Location permission is turned off for this app. Enable it in Settings to see Hotels near you.',
                  actionLabel: 'Open Settings',
                  onAction: () async => controller.openAppSettings(),
                  secondaryLabel: 'Try again',
                  onSecondary: controller.load,
                ),
              );
            case NearbyHotelsState.serviceDisabled:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.location_off_outlined,
                  message: 'Turn on location services to see Hotels near you.',
                  actionLabel: 'Open Location Settings',
                  onAction: () async => controller.openLocationSettings(),
                  secondaryLabel: 'Try again',
                  onSecondary: controller.load,
                ),
              );
            case NearbyHotelsState.error:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.cloud_off_outlined,
                  message: controller.errorMessage ?? 'Something went wrong.',
                  actionLabel: 'Try again',
                  onAction: controller.load,
                ),
              );
            case NearbyHotelsState.empty:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.map_outlined,
                  message: 'No Hotels within 5 km of your location yet.',
                  actionLabel: 'Refresh',
                  onAction: controller.load,
                ),
              );
            case NearbyHotelsState.loaded:
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  HHSpacing.space5,
                  6,
                  HHSpacing.space5,
                  HHSpacing.space7,
                ),
                sliver: SliverList.separated(
                  itemCount: controller.hotels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _NearbyHotelTile(
                    nearbyHotel: controller.hotels[index],
                  ),
                ),
              );
          }
        },
      ),
    ];
  }

  List<Widget> _popularSlivers() {
    return [
      ListenableBuilder(
        listenable: _popular,
        builder: (context, _) {
          final controller = _popular;
          switch (controller.state) {
            case PopularHotelsState.loading:
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              );
            case PopularHotelsState.error:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.cloud_off_outlined,
                  message: controller.errorMessage ?? 'Something went wrong.',
                  actionLabel: 'Try again',
                  onAction: controller.load,
                ),
              );
            case PopularHotelsState.empty:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.local_fire_department_outlined,
                  message: 'No popular Hotels yet — check back soon.',
                  actionLabel: 'Refresh',
                  onAction: controller.load,
                ),
              );
            case PopularHotelsState.loaded:
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  HHSpacing.space5,
                  6,
                  HHSpacing.space5,
                  HHSpacing.space7,
                ),
                sliver: SliverList.separated(
                  itemCount: controller.hotels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _PopularHotelTile(
                    popularHotel: controller.hotels[index],
                  ),
                ),
              );
          }
        },
      ),
    ];
  }

  List<Widget> _largeHallsSlivers() {
    return [
      ListenableBuilder(
        listenable: _largeHalls,
        builder: (context, _) {
          final controller = _largeHalls;
          switch (controller.state) {
            case LargeHallsState.loading:
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              );
            case LargeHallsState.error:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.cloud_off_outlined,
                  message: controller.errorMessage ?? 'Something went wrong.',
                  actionLabel: 'Try again',
                  onAction: controller.load,
                ),
              );
            case LargeHallsState.empty:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.meeting_room_outlined,
                  message: 'No Halls are available yet.',
                  actionLabel: 'Refresh',
                  onAction: controller.load,
                ),
              );
            case LargeHallsState.loaded:
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  HHSpacing.space5,
                  6,
                  HHSpacing.space5,
                  HHSpacing.space7,
                ),
                sliver: SliverList.separated(
                  itemCount: controller.halls.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _LargeHallTile(
                    largeHall: controller.halls[index],
                  ),
                ),
              );
          }
        },
      ),
    ];
  }

  List<Widget> _allHallsSlivers() {
    return [
      ListenableBuilder(
        listenable: _allHalls,
        builder: (context, _) {
          final controller = _allHalls;
          switch (controller.state) {
            case AllHallsState.loading:
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              );
            case AllHallsState.error:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.cloud_off_outlined,
                  message: controller.errorMessage ?? 'Something went wrong.',
                  actionLabel: 'Try again',
                  onAction: controller.load,
                ),
              );
            case AllHallsState.empty:
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SectionStatus(
                  icon: Icons.meeting_room_outlined,
                  message: 'No Halls are available yet.',
                  actionLabel: 'Refresh',
                  onAction: controller.load,
                ),
              );
            case AllHallsState.loaded:
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  HHSpacing.space5,
                  6,
                  HHSpacing.space5,
                  HHSpacing.space7,
                ),
                sliver: SliverList.separated(
                  itemCount: controller.halls.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == controller.halls.length) {
                      return _AllHallsFooter(controller: controller);
                    }
                    return _BrowsableHallTile(
                      browsableHall: controller.halls[index],
                    );
                  },
                ),
              );
          }
        },
      ),
    ];
  }

  List<Widget> _allHotelsSlivers(DiscoveryController discovery) {
    if (discovery.isLoading && discovery.hotels.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (discovery.errorMessage != null && discovery.hotels.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _SectionStatus(
            icon: Icons.cloud_off_outlined,
            message: discovery.errorMessage!,
            actionLabel: 'Try again',
            onAction: discovery.loadHotels,
          ),
        ),
      ];
    }

    final hotels = discovery.hotels.where((hotel) {
      if (_search.trim().isEmpty) return true;

      final query = _search.toLowerCase();

      return hotel.name.toLowerCase().contains(query) ||
          hotel.location.toLowerCase().contains(query);
    }).toList();

    return [
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
                setState(() => _selectedFilter = 4);
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
    ];
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
        if (auth.status == AuthStatus.authenticated) ...[
          _HeaderButton(
            icon: Icons.bookmark_border_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavedHotelsScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _HeaderButton(
            icon: Icons.event_note_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
            ),
          ),
          const SizedBox(width: 12),
        ],
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

/// Shared status content (loading-adjacent error/empty states) for the four
/// in-place Discover sections (Near You, Popular, Large Halls, All Halls) —
/// a plain, non-scrolling Column since callers already place it inside a
/// [SliverFillRemaining] within Discover's own single [CustomScrollView].
class _SectionStatus extends StatelessWidget {
  const _SectionStatus({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NearbyHotelTile extends StatelessWidget {
  const _NearbyHotelTile({required this.nearbyHotel});

  final NearbyHotel nearbyHotel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hotel = nearbyHotel.hotel;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HotelDetailScreen(hotelId: hotel.id),
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
                  width: 80,
                  height: 80,
                  child: hotel.logo?.url == null
                      ? Container(
                          color: scheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.apartment_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : Image.network(hotel.logo!.url, fit: BoxFit.cover),
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hotel.location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hotel.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me_outlined,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${nearbyHotel.distanceKm.toStringAsFixed(1)} km away',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularHotelTile extends StatelessWidget {
  const _PopularHotelTile({required this.popularHotel});

  final PopularHotel popularHotel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hotel = popularHotel.hotel;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HotelDetailScreen(hotelId: hotel.id),
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
                  width: 80,
                  height: 80,
                  child: hotel.logo?.url == null
                      ? Container(
                          color: scheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.apartment_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : Image.network(hotel.logo!.url, fit: BoxFit.cover),
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hotel.location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hotel.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          size: 15,
                          color: HHColors.textGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${popularHotel.bookingCount} '
                          '${popularHotel.bookingCount == 1 ? 'booking' : 'bookings'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: HHColors.textGold,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeHallTile extends StatelessWidget {
  const _LargeHallTile({required this.largeHall});

  final LargeHall largeHall;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hall = largeHall.hall;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HallDetailScreen(hall: hall)),
          );
        },
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: hall.photos.isEmpty
                  ? Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.meeting_room_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : Image.network(hall.photos.first.url, fit: BoxFit.cover),
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (largeHall.hotelName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        largeHall.hotelName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (hall.capacity.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_2_outlined,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Capacity ${hall.capacity}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
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

class _AllHallsFooter extends StatelessWidget {
  const _AllHallsFooter({required this.controller});

  final AllHallsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!controller.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "You've reached the end.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _BrowsableHallTile extends StatelessWidget {
  const _BrowsableHallTile({required this.browsableHall});

  final BrowsableHall browsableHall;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hall = browsableHall.hall;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HallDetailScreen(hall: hall)),
          );
        },
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: hall.photos.isEmpty
                  ? Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.meeting_room_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : Image.network(hall.photos.first.url, fit: BoxFit.cover),
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (browsableHall.hotelName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        browsableHall.hotelName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (hall.capacity.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups_2_outlined,
                                size: 16,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Capacity ${hall.capacity}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        if (hall.rentAmountCents != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 16,
                                color: HHColors.textGold,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${formatMoneyCents(hall.rentAmountCents)} / '
                                '${hall.rentDurationHours}h',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: HHColors.textGold,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                      ],
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
    final isSaved = context.select<FavoritesController, bool>(
      (favorites) => favorites.isSaved(hotel.id),
    );

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
                child: GestureDetector(
                  onTap: () => context.read<FavoritesController>().toggle(hotel.id),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .88),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: isSaved ? scheme.primary : scheme.onSurface,
                    ),
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
  late final HotelReviewsController _reviewsController = HotelReviewsController(
    ReviewRepository(context.read<ApiClient>()),
    widget.hotelId,
  );

  @override
  void initState() {
    super.initState();
    future = _load();
    _reviewsController.load();
  }

  @override
  void dispose() {
    _reviewsController.dispose();
    super.dispose();
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
                  setState(() {
                    future = _load();
                  });
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
            reviewsController: _reviewsController,
            onHallReturned: () {
              setState(() {
                future = _load();
              });
              _reviewsController.load();
            },
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
    required this.reviewsController,
    required this.onHallReturned,
  });

  final HotelSummary hotel;
  final List<HallSummary> halls;
  final HotelReviewsController reviewsController;
  // Refreshes this screen's own Hotel+Halls fetch after popping back from a
  // Hall's own detail screen (e.g. having booked it there) — otherwise the
  // Halls list and review summary shown here would only ever reflect
  // whatever was true when this screen was first opened.
  final VoidCallback onHallReturned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSaved = context.select<FavoritesController, bool>(
      (favorites) => favorites.isSaved(hotel.id),
    );

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
                  icon: isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  iconColor: isSaved ? scheme.primary : Colors.black87,
                  onTap: () =>
                      context.read<FavoritesController>().toggle(hotel.id),
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
                if (hotel.reviewSummary != null) ...[
                  Row(
                    children: [
                      if (hotel.reviewSummary!.count > 0) ...[
                        StarRatingDisplay(
                          rating: hotel.reviewSummary!.average!.round(),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hotel.reviewSummary!.average!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${hotel.reviewSummary!.count} ${hotel.reviewSummary!.count == 1 ? 'review' : 'reviews'})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ] else
                        Text(
                          'No reviews yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

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

                if (hotel.latitude != null && hotel.longitude != null) ...[
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _HotelLocationMap(
                    latitude: hotel.latitude!,
                    longitude: hotel.longitude!,
                    hotelName: hotel.name,
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
                        onReturned: onHallReturned,
                      ),
                    ),
                  ),

                const SizedBox(height: 28),
                Text(
                  'Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ListenableBuilder(
                  listenable: reviewsController,
                  builder: (context, _) => _ReviewsSection(controller: reviewsController),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.controller});

  final HotelReviewsController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.state) {
      case HotelReviewsState.loading:
        return const Center(child: CircularProgressIndicator());
      case HotelReviewsState.error:
        return _ReviewsMessage(
          message: controller.errorMessage ?? 'Could not load reviews.',
          actionLabel: 'Retry',
          onAction: controller.load,
        );
      case HotelReviewsState.empty:
        return const _ReviewsMessage(message: 'No reviews yet.');
      case HotelReviewsState.loaded:
        return Column(
          children: [
            ...controller.reviews.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ReviewTile(review: review),
              ),
            ),
            if (controller.hasMore)
              controller.isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : TextButton(
                      onPressed: controller.loadMore,
                      child: const Text('Load more reviews'),
                    ),
          ],
        );
    }
  }
}

class _ReviewsMessage extends StatelessWidget {
  const _ReviewsMessage({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRatingDisplay(rating: review.rating),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (review.text?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(review.text!),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

/// A read-only preview of the Hotel's coordinate (`ADR-0008`) — a single
/// fixed pin, no pan/zoom/rotate on the preview itself, so it never fights
/// the surrounding `CustomScrollView` for drag gestures. Tapping it opens
/// [_FullMapScreen], a dedicated full-screen map with pan/zoom enabled, so
/// Customers can still explore the exact location. Only rendered when
/// structured coordinates exist; a Hotel whose `profileData.location` is
/// still the legacy plain-string shape (pre-`BDR-017`) has no
/// `latitude`/`longitude` and simply keeps the existing text-only address
/// display instead.
class _HotelLocationMap extends StatelessWidget {
  const _HotelLocationMap({
    required this.latitude,
    required this.longitude,
    required this.hotelName,
  });

  final double latitude;
  final double longitude;
  final String hotelName;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hotelhallbooking.customer',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        size: 40,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: const [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _FullMapScreen(
                        latitude: latitude,
                        longitude: longitude,
                        hotelName: hotelName,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.zoom_out_map,
                          size: 18,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dedicated, full-screen map with pan/zoom/rotate enabled — reached by
/// tapping the read-only preview in [_HotelLocationMap]. Having no sibling
/// scrollable to fight over drag gestures with, it can safely turn on full
/// interaction so Customers can zoom in and confirm the exact location.
class _FullMapScreen extends StatelessWidget {
  const _FullMapScreen({
    required this.latitude,
    required this.longitude,
    required this.hotelName,
  });

  final double latitude;
  final double longitude;
  final String hotelName;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(hotelName)),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 15,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom |
                InteractiveFlag.drag |
                InteractiveFlag.doubleTapZoom |
                InteractiveFlag.flingAnimation,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.hotelhallbooking.customer',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_pin,
                  size: 40,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          RichAttributionWidget(
            attributions: const [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HallCard extends StatelessWidget {
  const _HallCard({
    required this.hall,
    this.onReturned,
  });

  final HallSummary hall;
  // Called after popping back from Hall Detail (e.g. having booked the
  // Hall there) so the Hotel Detail screen that hosts this card can
  // refresh its own Halls/reviews rather than showing stale data until
  // the Customer leaves and re-enters the whole screen.
  final VoidCallback? onReturned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HallDetailScreen(hall: hall),
            ),
          );
          onReturned?.call();
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
                    if (hall.capacity.isNotEmpty ||
                        hall.rentAmountCents != null) ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (hall.capacity.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                          if (hall.rentAmountCents != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.payments_outlined,
                                  size: 16,
                                  color: HHColors.textGold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${formatMoneyCents(hall.rentAmountCents)} / '
                                  '${hall.rentDurationHours}h',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: HHColors.textGold,
                                      ),
                                ),
                              ],
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

  void _openPhotoViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _HallPhotoViewer(
          photos: hall.photos,
          initialIndex: initialIndex,
        ),
        fullscreenDialog: true,
      ),
    );
  }

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
      final booked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => BookHallScreen(hall: hall)),
      );
      if (booked == true && context.mounted) {
        // Popular Hotels' ranking is Booking-count-driven — mark it stale
        // rather than refetch immediately (the Customer isn't looking at
        // Discover right now), so the next time they actually view that
        // tab it's never showing pre-Booking data.
        context.read<PopularHotelsController>().markStale();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Booking requested. Track its status and payment from My Bookings.',
            ),
          ),
        );
      }
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
                  child: _HallHeroCarousel(
                    photos: hall.photos,
                    onTap: (index) => _openPhotoViewer(context, index),
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

                  if (hall.rentAmountCents != null) ...[
                    const SizedBox(height: 24),
                    PaymentTermsCard(
                      rentAmountCents: hall.rentAmountCents,
                      rentDurationHours: hall.rentDurationHours,
                      advancePaymentPercent: hall.advancePaymentPercent,
                      requiredAdvanceCents: hall.advancePaymentPercent == null
                          ? null
                          : calculateBookingPricingPreview(
                              startsAt: DateTime(2000),
                              endsAt: DateTime(
                                2000,
                              ).add(Duration(hours: hall.rentDurationHours)),
                              rentAmountCents: hall.rentAmountCents!,
                              advancePercent: hall.advancePaymentPercent!,
                            ).requiredAdvanceCents,
                      paymentReceivingNumber: hall.paymentReceivingNumber,
                      customerServiceNumber: hall.customerServiceNumber,
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
                          return GestureDetector(
                            onTap: () => _openPhotoViewer(context, index),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 130,
                                child: _NetworkImage(
                                  url: hall.photos[index].url,
                                ),
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

/// The Hall Detail screen's hero image — auto-advances through the Hall's
/// photos with a smooth slide transition (falling back to the single/no-photo
/// static image when there's nothing to cycle through), still swipeable by
/// hand, and taps through to [_HallPhotoViewer] at whichever photo is
/// currently showing.
class _HallHeroCarousel extends StatefulWidget {
  const _HallHeroCarousel({required this.photos, required this.onTap});

  final List<MediaItem> photos;
  final ValueChanged<int> onTap;

  @override
  State<_HallHeroCarousel> createState() => _HallHeroCarouselState();
}

class _HallHeroCarouselState extends State<_HallHeroCarousel> {
  final _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.photos.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        final next = (_currentIndex + 1) % widget.photos.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return GestureDetector(
        onTap: null,
        child: const _NetworkImage(),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.photos.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => widget.onTap(index),
            child: _NetworkImage(url: widget.photos[index].url),
          ),
        ),
        if (widget.photos.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.photos.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentIndex ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: i == _currentIndex ? 1 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A full-screen, swipeable, pinch-to-zoomable viewer for a Hall's photos —
/// reached by tapping the hero image or any gallery thumbnail on
/// [HallDetailScreen]. Being its own screen (not nested inside the detail
/// screen's `CustomScrollView`), it can safely give each photo an
/// [InteractiveViewer] without fighting a parent scrollable for drag
/// gestures — the same pattern used for the Hotel location map.
class _HallPhotoViewer extends StatefulWidget {
  const _HallPhotoViewer({required this.photos, required this.initialIndex});

  final List<MediaItem> photos;
  final int initialIndex;

  @override
  State<_HallPhotoViewer> createState() => _HallPhotoViewerState();
}

class _HallPhotoViewerState extends State<_HallPhotoViewer> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.network(
                  widget.photos[index].url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 18,
            child: _FloatingCircleButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.photos.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
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
    this.iconColor = Colors.black87,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

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
            color: iconColor,
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

