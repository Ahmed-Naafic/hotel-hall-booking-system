import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../data/availability_models.dart';
import '../../data/availability_repository.dart';

/// Mogadishu is a fixed UTC+3 offset, no DST (Approved Technical Design
/// §4) — every date/time shown or picked here is Mogadishu wall-clock time,
/// computed from a fixed offset, never the device's own timezone.
DateTime _mogadishuNow() => DateTime.now().toUtc().add(const Duration(hours: 3));
DateTime _mogadishuLocal(DateTime utc) => utc.toUtc().add(const Duration(hours: 3));

String _formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Manager → My Hotel → Halls → Hall Details → View Availability → Add/Edit
/// Block. One screen for both create and edit (`existingBlock` optional),
/// matching `HallFormScreen`'s own precedent. Owns its own
/// `AvailabilityRepository` and performs the actual create/update call
/// itself, popping with the resulting block — the calling screen only
/// updates its local list (`AvailabilityController.upsert`), never a second
/// network call, matching `HallFormScreen`/`HallListScreen`'s existing
/// split of responsibility exactly.
class BlockFormScreen extends StatefulWidget {
  const BlockFormScreen({
    super.key,
    required this.hotelId,
    required this.hallId,
    required this.initialDate,
    this.existingBlock,
  });

  final String hotelId;
  final String hallId;
  final DateTime initialDate;
  final AvailabilityBlock? existingBlock;

  bool get isEditing => existingBlock != null;

  @override
  State<BlockFormScreen> createState() => _BlockFormScreenState();
}

class _BlockFormScreenState extends State<BlockFormScreen> {
  late final AvailabilityRepository _repository;
  late final TextEditingController _reasonController;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = AvailabilityRepository(context.read<ApiClient>());

    final existing = widget.existingBlock;
    if (existing != null) {
      final startLocal = _mogadishuLocal(existing.startsAt);
      final endLocal = _mogadishuLocal(existing.endsAt);
      _date = DateTime(startLocal.year, startLocal.month, startLocal.day);
      _startTime = TimeOfDay(hour: startLocal.hour, minute: startLocal.minute);
      _endTime = TimeOfDay(hour: endLocal.hour, minute: endLocal.minute);
      _reasonController = TextEditingController(text: existing.reason ?? '');
    } else {
      final initial = widget.initialDate;
      _date = DateTime(initial.year, initial.month, initial.day);
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _reasonController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = _mogadishuNow();
    final firstDate = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(firstDate) ? firstDate : _date,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final dateKey =
        '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final reason = _reasonController.text.trim();

    try {
      final AvailabilityBlock block;
      if (widget.isEditing) {
        block = await _repository.updateBlock(
          hotelId: widget.hotelId,
          hallId: widget.hallId,
          blockId: widget.existingBlock!.id,
          date: dateKey,
          startTime: _formatTimeOfDay(_startTime),
          endTime: _formatTimeOfDay(_endTime),
          reason: reason.isEmpty ? null : reason,
        );
      } else {
        block = await _repository.createBlock(
          hotelId: widget.hotelId,
          hallId: widget.hallId,
          date: dateKey,
          startTime: _formatTimeOfDay(_startTime),
          endTime: _formatTimeOfDay(_endTime),
          reason: reason.isEmpty ? null : reason,
        );
      }
      if (mounted) Navigator.of(context).pop(block);
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    } on NetworkException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Block' : 'Add Block')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                HHErrorBanner(message: _errorMessage!),
                const SizedBox(height: HHSpacing.space5),
              ],
              const HHSectionLabel('BLOCK PERIOD'),
              HHCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PickerRow(
                      icon: Icons.event_outlined,
                      label: 'Date',
                      value:
                          '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                      onTap: _isSaving ? null : _pickDate,
                    ),
                    const SizedBox(height: HHSpacing.space4),
                    _PickerRow(
                      icon: Icons.schedule_outlined,
                      label: 'Start time',
                      value: _formatTimeOfDay(_startTime),
                      onTap: _isSaving ? null : _pickStartTime,
                    ),
                    const SizedBox(height: HHSpacing.space4),
                    _PickerRow(
                      icon: Icons.schedule_outlined,
                      label: 'End time',
                      value: _formatTimeOfDay(_endTime),
                      onTap: _isSaving ? null : _pickEndTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HHSpacing.space7),
              const HHSectionLabel('REASON (OPTIONAL)'),
              HHCard(
                child: HHTextField(
                  label: 'e.g. Maintenance, Private event, Cleaning',
                  controller: _reasonController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(height: HHSpacing.space7),
              HHPrimaryButton(
                label: widget.isEditing ? 'Save changes' : 'Create Block',
                isLoading: _isSaving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HHRadii.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HHSpacing.space2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: HHColors.actionPrimary),
            const SizedBox(width: HHSpacing.space3),
            Expanded(
              child: Text(label, style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textSm)),
            ),
            Text(value, style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textMd)),
          ],
        ),
      ),
    );
  }
}
