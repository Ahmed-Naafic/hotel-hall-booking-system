import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../reviews/presentation/widgets/star_rating.dart';
import '../../data/booking_models.dart';
import '../../data/booking_repository.dart';
import '../widgets/leave_review_dialog.dart';
import '../widgets/payment_terms.dart';

/// Customer → a single Booking's detail (Booking Management V1 correction
/// #2/#3) — Hotel, Hall, date/time, guests, event type, special request,
/// booking status, payment status, and payment amount information, via the
/// existing `GET /bookings/:id`. Also hosts cancellation (#3) and reporting
/// a payment (#1) for a Booking still awaiting one — no field here is
/// invented beyond what the backend already returns.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  String? _error;
  bool _busy = false;

  BookingRepository get _repository =>
      BookingRepository(context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final booking = await _repository.get(widget.bookingId);
      if (mounted) setState(() => _booking = booking);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      final updated = await _repository.cancel(widget.bookingId);
      if (mounted) setState(() => _booking = updated);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leaveReview() async {
    final booking = _booking;
    if (booking == null) return;
    setState(() => _busy = true);
    final updated = await promptSubmitReview(
      context,
      booking: booking,
      repository: _repository,
    );
    if (updated != null && mounted) setState(() => _booking = updated);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reportPayment() async {
    final booking = _booking;
    if (booking == null) return;
    setState(() => _busy = true);
    final reported = await promptReportPayment(
      context,
      booking: booking,
      repository: _repository,
    );
    if (reported) await _load();
    if (mounted) setState(() => _busy = false);
  }

  // Cancellation applies to any still-applicable Booking (PENDING or
  // CONFIRMED) regardless of payment state (no refund logic is triggered —
  // paymentStatus is left exactly as it was).
  bool get _canCancel =>
      _booking?.status == 'PENDING' || _booking?.status == 'CONFIRMED';

  bool get _canReportPayment =>
      _booking?.status == 'PENDING' &&
      (_booking?.paymentStatus == 'UNPAID' || _booking?.paymentStatus == 'REJECTED');

  // Ratings & Reviews V1 (approved business decisions) — only a COMPLETED
  // Booking not already reviewed may be reviewed; the backend is still the
  // sole authority (it re-checks this on submit), this only decides whether
  // to show the button at all.
  bool get _canLeaveReview =>
      _booking?.status == 'COMPLETED' && _booking?.review == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Booking Details')),
      body: SafeArea(child: _body()),
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
    final booking = _booking;
    if (booking == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(HHSpacing.space7),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.hall?.name ?? 'Hall',
                  style: TextStyle(
                    fontWeight: HHTypeScale.weightSemibold,
                    fontSize: HHTypeScale.textLg,
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
            Text(booking.hotel!.name!, style: TextStyle(color: HHColors.textMuted)),
          ],
          const SizedBox(height: HHSpacing.space5),
          HHCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HHSectionLabel('BOOKING DETAILS'),
                const SizedBox(height: HHSpacing.space3),
                _row('Date/time', '${booking.startsAt.toLocal()} – ${booking.endsAt.toLocal()}'),
                _row('Guests', '${booking.numberOfGuests}'),
                _row('Event type', booking.eventType.replaceAll('_', ' ')),
                if (booking.specialRequest?.trim().isNotEmpty == true)
                  _row('Special request', booking.specialRequest!),
              ],
            ),
          ),
          const SizedBox(height: HHSpacing.space5),
          HHCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HHSectionLabel('PAYMENT STATUS'),
                const SizedBox(height: HHSpacing.space3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: TextStyle(color: HHColors.textMuted)),
                    HHStatusBadge(
                      label: booking.paymentStatus,
                      tone: bookingStatusTone(booking.paymentStatus),
                    ),
                  ],
                ),
                if (booking.reportedAmountCents != null)
                  _row('Amount you reported', formatMoneyCents(booking.reportedAmountCents)),
                if (booking.paymentRejectionReason?.trim().isNotEmpty == true)
                  _row('Hotel\'s note', booking.paymentRejectionReason!),
              ],
            ),
          ),
          const SizedBox(height: HHSpacing.space5),
          PaymentTermsCard(
            rentAmountCents: booking.totalRentCents,
            rentDurationHours: booking.hall?.rentDurationHours ?? 24,
            advancePaymentPercent: booking.advancePercent,
            requiredAdvanceCents: booking.requiredAdvanceCents,
            paymentReceivingNumber: booking.hall?.paymentReceivingNumber ?? '',
            customerServiceNumber: booking.hall?.customerServiceNumber ?? '',
          ),
          if (booking.review != null) ...[
            const SizedBox(height: HHSpacing.space5),
            HHCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HHSectionLabel('YOUR REVIEW'),
                  const SizedBox(height: HHSpacing.space3),
                  StarRatingDisplay(rating: booking.review!.rating),
                  if (booking.review!.text?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: HHSpacing.space3),
                    Text(booking.review!.text!),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: HHSpacing.space7),
          if (_canReportPayment)
            HHPrimaryButton(
              label: 'Report Payment Sent',
              isLoading: _busy,
              onPressed: _reportPayment,
            ),
          if (_canLeaveReview) ...[
            const SizedBox(height: HHSpacing.space4),
            HHPrimaryButton(
              label: 'Leave a Review',
              isLoading: _busy,
              onPressed: _leaveReview,
            ),
          ],
          if (_canCancel) ...[
            const SizedBox(height: HHSpacing.space4),
            OutlinedButton(
              onPressed: _busy ? null : _cancel,
              child: const Text('Cancel Booking'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: HHSpacing.space1),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: HHColors.textMuted)),
        const SizedBox(width: HHSpacing.space3),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: HHTypeScale.weightSemibold),
          ),
        ),
      ],
    ),
  );
}
