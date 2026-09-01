import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../application/hall_form_controller.dart';
import '../../application/hall_media_controller.dart';
import '../../../hotel/application/image_picker_service.dart';
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
/// Hall photos use the approved shared-media Hall endpoints. A Hall must be
/// created before its media path can exist, so create mode explains that
/// photos become available from Edit Hall; edit mode provides upload/delete.
class HallFormScreen extends StatefulWidget {
  const HallFormScreen({
    super.key,
    required this.hotelId,
    this.existingHall,
    this.pickImage = pickImageFromGallery,
  });

  final String hotelId;
  final Hall? existingHall;
  final ImagePickerFn pickImage;

  bool get isEditing => existingHall != null;

  @override
  State<HallFormScreen> createState() => _HallFormScreenState();
}

class _HallFormScreenState extends State<HallFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customFieldsKey = GlobalKey<HallProfileDataEditorState>();
  late final HallFormController _controller;
  HallMediaController? _mediaController;

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
    if (widget.existingHall != null) {
      _mediaController = HallMediaController(
        repository: HallRepository(context.read<ApiClient>()),
        hotelId: widget.hotelId,
        hallId: widget.existingHall!.id,
        pickImage: widget.pickImage,
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _mediaController!.load(),
      );
    }

    final existing =
        widget.existingHall?.profileData ?? const <String, dynamic>{};
    _nameController = TextEditingController(
      text: existing['name']?.toString() ?? '',
    );
    _capacityController = TextEditingController(
      text: existing['capacity']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing['description']?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: existing['location']?.toString() ?? '',
    );
    _existingCustomFields = Map.fromEntries(
      existing.entries.where(
        (entry) => !HallFormController.standardFieldKeys.contains(entry.key),
      ),
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

    final hall = await _controller.submit(
      standardFields: standardFields,
      customFields: customFields,
    );
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HallFormController>.value(
      value: _controller,
      child: Consumer<HallFormController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: HHColors.surfacePage,
            appBar: AppBar(
              title: Text(widget.isEditing ? 'Edit Hall' : 'Create Hall'),
            ),
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
                      const HHSectionLabel('HALL INFORMATION'),
                      HHCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            HHTextField(
                              label: 'Hall Name',
                              controller: _nameController,
                              enabled: !controller.isBusy,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Hall Name is required.'
                                  : null,
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
                                if (trimmed.isEmpty) {
                                  return 'Capacity is required.';
                                }
                                final parsed = int.tryParse(trimmed);
                                if (parsed == null || parsed <= 0) {
                                  return 'Capacity must be a valid positive number.';
                                }
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
                          ],
                        ),
                      ),
                      const SizedBox(height: HHSpacing.space8),
                      const HHSectionLabel('HALL PHOTOS'),
                      HHCard(
                        child: _mediaController == null
                            ? Row(
                                children: [
                                  Icon(Icons.photo_library_outlined, color: HHColors.textMuted),
                                  const SizedBox(width: HHSpacing.space3),
                                  const Expanded(
                                    child: Text(
                                      'Create the Hall first, then add photos from Edit Hall.',
                                    ),
                                  ),
                                ],
                              )
                            : ListenableBuilder(
                                listenable: _mediaController!,
                                builder: (context, _) =>
                                    _HallPhotosSection(controller: _mediaController!),
                              ),
                      ),
                      const SizedBox(height: HHSpacing.space8),
                      const HHSectionLabel('ADDITIONAL INFORMATION'),
                      Text(
                        'Add any other details about this Hall. These cannot replace the required '
                        'information above.',
                        style: TextStyle(
                          color: HHColors.textMuted,
                          fontSize: HHTypeScale.textSm,
                        ),
                      ),
                      const SizedBox(height: HHSpacing.space4),
                      HHCard(
                        child: HallProfileDataEditor(
                          key: _customFieldsKey,
                          initialData: _existingCustomFields,
                          enabled: !controller.isBusy,
                        ),
                      ),
                      const SizedBox(height: HHSpacing.space7),
                      HHPrimaryButton(
                        label: widget.isEditing
                            ? 'Save changes'
                            : 'Create Hall',
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

class _HallPhotosSection extends StatelessWidget {
  const _HallPhotosSection({required this.controller});
  final HallMediaController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (controller.errorMessage != null) ...[
        HHErrorBanner(message: controller.errorMessage!),
        const SizedBox(height: HHSpacing.space3),
      ],
      if (controller.photos.isNotEmpty)
        Wrap(
          spacing: HHSpacing.space3,
          runSpacing: HHSpacing.space3,
          children: controller.photos
              .map(
                (photo) => Stack(
                  children: [
                    HHNetworkImage(
                      url: photo.url,
                      width: 96,
                      height: 80,
                      fallbackIcon: Icons.broken_image_outlined,
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton.filled(
                        tooltip: 'Delete photo',
                        visualDensity: VisualDensity.compact,
                        onPressed: controller.deletingId == null
                            ? () => controller.delete(photo.id)
                            : null,
                        icon: controller.deletingId == photo.id
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      if (controller.photos.isNotEmpty)
        const SizedBox(height: HHSpacing.space3),
      OutlinedButton.icon(
        onPressed: controller.isBusy ? null : controller.upload,
        icon: controller.isBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add Photos'),
      ),
    ],
  );
}
