import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../../reviews/presentation/widgets/star_rating.dart';
import '../../data/booking_models.dart';
import '../../data/booking_repository.dart';

/// Ratings & Reviews V1 (approved business decisions) — the simple flow:
/// choose 1–5 stars, optionally write text, submit. The backend is the sole
/// authority for eligibility; this only surfaces whatever it decides
/// (success, or its error message on failure — e.g. a race where the
/// Booking was reviewed from another device in the meantime).
Future<Booking?> promptSubmitReview(
  BuildContext context, {
  required Booking booking,
  required BookingRepository repository,
}) async {
  final textController = TextEditingController();
  final result = await showDialog<({int rating, String text})>(
    context: context,
    builder: (context) {
      var rating = 0;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StarRatingInput(
                rating: rating,
                onChanged: (value) => setState(() => rating = value),
              ),
              const SizedBox(height: HHSpacing.space4),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comments (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: rating < 1
                  ? null
                  : () => Navigator.pop(context, (rating: rating, text: textController.text)),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
    },
  );
  // Not disposed here — same dialog-teardown-race reason as
  // promptReportPayment's own TextEditingController.
  if (result == null) return null;

  try {
    final updated = await repository.submitReview(
      bookingId: booking.id,
      rating: result.rating,
      text: result.text,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted. Thank you!')),
      );
    }
    return updated;
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    return null;
  }
}
