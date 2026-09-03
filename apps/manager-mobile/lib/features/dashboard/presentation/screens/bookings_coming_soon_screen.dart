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
      _BookingsComingSoonScreenState();
}

class _BookingsComingSoonScreenState extends State<BookingsComingSoonScreen> {
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

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onAction});
  final ManagerBooking booking;
  final void Function(String action, Object? body) onAction;

  @override
  Widget build(BuildContext context) => HHCard(
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
        const SizedBox(height: HHSpacing.space4),
        Wrap(
          spacing: HHSpacing.space2,
          runSpacing: HHSpacing.space2,
          children: _actions(),
        ),
      ],
    ),
  );

  List<Widget> _actions() {
    if (booking.status == 'PENDING' &&
        booking.paymentStatus == 'CUSTOMER_REPORTED')
      return [
        FilledButton(
          onPressed: () =>
              onAction('payment-verification', {'decision': 'VERIFY'}),
          child: const Text('Verify Payment'),
        ),
        OutlinedButton(
          onPressed: () => onAction('payment-verification', {
            'decision': 'REJECT',
            'reason': 'Payment could not be verified.',
          }),
          child: const Text('Reject Payment'),
        ),
      ];
    if (booking.status == 'PENDING' && booking.paymentStatus == 'PAID')
      return [
        FilledButton(
          onPressed: () => onAction('confirmation', null),
          child: const Text('Confirm'),
        ),
      ];
    if (booking.status == 'PENDING')
      return [
        OutlinedButton(
          onPressed: () => onAction('rejection', null),
          child: const Text('Reject Booking'),
        ),
        OutlinedButton(
          onPressed: () => onAction('cancellation', null),
          child: const Text('Cancel'),
        ),
      ];
    if (booking.status == 'CONFIRMED')
      return [
        OutlinedButton(
          onPressed: () => onAction('completion', null),
          child: const Text('Complete'),
        ),
        OutlinedButton(
          onPressed: () => onAction('no-show', null),
          child: const Text('No-show'),
        ),
      ];
    return const [];
  }
}
