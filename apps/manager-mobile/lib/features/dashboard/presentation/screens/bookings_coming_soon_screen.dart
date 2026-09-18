import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/booking_list_tile.dart';
import '../../../../core/presentation/dashboard_back_button.dart';
import '../../../../core/presentation/manager_formatters.dart';
import '../../../bookings/data/booking_models.dart';
import '../../../bookings/data/booking_repository.dart';
import '../../../chat/presentation/screens/chat_screen.dart';

/// Manager → Bookings tab — every Booking for the Hotel, searchable by
/// Customer name/mobile/Hall and filterable by status (All/Confirmed/
/// Pending, matching the approved app mockup exactly). A row is a compact
/// summary only; tapping it opens the full detail plus lifecycle actions
/// (Verify Payment, Confirm, Reject, Cancel, Complete, No-show) in a
/// bottom sheet — the mockup itself shows no inline actions, so those stay
/// out of the list and behind one tap instead.
class BookingsComingSoonScreen extends StatefulWidget {
  const BookingsComingSoonScreen({
    super.key,
    this.hotelId,
    this.active = true,
    this.embedded = false,
    this.onOpenDashboardTab,
  });

  final String? hotelId;
  final bool active;

  /// True when hosted as the Bookings tab of the bottom-navigation shell
  /// ([HomeScreen]) — matches the same convention [HallListScreen]/
  /// [MyHotelScreen] already use ([DashboardBackButton]).
  final bool embedded;
  final VoidCallback? onOpenDashboardTab;

  @override
  State<BookingsComingSoonScreen> createState() =>
      BookingsComingSoonScreenState();
}

/// Public so `HomeScreen` (the `IndexedStack` owner) can hold a `GlobalKey`
/// and call [refresh] explicitly when the Bookings tab is (re)selected —
/// the same reason `DashboardScreenState.refresh` exists: an `IndexedStack`
/// tab has no built-in "became visible again" callback, so without this a
/// Booking created while this tab sat alive in the background (e.g. a
/// Customer books while the Manager is on the Home tab) would never appear
/// until the app restarts.
class BookingsComingSoonScreenState extends State<BookingsComingSoonScreen> {
  List<ManagerBooking>? _bookings;
  String? _error;
  String? _loadedHotelId;

  String _search = '';
  // null = "All"; otherwise the exact backend status value ('CONFIRMED' /
  // 'PENDING') — matching the mockup's own 3 chips, never every possible
  // BookingStatus value.
  String? _statusFilter;

  Future<void> _load(String hotelId) async {
    setState(() {
      _loadedHotelId = hotelId;
      _error = null;
    });
    try {
      final rows = await ManagerBookingRepository(
        context.read<ApiClient>(),
      ).list(hotelId);
      if (mounted) setState(() => _bookings = rows);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  /// Called by `HomeScreen` when the Bookings tab becomes selected again —
  /// always re-fetches, never relies on `_loadedHotelId` staying unchanged
  /// (that guard exists only to avoid a redundant fetch on first build).
  Future<void> refresh() async {
    if (widget.hotelId != null) await _load(widget.hotelId!);
  }

  /// Returns the Booking as it stands after the action, or `null` if the
  /// action failed — the open detail sheet re-renders itself from this, so a
  /// Manager who verifies a payment sees the next valid action appear without
  /// closing and reopening the sheet.
  Future<ManagerBooking?> _action(
    String hotelId,
    ManagerBooking booking,
    String action, {
    Object? body,
  }) async {
    try {
      final updated = await ManagerBookingRepository(
        context.read<ApiClient>(),
      ).action(hotelId, booking.id, action, body: body);
      await _load(hotelId);
      return updated;
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return null;
    }
  }

  void _openDetail(String hotelId, ManagerBooking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BookingDetailSheet(
        booking: booking,
        onAction: (action, body) => _action(hotelId, booking, action, body: body),
      ),
    );
  }

  List<ManagerBooking> _applyFilters(List<ManagerBooking> bookings) {
    final query = _search.trim().toLowerCase();
    return bookings.where((booking) {
      if (_statusFilter != null && booking.status != _statusFilter) return false;
      if (query.isEmpty) return true;
      final name = (booking.customerFullName ?? '').toLowerCase();
      final mobile = (booking.customerMobileNumber ?? '').toLowerCase();
      final hall = (booking.hallName ?? '').toLowerCase();
      return name.contains(query) || mobile.contains(query) || hall.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active && widget.hotelId != null && _loadedHotelId != widget.hotelId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(widget.hotelId!));
    }
    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(
        title: const Text('Bookings'),
        centerTitle: true,
        leading: DashboardBackButton(embedded: widget.embedded, onOpenDashboardTab: widget.onOpenDashboardTab),
      ),
      body: SafeArea(child: _body(widget.hotelId)),
    );
  }

  Widget _body(String? hotelId) {
    if (hotelId == null) {
      return const HHEmptyState(
        icon: Icons.apartment_outlined,
        title: 'Set up your Hotel',
        message: 'Bookings will appear after your Hotel is set up.',
      );
    }

    final bookings = _bookings;
    final allCount = bookings?.length;
    final confirmedCount = bookings?.where((b) => b.status == 'CONFIRMED').length;
    final pendingCount = bookings?.where((b) => b.status == 'PENDING').length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            HHSpacing.space5,
            HHSpacing.space4,
            HHSpacing.space5,
            HHSpacing.space3,
          ),
          child: TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: const InputDecoration(
              hintText: 'Search bookings...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space5),
          child: Row(
            // All at the left edge, Pending at the right edge, Confirmed
            // landing in the true center between them.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusFilterChip(
                label: 'All',
                count: allCount,
                selected: _statusFilter == null,
                onTap: () => setState(() => _statusFilter = null),
              ),
              _StatusFilterChip(
                label: 'Confirmed',
                count: confirmedCount,
                selected: _statusFilter == 'CONFIRMED',
                onTap: () => setState(() => _statusFilter = 'CONFIRMED'),
              ),
              _StatusFilterChip(
                label: 'Pending',
                count: pendingCount,
                selected: _statusFilter == 'PENDING',
                onTap: () => setState(() => _statusFilter = 'PENDING'),
              ),
            ],
          ),
        ),
        const SizedBox(height: HHSpacing.space3),
        Expanded(child: _content(hotelId, bookings)),
      ],
    );
  }

  Widget _content(String hotelId, List<ManagerBooking>? bookings) {
    if (_error != null) {
      return HHEmptyState(
        icon: Icons.error_outline,
        message: _error!,
        actionLabel: 'Retry',
        onAction: () => _load(hotelId),
      );
    }
    if (bookings == null) {
      return widget.active
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }
    if (bookings.isEmpty) {
      return const HHEmptyState(
        icon: Icons.event_available_outlined,
        title: 'No bookings yet',
        message: 'Customer booking requests will appear here.',
      );
    }

    final filtered = _applyFilters(bookings);
    if (filtered.isEmpty) {
      return HHEmptyState(
        icon: Icons.search_off,
        title: 'No bookings match',
        message: 'Try a different search or filter.',
        actionLabel: 'Clear filters',
        onAction: () async => setState(() {
          _search = '';
          _statusFilter = null;
        }),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(hotelId),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          HHSpacing.space5,
          0,
          HHSpacing.space5,
          HHSpacing.space5,
        ),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: HHSpacing.space3),
        itemBuilder: (context, index) {
          final booking = filtered[index];
          return BookingListTile(
            booking: booking,
            onTap: () => _openDetail(hotelId, booking),
          );
        },
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = count == null ? label : '$label ($count)';
    return Material(
      color: selected ? context.hh.actionPrimary : context.hh.surfaceSunken,
      borderRadius: BorderRadius.circular(HHRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HHRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HHSpacing.space5,
            vertical: HHSpacing.space3,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? context.hh.textInverse : context.hh.textMuted,
              fontWeight: selected ? HHTypeScale.weightSemibold : HHTypeScale.weightRegular,
              fontSize: HHTypeScale.textSm,
            ),
          ),
        ),
      ),
    );
  }
}

/// The Booking's full detail plus every lifecycle action valid for its
/// current status/paymentStatus — everything `_BookingCard` used to show
/// inline in the list, now behind one tap instead (the mockup's own
/// Bookings screen shows no inline actions at all).
class _BookingDetailSheet extends StatefulWidget {
  const _BookingDetailSheet({required this.booking, required this.onAction});
  final ManagerBooking booking;
  final Future<ManagerBooking?> Function(String action, Object? body) onAction;

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  // Which action is currently in flight, if any — drives both the tapped
  // button's spinner and disabling every other action on this card so a
  // second tap can't fire while the first is still pending.
  String? _pendingKey;

  // The Booking as this sheet currently knows it. A bottom sheet is its own
  // route, so the parent screen reloading its list behind it does not rebuild
  // this — without tracking the result here, verifying a payment left the
  // sheet rendering the pre-verification Booking and its "Confirm" button
  // hidden until the Manager closed and reopened the sheet.
  late ManagerBooking _booking = widget.booking;

  /// [closeAfter] distinguishes a step from a decision: verifying or
  /// rejecting a payment leaves the Manager with a further call to make on
  /// this Booking, so the sheet stays open and re-renders; confirming,
  /// rejecting, cancelling, completing or marking a no-show settles it, so
  /// the sheet closes rather than lingering on a Booking already dealt with.
  Future<void> _run(
    String key,
    String action,
    Object? body, {
    bool closeAfter = true,
  }) async {
    setState(() => _pendingKey = key);
    try {
      final updated = await widget.onAction(action, body);
      if (!mounted || updated == null) return;
      if (closeAfter) {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _booking = updated);
    } finally {
      if (mounted) setState(() => _pendingKey = null);
    }
  }

  // The required advance is informational for the Manager's own judgment,
  // never a backend-enforced floor (approved decision) — verifying an
  // amount below it is allowed, but only after this explicit confirmation,
  // so it's never mistaken for a silent no-op tap.
  Future<void> _verifyPayment() async {
    final booking = _booking;
    final insufficient = booking.reportedAmountCents != null &&
        booking.reportedAmountCents! < booking.requiredAdvanceCents;
    if (insufficient) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reported amount is short'),
          content: Text(
            'The Customer reported \$${(booking.reportedAmountCents! / 100).toStringAsFixed(2)}, '
            'less than the required \$${(booking.requiredAdvanceCents / 100).toStringAsFixed(2)}. '
            'Verify anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verify Anyway'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _run(
      'verify',
      'payment-verification',
      {'decision': 'VERIFY'},
      closeAfter: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final timingHint = _timingHint;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.hh.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(HHRadii.modal)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              HHSpacing.space6,
              HHSpacing.space3,
              HHSpacing.space6,
              HHSpacing.space7,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: HHSpacing.space5),
                  decoration: BoxDecoration(
                    color: context.hh.borderDefault,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.eventType.replaceAll('_', ' '),
                      style: TextStyle(
                        fontWeight: HHTypeScale.weightSemibold,
                        fontSize: HHTypeScale.textLg,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Messages',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatScreen(bookingId: booking.id)),
                    ),
                  ),
                  HHStatusBadge(
                    label: ManagerFormatters.status(booking.status),
                    tone: toneForBookingStatus(booking.status),
                  ),
                ],
              ),
              const SizedBox(height: HHSpacing.space4),
              if (booking.hallName != null) ...[
                Text(
                  booking.hallName!,
                  style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textMd),
                ),
                const SizedBox(height: HHSpacing.space2),
              ],
              // BDR-018 — the Customer's own Full Name/Mobile Number, never
              // a fake placeholder; `null` only for a pre-BDR-018 account
              // that has not since set a name (booking_models.dart's own
              // doc comment).
              if (booking.customerFullName != null || booking.customerMobileNumber != null)
                Row(
                  children: [
                    _CustomerAvatar(
                      name: booking.customerFullName ?? booking.customerMobileNumber ?? 'Customer',
                      avatarUrl: booking.customerAvatarUrl,
                    ),
                    const SizedBox(width: HHSpacing.space3),
                    Expanded(
                      child: Text(
                        [
                          if (booking.customerFullName != null) booking.customerFullName!,
                          if (booking.customerMobileNumber != null) booking.customerMobileNumber!,
                        ].join(' • '),
                        style: TextStyle(color: context.hh.textMuted),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: HHSpacing.space2),
              Text(
                '${booking.guests} guests • \$${(booking.totalRentCents / 100).toStringAsFixed(2)}',
                style: TextStyle(color: context.hh.textMuted),
              ),
              Text(
                '${ManagerFormatters.date(booking.startsAt)} • '
                '${ManagerFormatters.time(booking.startsAt)} – ${ManagerFormatters.time(booking.endsAt)}',
                style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textSm),
              ),
              if (booking.paymentStatus == 'CUSTOMER_REPORTED' &&
                  booking.reportedAmountCents != null) ...[
                const SizedBox(height: HHSpacing.space4),
                Text(
                  'Customer reported: \$${(booking.reportedAmountCents! / 100).toStringAsFixed(2)} '
                  '(required: \$${(booking.requiredAdvanceCents / 100).toStringAsFixed(2)})',
                  style: TextStyle(
                    fontWeight: HHTypeScale.weightSemibold,
                    color: booking.reportedAmountCents! >= booking.requiredAdvanceCents
                        ? context.hh.success700
                        : context.hh.danger700,
                  ),
                ),
              ],
              // BDR-024 — set only when the Customer cancelled a Confirmed
              // booking; never shown otherwise.
              if (booking.cancellationReason != null) ...[
                const SizedBox(height: HHSpacing.space4),
                Text(
                  'Customer\'s reason for cancelling: ${booking.cancellationReason}',
                  style: TextStyle(color: context.hh.textMuted),
                ),
              ],
              const SizedBox(height: HHSpacing.space5),
              Wrap(
                spacing: HHSpacing.space2,
                runSpacing: HHSpacing.space2,
                children: _actions(context),
              ),
              if (timingHint != null) ...[
                const SizedBox(height: HHSpacing.space3),
                Text(
                  timingHint,
                  style: TextStyle(
                    fontSize: HHTypeScale.textSm,
                    color: context.hh.textMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _spinner({required bool filled}) => SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: filled ? Theme.of(context).colorScheme.onPrimary : null,
    ),
  );

  Widget _button({
    required String actionKey,
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
    bool enabled = true,
  }) {
    final isPending = _pendingKey == actionKey;
    final isDisabled = _pendingKey != null || !enabled;
    final child = isPending ? _spinner(filled: filled) : Text(label);
    return filled
        ? FilledButton(onPressed: isDisabled ? null : onPressed, child: child)
        : OutlinedButton(onPressed: isDisabled ? null : onPressed, child: child);
  }

  // Completion and No-show are refused by the backend until the Booking's own
  // clock reaches them (422 "A booking can only be completed after it ends." /
  // "...marked no-show after it starts."). Mirrored here so the Manager is
  // never offered a button that cannot succeed — the backend stays the
  // authority, this only avoids the guaranteed-failure tap.
  bool get _hasStarted => !DateTime.now().isBefore(_booking.startsAt);
  bool get _hasEnded => !DateTime.now().isBefore(_booking.endsAt);

  /// Why Complete/No-show are greyed out, or `null` when nothing is waiting
  /// on the clock.
  String? get _timingHint {
    if (_booking.status != 'CONFIRMED' || _hasEnded) return null;
    if (!_hasStarted) {
      return 'No-show can be marked once this Booking starts, and Complete once it ends.';
    }
    return 'Complete can be marked once this Booking ends.';
  }

  // Cancellation applies to any still-applicable Booking (PENDING or
  // CONFIRMED) regardless of payment state — it is offered alongside
  // whichever other actions that status/payment combination already
  // exposes, never in place of them.
  List<Widget> _actions(BuildContext context) {
    final booking = _booking;
    final actions = <Widget>[];
    if (booking.status == 'PENDING' &&
        booking.paymentStatus == 'CUSTOMER_REPORTED') {
      actions.addAll([
        _button(
          actionKey: 'verify',
          label: 'Verify Payment',
          filled: true,
          onPressed: _verifyPayment,
        ),
        _button(
          actionKey: 'reject-payment',
          label: 'Reject Payment',
          onPressed: () => _run(
            'reject-payment',
            'payment-verification',
            {
              'decision': 'REJECT',
              'reason': 'Payment could not be verified.',
            },
            closeAfter: false,
          ),
        ),
      ]);
    } else if (booking.status == 'PENDING' &&
        booking.paymentStatus == 'PAID') {
      actions.add(
        _button(
          actionKey: 'confirm',
          label: 'Confirm',
          filled: true,
          onPressed: () => _run('confirm', 'confirmation', null),
        ),
      );
    } else if (booking.status == 'PENDING') {
      actions.add(
        _button(
          actionKey: 'reject-booking',
          label: 'Reject Booking',
          onPressed: () => _run('reject-booking', 'rejection', null),
        ),
      );
    }
    if (booking.status == 'PENDING' || booking.status == 'CONFIRMED') {
      actions.add(
        _button(
          actionKey: 'cancel',
          label: 'Cancel',
          onPressed: () => _run('cancel', 'cancellation', null),
        ),
      );
    }
    if (booking.status == 'CONFIRMED') {
      actions.addAll([
        _button(
          actionKey: 'complete',
          label: 'Complete',
          enabled: _hasEnded,
          onPressed: () => _run('complete', 'completion', null),
        ),
        _button(
          actionKey: 'no-show',
          label: 'No-show',
          enabled: _hasStarted,
          onPressed: () => _run('no-show', 'no-show', null),
        ),
      ]);
    }
    return actions;
  }
}

/// Same photo-or-initials rendering as [BookingListTile], duplicated here
/// (rather than shared) because this sheet's avatar sits inline with a
/// two-line text block instead of a `HHCard` row.
class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    Widget initialsAvatar() => CircleAvatar(
      radius: 20,
      backgroundColor: context.hh.surfaceNavyTint,
      child: Text(initial, style: TextStyle(color: context.hh.textHeading, fontWeight: HHTypeScale.weightSemibold)),
    );

    if (avatarUrl == null || avatarUrl!.isEmpty) return initialsAvatar();
    return ClipOval(
      child: Image.network(
        avatarUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => initialsAvatar(),
      ),
    );
  }
}
