import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/dashboard_back_button.dart';
import '../../../bookings/data/booking_models.dart';
import '../../../bookings/data/booking_repository.dart';
import '../../../halls/data/hall_repository.dart';
import '../../../halls/presentation/screens/hall_list_screen.dart';
import '../../application/hotel_context_controller.dart';
import '../../data/hotel_models.dart';
import '../../data/hotel_repository.dart';
import '../widgets/hotel_onboarding.dart';
import '../widgets/hotel_profile_header.dart';
import 'hotel_details_screen.dart';
import 'hotel_profile_form_screen.dart';

/// Manager → My Hotel — the minimal navigation level between Home and
/// Halls the requested nav tree calls for. Shows the Hotel's own real
/// `status` field verbatim (no client-side translation into a Visible/
/// Hidden judgment — that stays server-computed, Hall Management Technical
/// Design §6). Once a Hotel exists, [HotelProfileHeader] is this screen's
/// main content — hero photo, name, an at-a-glance stat grid, and an About
/// excerpt — mirroring the approved app mockup's own "My Hotel" screen,
/// restyled with this app's existing light design tokens rather than that
/// mockup's dark theme.
class MyHotelScreen extends StatefulWidget {
  const MyHotelScreen({
    super.key,
    this.embedded = false,
    this.onOpenDashboardTab,
    this.onOpenHallsTab,
    this.onOpenBookingsTab,
  });

  /// True when hosted as the Hotel tab of the bottom-navigation shell
  /// ([HomeScreen]) rather than pushed on top of another screen — since
  /// the shell already triggers the shared [HotelContextController]'s
  /// initial load, skips firing a second one. Still shows a back affordance
  /// either way (the approved app mockup's own "My Hotel" screen has one),
  /// wired to [onOpenDashboardTab] rather than an actual pop when embedded
  /// (a bottom-nav tab has no route of its own to pop).
  final bool embedded;

  /// Switches [HomeScreen] to its own Dashboard/Halls/Bookings tab instead
  /// of pushing a second copy of that screen on top — `null` (e.g. if this
  /// screen is ever hosted standalone) falls back to pushing directly, or
  /// for the back arrow, a plain `Navigator.pop`.
  final VoidCallback? onOpenDashboardTab;
  final VoidCallback? onOpenHallsTab;
  final VoidCallback? onOpenBookingsTab;

  @override
  State<MyHotelScreen> createState() => MyHotelScreenState();
}

/// Public so `HomeScreen` (the `IndexedStack` owner) can hold a `GlobalKey`
/// and call [refresh] explicitly when the Hotel tab is (re)selected — the
/// same reason `DashboardScreenState.refresh`/`BookingsComingSoonScreenState.refresh`
/// exist: without this, a Hall created on the Halls tab (or a Booking taken
/// while this tab sat idle in the background) would leave this screen's
/// stats stale until the app restarts.
class MyHotelScreenState extends State<MyHotelScreen> {
  HotelMediaCollection? _media;
  Future<int>? _hallCountFuture;
  Future<BookingSummary>? _summaryFuture;
  String? _statsLoadedForHotelId;

  Future<void> refresh() async {
    final hotelContext = context.read<HotelContextController>();
    await hotelContext.load();
    if (mounted) _maybeLoadStats(hotelContext.hotel?.id, force: true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final hotelContext = context.read<HotelContextController>();
      if (!widget.embedded || hotelContext.status == HotelContextStatus.unknown) {
        await hotelContext.load();
      }
      _maybeLoadStats(hotelContext.hotel?.id);
    });
  }

  /// The Hotel's Media (Logo + Photos) and its own real stats — hall count
  /// (`HallRepository.listHalls().total`) and booking summary
  /// (`ManagerBookingRepository.summary()`), the same database-side
  /// aggregates `DashboardScreen`'s Overview grid already uses, never
  /// every Hall/Booking fetched client-side just to count them. Cached per
  /// Hotel id so switching back to this tab never re-fetches needlessly.
  void _maybeLoadStats(String? hotelId, {bool force = false}) {
    if (hotelId == null) return;
    if (!force && hotelId == _statsLoadedForHotelId) return;
    _statsLoadedForHotelId = hotelId;
    final apiClient = context.read<ApiClient>();
    // Plain field assignment, not `setState` — this runs from within
    // `build()` itself (the `ready` case below), so the `FutureBuilder`s
    // `HotelProfileHeader` builds later in this same pass already pick up
    // these new Futures directly, the same pattern `DashboardScreen`'s own
    // `_maybeLoadHallCount`/`_maybeLoadSummary` already use.
    _hallCountFuture = HallRepository(apiClient).listHalls(hotelId: hotelId, limit: 1).then((page) => page.total);
    _summaryFuture = ManagerBookingRepository(apiClient).summary(hotelId);
    HotelRepository(apiClient).getMedia(hotelId).then((media) {
      if (mounted) setState(() => _media = media);
    }).catchError((Object _) {
      // The hero photo is a non-essential nicety — falls back to the
      // generic icon rather than surfacing an error for something the
      // Manager didn't explicitly ask to load.
    });
  }

  Future<void> _openHotelDetails() async {
    final hotel = context.read<HotelContextController>().hotel;
    if (hotel == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HotelDetailsScreen(hotelId: hotel.id)),
    );
    if (mounted) _maybeLoadStats(hotel.id, force: true);
  }

  /// Only `APPROVED_ACTIVE`/`REJECTED` Hotels can actually be edited — the
  /// backend rejects `PATCH /hotels/:id` with `422` for every other status
  /// (`hotel.controller.js#updateHotel`), the same guard `HotelDetailsScreen`
  /// already applies before showing its own Edit action.
  Future<void> _openEdit() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const HotelProfileFormScreen()),
    );
    if (done == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hotel profile updated.')),
      );
      final hotelContext = context.read<HotelContextController>();
      await hotelContext.load();
      if (mounted) _maybeLoadStats(hotelContext.hotel?.id, force: true);
    }
  }

  /// Only `APPROVED_ACTIVE`/`REJECTED` Hotels can actually be edited — the
  /// same guard `_openEdit`'s own doc comment and `HotelDetailsScreen`
  /// already state, shared here so the AppBar icon and the bottom "Edit
  /// Profile" button never disagree.
  bool _isEditable(Hotel? hotel) => hotel != null && (hotel.status == 'APPROVED_ACTIVE' || hotel.status == 'REJECTED');

  void _openHallsTab() {
    if (widget.onOpenHallsTab != null) {
      widget.onOpenHallsTab!();
      return;
    }
    final hotel = context.read<HotelContextController>().hotel;
    if (hotel == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HallListScreen(hotelId: hotel.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotelContext = context.watch<HotelContextController>();

    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(
        title: const Text('My Hotel'),
        centerTitle: true,
        leading: DashboardBackButton(embedded: widget.embedded, onOpenDashboardTab: widget.onOpenDashboardTab),
        actions: [
          if (_isEditable(hotelContext.hotel))
            IconButton(onPressed: _openEdit, icon: const Icon(Icons.edit_outlined), tooltip: 'Edit Profile'),
        ],
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
        _maybeLoadStats(hotel.id);
        return RefreshIndicator(
          onRefresh: () async {
            await hotelContext.load();
            _maybeLoadStats(hotelContext.hotel?.id, force: true);
          },
          child: ListView(
            padding: const EdgeInsets.all(HHSpacing.space7),
            children: [
              HotelProfileHeader(
                hotel: hotel,
                media: _media,
                reviewSummary: hotelContext.reviewSummary,
                hallCountFuture: _hallCountFuture,
                summaryFuture: _summaryFuture,
                onOpenPhotos: _openHotelDetails,
                onOpenHallsTab: _openHallsTab,
                onOpenBookingsTab: widget.onOpenBookingsTab,
                onEdit: _isEditable(hotel) ? _openEdit : null,
              ),
              if (hotelContext.errorMessage != null) ...[
                const SizedBox(height: HHSpacing.space5),
                HHErrorBanner(message: hotelContext.errorMessage!),
              ],
              ...hotelOnboardingSteps(context, hotelContext, hotel),
              const SizedBox(height: HHSpacing.space7),
              HHPrimaryButton(
                label: 'Manage Halls',
                isLoading: false,
                onPressed: _openHallsTab,
              ),
            ],
          ),
        );
    }
  }
}
