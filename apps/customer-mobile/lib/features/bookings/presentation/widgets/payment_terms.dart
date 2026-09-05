import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../data/booking_models.dart';
import '../../data/booking_repository.dart';

String formatMoneyCents(int? cents) =>
    cents == null ? '—' : '\$${(cents / 100).toStringAsFixed(2)}';

/// The Hall's commercial/payment terms — Rent, the fixed 24-hour rent unit,
/// the 30% advance percentage, the system-calculated required advance, and
/// where to send it. Shown before the Customer submits a booking (on the
/// Book Hall form, with a live-updating [requiredAdvanceCents] preview) and
/// again on an existing Booking's detail screen (with the immutable
/// snapshot the backend actually charged) — same widget, same figures,
/// never re-derived differently in two places.
class PaymentTermsCard extends StatelessWidget {
  const PaymentTermsCard({
    super.key,
    required this.rentAmountCents,
    required this.rentDurationHours,
    required this.advancePaymentPercent,
    required this.requiredAdvanceCents,
    required this.paymentReceivingNumber,
    required this.customerServiceNumber,
  });

  final int? rentAmountCents;
  final int rentDurationHours;
  final double? advancePaymentPercent;
  final int? requiredAdvanceCents;
  final String paymentReceivingNumber;
  final String customerServiceNumber;

  @override
  Widget build(BuildContext context) => HHCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HHSectionLabel('PAYMENT TERMS'),
        const SizedBox(height: HHSpacing.space3),
        _row(
          'Rent',
          rentAmountCents == null
              ? 'Not set by the Hotel yet'
              : '${formatMoneyCents(rentAmountCents)} / $rentDurationHours hours',
        ),
        _row(
          'Advance required',
          advancePaymentPercent == null
              ? '—'
              : '${advancePaymentPercent!.toStringAsFixed(0)}%',
        ),
        _row('Required advance amount', formatMoneyCents(requiredAdvanceCents)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: HHSpacing.space3),
          child: Divider(height: 1),
        ),
        _row(
          'Send payment to',
          paymentReceivingNumber.isEmpty
              ? 'Not set by the Hotel yet'
              : paymentReceivingNumber,
        ),
        _row('Hotel contact', customerServiceNumber.isEmpty ? '—' : customerServiceNumber),
      ],
    ),
  );

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

/// Prompts the Customer for the amount they actually sent, then reports it
/// through the existing `POST /bookings/:id/payment-report` endpoint — this
/// only ever reports; it never sets payment status to Paid (only a Hotel
/// Manager's own verification does that). Returns `true` if a report was
/// submitted.
Future<bool> promptReportPayment(
  BuildContext context, {
  required Booking booking,
  required BookingRepository repository,
}) async {
  final controller = TextEditingController(
    text: (booking.requiredAdvanceCents / 100).toStringAsFixed(2),
  );
  final amountCents = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Report Payment Sent'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send the advance to '
            '${booking.hall?.paymentReceivingNumber.isNotEmpty == true ? booking.hall!.paymentReceivingNumber : "the Hotel's payment number"}, '
            'then enter the amount you actually sent.',
          ),
          const SizedBox(height: HHSpacing.space4),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount sent (USD)'),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(controller.text.trim());
            if (value == null || value <= 0) return;
            Navigator.pop(context, (value * 100).round());
          },
          child: const Text('Report'),
        ),
      ],
    ),
  );
  // Not disposed here: showDialog returns as soon as Navigator.pop fires,
  // before the dialog's exit animation finishes tearing down the TextField
  // that still holds this controller — disposing synchronously at this
  // point races that teardown and can crash with a framework assertion
  // ('_dependents.isEmpty' in framework.dart). A single short-lived,
  // dialog-scoped controller left for GC is the safe tradeoff.
  if (amountCents == null) return false;

  try {
    await repository.reportPayment(bookingId: booking.id, amountCents: amountCents);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment reported for Hotel verification.')),
      );
    }
    return true;
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
  }
}

/// Maps a Booking/payment status string to a badge tone — purely visual,
/// no business meaning invented beyond what the backend's own status
/// already means.
HHBadgeTone bookingStatusTone(String status) {
  switch (status) {
    case 'CONFIRMED':
    case 'COMPLETED':
    case 'PAID':
      return HHBadgeTone.success;
    case 'PENDING':
    case 'CUSTOMER_REPORTED':
      return HHBadgeTone.warning;
    case 'REJECTED':
    case 'CANCELLED':
    case 'NO_SHOW':
    case 'EXPIRED':
      return HHBadgeTone.danger;
    default:
      return HHBadgeTone.neutral;
  }
}
