import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// Read-only star display for an existing rating (1–5, whole stars only —
/// V1 never shows half-stars, matching the whole-integer rating scale
/// approved for Ratings & Reviews V1).
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({super.key, required this.rating, this.size = 16});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        // The token, not a fixed `gold600`: that is the light theme's gold
        // and it sits too dark to read on a navy page.
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: context.hh.actionGold,
        ),
      ),
    );
  }
}

/// Interactive 1–5 star picker for submitting a review.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({super.key, required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          onPressed: () => onChanged(starValue),
          icon: Icon(
            starValue <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: context.hh.actionGold,
          ),
          iconSize: 32,
        );
      }),
    );
  }
}
