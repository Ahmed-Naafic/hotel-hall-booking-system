import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../../data/booking_models.dart';
import '../../data/booking_repository.dart';

/// BDR-024 — cancelling a Confirmed booking requires a reason (the Hotel
/// already committed the Hall for it); a still-Pending booking does not, so
/// this prompt is only ever shown for a Confirmed one
/// (`booking_detail_screen.dart#_cancel` branches on status). The backend
/// is the sole authority for whether a reason is actually required — this
/// only collects it and disables submit until non-empty, matching
/// `promptSubmitReview`'s own disabled-until-valid pattern.
Future<Booking?> promptCancelConfirmedBooking(
  BuildContext context, {
  required Booking booking,
  required BookingRepository repository,
}) async {
  final reasonController = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Cancel booking'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason for cancelling'),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: reasonController.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, reasonController.text),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    ),
  );
  // Not disposed here — same dialog-teardown-race reason
  // `promptSubmitReview`'s own TextEditingController already documents.
  if (reason == null) return null;

  try {
    final updated = await repository.cancel(booking.id, reason: reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
    }
    return updated;
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
    return null;
  }
}
