import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';
import '../../../bookings/data/booking_models.dart';
import '../../../bookings/data/booking_repository.dart';

/// Manager → Bookings tab. Booking management has no backend API yet —
/// this screen deliberately shows nothing but an acknowledgement, never a
/// fake list, fake stats, or a disabled preview of unimplemented UI.
class BookingsComingSoonScreen extends StatefulWidget {
  const BookingsComingSoonScreen({super.key, this.hotelId, this.active = true});

  final String? hotelId;
  final bool active;

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

  Future<void> _action(
    String hotelId,
    ManagerBooking booking,
    String action, {
    Object? body,
  }) async {
    try {
      await ManagerBookingRepository(
        context.read<ApiClient>(),
      ).action(hotelId, booking.id, action, body: body);
      await _load(hotelId);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active && widget.hotelId != null && _loadedHotelId != widget.hotelId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(widget.hotelId!));
    }
    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Bookings')),
      body: SafeArea(child: _body(widget.hotelId)),
    );
  }

  Widget _body(String? hotelId) {
    if (hotelId == null)
      return const HHEmptyState(
        icon: Icons.apartment_outlined,
        title: 'Set up your Hotel',
        message: 'Bookings will appear after your Hotel is set up.',
      );
    if (_error != null)
      return HHEmptyState(
        icon: Icons.error_outline,
        message: _error!,
        actionLabel: 'Retry',
        onAction: () => _load(hotelId),
      );
    if (_bookings == null) {
      return widget.active
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }
    if (_bookings!.isEmpty)
      return const HHEmptyState(
        icon: Icons.event_available_outlined,
        title: 'No bookings yet',
        message: 'Customer booking requests will appear here.',
      );
    return RefreshIndicator(
      onRefresh: () => _load(hotelId),
      child: ListView.separated(
        padding: const EdgeInsets.all(HHSpacing.space5),
        itemCount: _bookings!.length,
        separatorBuilder: (_, __) => const SizedBox(height: HHSpacing.space4),
        itemBuilder: (context, index) => _BookingCard(
          booking: _bookings![index],
          onAction: (action, body) =>
              _action(hotelId, _bookings![index], action, body: body),
        ),
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  const _BookingCard({required this.booking, required this.onAction});
  final ManagerBooking booking;
  final Future<void> Function(String action, Object? body) onAction;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  // Which action is currently in flight, if any — drives both the tapped
  // button's spinner and disabling every other action on this card so a
  // second tap can't fire while the first is still pending.
  String? _pendingKey;

  Future<void> _run(String key, String action, Object? body) async {
    setState(() => _pendingKey = key);
    try {
      await widget.onAction(action, body);
    } finally {
      if (mounted) setState(() => _pendingKey = null);
    }
  }

  // The required advance is informational for the Manager's own judgment,
  // never a backend-enforced floor (approved decision) — verifying an
  // amount below it is allowed, but only after this explicit confirmation,
  // so it's never mistaken for a silent no-op tap.
  Future<void> _verifyPayment() async {
    final booking = widget.booking;
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
    await _run('verify', 'payment-verification', {'decision': 'VERIFY'});
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return HHCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.eventType.replaceAll('_', ' '),
                  style: TextStyle(
                    fontWeight: HHTypeScale.weightSemibold,
                    fontSize: HHTypeScale.textMd,
                  ),
                ),
              ),
              HHStatusBadge(label: booking.status),
            ],
          ),
          const SizedBox(height: HHSpacing.space3),
          Text(
            '${booking.guests} guests • \$${(booking.totalRentCents / 100).toStringAsFixed(2)}',
            style: TextStyle(color: HHColors.textMuted),
          ),
          Text(
            '${booking.startsAt.toLocal()} – ${booking.endsAt.toLocal()}',
            style: TextStyle(
              color: HHColors.textMuted,
              fontSize: HHTypeScale.textSm,
            ),
          ),
          if (booking.paymentStatus == 'CUSTOMER_REPORTED' &&
              booking.reportedAmountCents != null) ...[
            const SizedBox(height: HHSpacing.space3),
            Text(
              'Customer reported: \$${(booking.reportedAmountCents! / 100).toStringAsFixed(2)} '
              '(required: \$${(booking.requiredAdvanceCents / 100).toStringAsFixed(2)})',
              style: TextStyle(
                fontWeight: HHTypeScale.weightSemibold,
                color: booking.reportedAmountCents! >= booking.requiredAdvanceCents
                    ? HHColors.success700
                    : HHColors.danger700,
              ),
            ),
          ],
          const SizedBox(height: HHSpacing.space4),
          Wrap(
            spacing: HHSpacing.space2,
            runSpacing: HHSpacing.space2,
            children: _actions(context),
          ),
        ],
      ),
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
  }) {
    final isPending = _pendingKey == actionKey;
    final isDisabled = _pendingKey != null;
    final child = isPending ? _spinner(filled: filled) : Text(label);
    return filled
        ? FilledButton(onPressed: isDisabled ? null : onPressed, child: child)
        : OutlinedButton(onPressed: isDisabled ? null : onPressed, child: child);
  }

  // Cancellation applies to any still-applicable Booking (PENDING or
  // CONFIRMED) regardless of payment state — it is offered alongside
  // whichever other actions that status/payment combination already
  // exposes, never in place of them.
  List<Widget> _actions(BuildContext context) {
    final booking = widget.booking;
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
          onPressed: () => _run('reject-payment', 'payment-verification', {
            'decision': 'REJECT',
            'reason': 'Payment could not be verified.',
          }),
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
          onPressed: () => _run('complete', 'completion', null),
        ),
        _button(
          actionKey: 'no-show',
          label: 'No-show',
          onPressed: () => _run('no-show', 'no-show', null),
        ),
      ]);
    }
    return actions;
  }
}
