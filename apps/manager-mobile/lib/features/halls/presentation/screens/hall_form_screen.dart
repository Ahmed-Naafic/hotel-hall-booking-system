import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../application/hall_form_controller.dart';
import '../../data/hall_models.dart';
import '../../data/hall_repository.dart';
import '../widgets/hall_profile_data_editor.dart';

/// Manager → My Hotel → Halls → Create/Edit Hall (`POST`/`PATCH
/// /hotels/:hotelId/halls[/:id]`, HL1/HL2/HL3). Structured per `BDR-016`
/// (Required Hall Information, `Approved` 2026-08-26): required standard
/// fields (Hall Name, Capacity), optional standard fields (Description,
/// Location/Area), optional custom fields that can never substitute for a
/// required one. No fields beyond this approved model are collected —
/// `BR-HALL-02` means Hall preparation is allowed regardless of the owning
/// Hotel's own approval state, so this screen has no Hotel-status
/// precondition either.
///
/// **Hall Photos is a non-functional placeholder.** `BDR-016` approves it
/// as an optional business field, but — unlike Hotel Logo/Photos
/// (`ADR-0006`, Supabase) — no storage/upload mechanism has been designed
/// or approved for Hall media yet. This screen never invents one; the
/// control is shown per the approved layout, disabled, with the reason
/// stated plainly.
class HallFormScreen extends StatefulWidget {
  const HallFormScreen({super.key, required this.hotelId, this.existingHall});

  final String hotelId;
  final Hall? existingHall;

  bool get isEditing => existingHall != null;

  @override
  State<HallFormScreen> createState() => _HallFormScreenState();
}

class _HallFormScreenState extends State<HallFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customFieldsKey = GlobalKey<HallProfileDataEditorState>();
  late final HallFormController _controller;

  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final Map<String, dynamic> _existingCustomFields;

  @override
  void initState() {
    super.initState();
    _controller = HallFormController(
      repository: HallRepository(context.read<ApiClient>()),
      hotelId: widget.hotelId,
      existingHall: widget.existingHall,
    );

    final existing = widget.existingHall?.profileData ?? const <String, dynamic>{};
    _nameController = TextEditingController(text: existing['name']?.toString() ?? '');
    _capacityController = TextEditingController(text: existing['capacity']?.toString() ?? '');
    _descriptionController = TextEditingController(text: existing['description']?.toString() ?? '');
    _locationController = TextEditingController(text: existing['location']?.toString() ?? '');
    _existingCustomFields = Map.fromEntries(
      existing.entries.where((entry) => !HallFormController.standardFieldKeys.contains(entry.key)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final standardFields = <String, dynamic>{
      'name': _nameController.text.trim(),
      'capacity': int.parse(_capacityController.text.trim()),
      if (description.isNotEmpty) 'description': description,
      if (location.isNotEmpty) 'location': location,
    };
    final customFields = _customFieldsKey.currentState!.collect();

    final hall = await _controller.submit(standardFields: standardFields, customFields: customFields);
    if (hall != null && mounted) {
      // The caller (list or details screen) shows the success feedback on
      // its own, still-alive Scaffold — a SnackBar shown here would be
      // attached to this screen's Scaffold, which is about to be popped
      // away before it could ever render.
      Navigator.of(context).pop(hall);
    } else {
      setState(() {});
    }
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.only(bottom: HHSpacing.space4),
        child: Text(
          label,
          style: TextStyle(
            color: HHColors.textMuted,
            fontWeight: HHTypeScale.weightSemibold,
            fontSize: HHTypeScale.textXs,
            letterSpacing: 0.8,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HallFormController>.value(
      value: _controller,
      child: Consumer<HallFormController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: HHColors.surfacePage,
            appBar: AppBar(title: Text(widget.isEditing ? 'Edit Hall' : 'Create Hall')),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(HHSpacing.space7),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (controller.errorMessage != null) ...[
                        HHErrorBanner(message: controller.errorMessage!),
                        const SizedBox(height: HHSpacing.space5),
                      ],
                      _sectionHeader('HALL INFORMATION'),
                      HHTextField(
                        label: 'Hall Name',
                        controller: _nameController,
                        enabled: !controller.isBusy,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Hall Name is required.' : null,
                      ),
                      const SizedBox(height: HHSpacing.space5),
                      HHTextField(
                        label: 'Capacity',
                        controller: _capacityController,
                        enabled: !controller.isBusy,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final trimmed = v?.trim() ?? '';
                          if (trimmed.isEmpty) return 'Capacity is required.';
                          final parsed = int.tryParse(trimmed);
                          if (parsed == null || parsed <= 0) return 'Capacity must be a valid positive number.';
                          return null;
                        },
                      ),
                      const SizedBox(height: HHSpacing.space5),
                      HHTextField(
                        label: 'Description (optional)',
                        controller: _descriptionController,
                        enabled: !controller.isBusy,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: HHSpacing.space5),
                      HHTextField(
                        label: 'Location / Area (optional)',
                        controller: _locationController,
                        enabled: !controller.isBusy,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: HHSpacing.space8),
                      _sectionHeader('HALL PHOTOS'),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                            label: const Text('Add Photos'),
                          ),
                          const SizedBox(height: HHSpacing.space1),
                          Text(
                            'Not available yet — upload is coming soon.',
                            style: TextStyle(color: HHColors.textSubtle, fontSize: HHTypeScale.textXs),
                          ),
                        ],
                      ),
                      const SizedBox(height: HHSpacing.space8),
                      _sectionHeader('ADDITIONAL INFORMATION'),
                      Text(
                        'Add any other details about this Hall. These cannot replace the required '
                        'information above.',
                        style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textSm),
                      ),
                      const SizedBox(height: HHSpacing.space4),
                      HallProfileDataEditor(
                        key: _customFieldsKey,
                        initialData: _existingCustomFields,
                        enabled: !controller.isBusy,
                      ),
                      const SizedBox(height: HHSpacing.space7),
                      HHPrimaryButton(
                        label: widget.isEditing ? 'Save changes' : 'Create Hall',
                        isLoading: controller.isBusy,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
