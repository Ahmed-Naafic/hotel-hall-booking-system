import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../application/availability_controller.dart';
import '../../data/availability_models.dart';
import '../../data/availability_repository.dart';
import '../widgets/availability_block_tile.dart';
import 'block_form_screen.dart';

/// Manager → My Hotel → Halls → Hall Details → View Availability. Own-Hotel
/// scoped day-view over one Hall's manual availability blocks (Approved
/// Implementation Plan). Plain `Navigator.push`/`MaterialPageRoute`
/// navigation, identical to how `HallFormScreen` is reached from
/// `HallListScreen` — no bottom-nav or Dashboard change.
class HallAvailabilityScreen extends StatelessWidget {
  const HallAvailabilityScreen({super.key, required this.hotelId, required this.hallId});

  final String hotelId;
  final String hallId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AvailabilityController>(
      create: (context) => AvailabilityController(
        repository: AvailabilityRepository(context.read<ApiClient>()),
        hotelId: hotelId,
        hallId: hallId,
      )..load(),
      child: _HallAvailabilityView(hotelId: hotelId, hallId: hallId),
    );
  }
}

class _HallAvailabilityView extends StatelessWidget {
  const _HallAvailabilityView({required this.hotelId, required this.hallId});

  final String hotelId;
  final String hallId;

  Future<void> _openCreate(BuildContext context) async {
    final controller = context.read<AvailabilityController>();
    final created = await Navigator.of(context).push<AvailabilityBlock>(
      MaterialPageRoute(
        builder: (_) => BlockFormScreen(
          hotelId: hotelId,
          hallId: hallId,
          initialDate: controller.selectedDate,
        ),
      ),
    );
    if (created != null && context.mounted) {
      await controller.upsert(created);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability block created.')));
      }
    }
  }

  Future<void> _openEdit(BuildContext context, AvailabilityBlock block) async {
    final controller = context.read<AvailabilityController>();
    final updated = await Navigator.of(context).push<AvailabilityBlock>(
      MaterialPageRoute(
        builder: (_) => BlockFormScreen(
          hotelId: hotelId,
          hallId: hallId,
          initialDate: controller.selectedDate,
          existingBlock: block,
        ),
      ),
    );
    if (updated != null && context.mounted) {
      await controller.upsert(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability block updated.')));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, AvailabilityBlock block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete availability block?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final controller = context.read<AvailabilityController>();
    try {
      await controller.deleteBlock(block.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability block deleted.')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final controller = context.read<AvailabilityController>();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) controller.changeDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvailabilityController>();

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Availability')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Block'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _DateSelector(date: controller.selectedDate, onTap: () => _pickDate(context)),
            Expanded(child: _body(context, controller)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AvailabilityController controller) {
    switch (controller.status) {
      case AvailabilityStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case AvailabilityStatus.error:
        return HHEmptyState(
          icon: Icons.error_outline,
          message: controller.errorMessage ?? 'Something went wrong.',
          iconColor: HHColors.danger700,
          actionLabel: 'Retry',
          onAction: controller.load,
        );

      case AvailabilityStatus.empty:
        return HHEmptyState(
          icon: Icons.event_available_outlined,
          title: 'No blocks',
          message: 'This Hall has no availability blocks on this date.',
        );

      case AvailabilityStatus.ready:
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(HHSpacing.space7),
            children: [
              for (final block in controller.blocks)
                AvailabilityBlockTile(
                  block: block,
                  onTap: () => _openEdit(context, block),
                  onDelete: () => _confirmDelete(context, block),
                ),
            ],
          ),
        );
    }
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(HHSpacing.space7, HHSpacing.space5, HHSpacing.space7, 0),
      child: HHCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.event_outlined, color: HHColors.actionPrimary),
            const SizedBox(width: HHSpacing.space3),
            Expanded(child: Text(label, style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textMd))),
            Icon(Icons.expand_more, color: HHColors.textSubtle),
          ],
        ),
      ),
    );
  }
}
