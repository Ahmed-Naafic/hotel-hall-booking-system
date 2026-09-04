import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../data/booking_models.dart';
import '../../data/booking_repository.dart';
import '../widgets/payment_terms.dart';
import 'booking_detail_screen.dart';

/// Customer → My Bookings (Booking Management V1 correction #2) — the
/// Customer's own booking history via the existing `GET /bookings`.
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<Booking>? _bookings;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rows = await BookingRepository(context.read<ApiClient>()).list();
      if (mounted) setState(() => _bookings = rows);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('My Bookings')),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _load, child: _body()),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return HHEmptyState(
        icon: Icons.error_outline,
        message: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }
    if (_bookings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bookings!.isEmpty) {
      return const HHEmptyState(
        icon: Icons.event_note_outlined,
        title: 'No bookings yet',
        message: 'Bookings you request will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(HHSpacing.space5),
      itemCount: _bookings!.length,
      separatorBuilder: (_, __) => const SizedBox(height: HHSpacing.space4),
      itemBuilder: (context, index) {
        final booking = _bookings![index];
        return HHCard(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookingDetailScreen(bookingId: booking.id),
              ),
            );
            _load();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.hall?.name ?? booking.eventType.replaceAll('_', ' '),
                      style: TextStyle(
                        fontWeight: HHTypeScale.weightSemibold,
                        fontSize: HHTypeScale.textMd,
                      ),
                    ),
                  ),
                  HHStatusBadge(
                    label: booking.status,
                    tone: bookingStatusTone(booking.status),
                  ),
                ],
              ),
              if (booking.hotel?.name != null) ...[
                const SizedBox(height: HHSpacing.space1),
                Text(
                  booking.hotel!.name!,
                  style: TextStyle(color: HHColors.textMuted),
                ),
              ],
              const SizedBox(height: HHSpacing.space3),
              Text(
                '${booking.startsAt.toLocal()} – ${booking.endsAt.toLocal()}',
                style: TextStyle(
                  color: HHColors.textMuted,
                  fontSize: HHTypeScale.textSm,
                ),
              ),
              const SizedBox(height: HHSpacing.space2),
              Row(
                children: [
                  Text(
                    '${booking.numberOfGuests} guests • ${formatMoneyCents(booking.totalRentCents)}',
                    style: TextStyle(color: HHColors.textMuted),
                  ),
                  const Spacer(),
                  HHStatusBadge(
                    label: booking.paymentStatus,
                    tone: bookingStatusTone(booking.paymentStatus),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
