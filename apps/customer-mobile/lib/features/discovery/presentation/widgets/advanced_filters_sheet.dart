import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../application/all_halls_controller.dart';

/// The Discover screen's filter icon (next to the search field) — narrows
/// "All Halls" by minimum guest capacity and/or price-per-day range, the
/// two Hall attributes the platform-wide browse endpoint
/// (`GET /halls`) already supports filtering by
/// (`hall.controller.js#browseHalls`). Returns `null` if dismissed without
/// applying; returns [AdvancedHallFilters.none] if "Reset" is tapped.
Future<AdvancedHallFilters?> showAdvancedFiltersSheet(
  BuildContext context, {
  required AdvancedHallFilters initial,
}) {
  final minGuestsController = TextEditingController(
    text: initial.minCapacity?.toString() ?? '',
  );
  final minPriceController = TextEditingController(
    text: initial.minPriceCents != null ? (initial.minPriceCents! / 100).toStringAsFixed(0) : '',
  );
  final maxPriceController = TextEditingController(
    text: initial.maxPriceCents != null ? (initial.maxPriceCents! / 100).toStringAsFixed(0) : '',
  );
  // Hoisted above `StatefulBuilder`'s own `builder` — that callback re-runs
  // in full on every `setState`, so a `String? error` declared inside it
  // would be reinitialized to null on the very next rebuild, right after
  // being set.
  String? error;

  return showModalBottomSheet<AdvancedHallFilters>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        int? parseNonNegativeInt(String text) {
          final trimmed = text.trim();
          if (trimmed.isEmpty) return null;
          return int.tryParse(trimmed);
        }

        int? parsePriceCents(String text) {
          final trimmed = text.trim();
          if (trimmed.isEmpty) return null;
          final value = double.tryParse(trimmed);
          if (value == null) return null;
          return (value * 100).round();
        }

        void apply() {
          final minCapacity = parseNonNegativeInt(minGuestsController.text);
          final minPriceCents = parsePriceCents(minPriceController.text);
          final maxPriceCents = parsePriceCents(maxPriceController.text);
          if (minGuestsController.text.trim().isNotEmpty && minCapacity == null) {
            setState(() => error = 'Minimum guests must be a whole number.');
            return;
          }
          if ((minPriceController.text.trim().isNotEmpty && minPriceCents == null) ||
              (maxPriceController.text.trim().isNotEmpty && maxPriceCents == null)) {
            setState(() => error = 'Price must be a valid amount.');
            return;
          }
          if (minPriceCents != null && maxPriceCents != null && minPriceCents > maxPriceCents) {
            setState(() => error = 'Max price must be at least the min price.');
            return;
          }
          Navigator.pop(
            context,
            AdvancedHallFilters(minCapacity: minCapacity, minPriceCents: minPriceCents, maxPriceCents: maxPriceCents),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            left: HHSpacing.space6,
            right: HHSpacing.space6,
            top: HHSpacing.space6,
            bottom: MediaQuery.of(context).viewInsets.bottom + HHSpacing.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Filters',
                style: TextStyle(fontSize: HHTypeScale.textLg, fontWeight: HHTypeScale.weightSemibold),
              ),
              const SizedBox(height: HHSpacing.space5),
              const HHSectionLabel('MINIMUM GUESTS'),
              const SizedBox(height: HHSpacing.space2),
              TextField(
                controller: minGuestsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 200'),
              ),
              const SizedBox(height: HHSpacing.space5),
              const HHSectionLabel('PRICE PER DAY (USD)'),
              const SizedBox(height: HHSpacing.space2),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Min'),
                    ),
                  ),
                  const SizedBox(width: HHSpacing.space3),
                  Expanded(
                    child: TextField(
                      controller: maxPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Max'),
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: HHSpacing.space3),
                Text(error!, style: TextStyle(color: context.hh.danger700, fontSize: HHTypeScale.textSm)),
              ],
              const SizedBox(height: HHSpacing.space6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, AdvancedHallFilters.none),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: HHSpacing.space3),
                  Expanded(
                    child: HHPrimaryButton(label: 'Apply Filters', onPressed: apply),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
