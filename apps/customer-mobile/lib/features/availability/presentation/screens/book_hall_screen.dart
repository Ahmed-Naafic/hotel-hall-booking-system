import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../discovery/data/discovery_models.dart';
import '../../application/availability_controller.dart';
import '../../data/availability_models.dart';
import '../../data/availability_repository.dart';

/// Mogadishu is a fixed UTC+3 offset, no DST (Approved Technical Design
/// §4) — every date/time here is Mogadishu wall-clock time, computed from
/// a fixed offset, never the device's own timezone.
DateTime _mogadishuNow() => DateTime.now().toUtc().add(const Duration(hours: 3));
DateTime _mogadishuLocal(DateTime utc) => utc.toUtc().add(const Duration(hours: 3));

/// A plain Mogadishu calendar date (e.g. `controller.selectedDate` — no
/// timezone meaning of its own, only its y/m/d fields matter) combined with
/// a picked wall-clock `TimeOfDay`, converted to the true UTC instant via
/// the fixed +03:00 offset. Deliberately never uses the device-local
/// `DateTime(y, m, d, h, m)` constructor for this — that would silently
/// reinterpret the picked time in the device's own timezone instead of
/// Mogadishu's, exactly the bug class `AvailabilityController.upsert`
/// (Manager Mobile) was fixed for.
DateTime _mogadishuInstant(DateTime date, TimeOfDay time) =>
    DateTime.utc(date.year, date.month, date.day, time.hour, time.minute).subtract(const Duration(hours: 3));

String _formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Hall Details → Book Hall → date/time selection (Approved Implementation
/// Plan). Reached only once `_book()` (`discover_screen.dart`) has already
/// confirmed the Customer is authenticated and verified — this screen
/// assumes that precondition, it never re-checks auth itself. Ends at the
/// authoritative backend check (decision 1) — Booking Management does not
/// exist yet, so a successful check still ends at the same placeholder
/// acknowledgement Hall Details showed before this screen existed.
class BookHallScreen extends StatelessWidget {
  const BookHallScreen({super.key, required this.hall});

  final HallSummary hall;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AvailabilityController>(
      create: (context) => AvailabilityController(
        repository: AvailabilityRepository(context.read<ApiClient>()),
        hallId: hall.id,
      )..load(),
      child: const _BookHallView(),
    );
  }
}

class _BookHallView extends StatefulWidget {
  const _BookHallView();

  @override
  State<_BookHallView> createState() => _BookHallViewState();
}

class _BookHallViewState extends State<_BookHallView> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  bool _periodOverlapsABusyPeriod(List<BusyPeriod> busyPeriods, DateTime date) {
    final startsAt = _mogadishuInstant(date, _startTime);
    var endsAt = _mogadishuInstant(date, _endTime);
    if (!endsAt.isAfter(startsAt)) endsAt = endsAt.add(const Duration(days: 1));
    return busyPeriods.any((p) => startsAt.isBefore(p.end) && p.start.isBefore(endsAt));
  }

  Future<void> _pickDate(BuildContext context) async {
    final controller = context.read<AvailabilityController>();
    final today = _mogadishuNow();
    final firstDate = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.isBefore(firstDate) ? firstDate : controller.selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
    );
    if (picked != null) controller.changeDate(picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _submit(BuildContext context) async {
    final controller = context.read<AvailabilityController>();
    final available = await controller.submitCheck(
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
    );
    if (!context.mounted) return;

    if (available == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.checkErrorMessage ?? 'Something went wrong.')),
      );
      return;
    }
    if (available == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This time is no longer available — please choose another.')),
      );
      return;
    }
    // Booking Management does not exist yet (Approved Technical Design
    // §2/§18, decision 1) — a successful availability check still ends at
    // the same placeholder acknowledgement Hall Details showed before this
    // screen existed, now gated behind a real backend re-validation.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking will be available in the Booking module.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvailabilityController>();

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Book Hall')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HHCard(
                onTap: () => _pickDate(context),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, color: HHColors.actionPrimary),
                    const SizedBox(width: HHSpacing.space3),
                    Expanded(child: Text(formatDateKey(controller.selectedDate), style: TextStyle(fontWeight: HHTypeScale.weightSemibold))),
                    Icon(Icons.expand_more, color: HHColors.textSubtle),
                  ],
                ),
              ),
              const SizedBox(height: HHSpacing.space5),
              const HHSectionLabel('AVAILABILITY THIS DAY'),
              _availabilityBody(controller),
              const SizedBox(height: HHSpacing.space7),
              const HHSectionLabel('SELECT A TIME'),
              HHCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TimeRow(label: 'Start time', value: _formatTimeOfDay(_startTime), onTap: _pickStartTime),
                    const SizedBox(height: HHSpacing.space4),
                    _TimeRow(label: 'End time', value: _formatTimeOfDay(_endTime), onTap: _pickEndTime),
                    if (controller.status == AvailabilityStatus.ready &&
                        _periodOverlapsABusyPeriod(controller.busyPeriods, controller.selectedDate)) ...[
                      const SizedBox(height: HHSpacing.space4),
                      Text(
                        'This time overlaps a busy period shown above.',
                        style: TextStyle(color: HHColors.danger700, fontSize: HHTypeScale.textSm),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: HHSpacing.space7),
              HHPrimaryButton(
                label: 'Submit',
                isLoading: controller.isChecking,
                onPressed: () => _submit(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _availabilityBody(AvailabilityController controller) {
    switch (controller.status) {
      case AvailabilityStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: HHSpacing.space5),
          child: Center(child: CircularProgressIndicator()),
        );
      case AvailabilityStatus.error:
        return HHEmptyState(
          icon: Icons.error_outline,
          message: controller.errorMessage ?? 'Something went wrong.',
          iconColor: HHColors.danger700,
          actionLabel: 'Retry',
          onAction: controller.load,
        );
      case AvailabilityStatus.ready:
        if (controller.busyPeriods.isEmpty) {
          return HHCard(
            child: Text('No busy periods on this date.', style: TextStyle(color: HHColors.textMuted)),
          );
        }
        return HHCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final period in controller.busyPeriods)
                Padding(
                  padding: const EdgeInsets.only(bottom: HHSpacing.space2),
                  child: Text(
                    '${_mogadishuLocal(period.start).hour.toString().padLeft(2, '0')}:${_mogadishuLocal(period.start).minute.toString().padLeft(2, '0')}'
                    ' – '
                    '${_mogadishuLocal(period.end).hour.toString().padLeft(2, '0')}:${_mogadishuLocal(period.end).minute.toString().padLeft(2, '0')}'
                    ' Busy',
                    style: TextStyle(color: HHColors.textMuted),
                  ),
                ),
            ],
          ),
        );
    }
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HHRadii.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HHSpacing.space2),
        child: Row(
          children: [
            Icon(Icons.schedule_outlined, size: 18, color: HHColors.actionPrimary),
            const SizedBox(width: HHSpacing.space3),
            Expanded(child: Text(label, style: TextStyle(color: HHColors.textMuted))),
            Text(value, style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textMd)),
          ],
        ),
      ),
    );
  }
}
