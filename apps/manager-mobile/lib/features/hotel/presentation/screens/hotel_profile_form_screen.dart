import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../application/hotel_context_controller.dart';
import '../../application/hotel_media_controller.dart';
import '../../application/hotel_profile_form_controller.dart';
import '../../application/image_picker_service.dart';
import '../../data/hotel_models.dart';
import '../../data/hotel_repository.dart';
import '../widgets/hotel_profile_data_editor.dart';
import 'hotel_location_picker_screen.dart';

/// Manager → My Hotel → Complete Hotel Profile (HM2, `BR-HOTEL-02`) —
/// `PATCH /hotels/:id` while the Hotel is `REGISTERED`. Structured per
/// `BDR-015` (Required Hotel Business-Profile Content, `Approved`
/// 2026-08-26): required standard fields, optional standard fields, and
/// optional custom fields that can never substitute for a required one.
///
/// Hotel Logo/Photos (`ADR-0006`, Technical Design §8a) upload immediately
/// on selection — independent of "Save & Continue," which only submits the
/// standard/custom text fields — via `HotelMediaController`, which only
/// ever calls this app's own `HotelRepository` (`POST`/`DELETE`/`GET
/// /hotels/:hotelId/media...`). This screen never talks to Supabase
/// directly and never holds a Supabase credential of any kind — the
/// mandated architecture (Manager Mobile → Hotel Management Backend →
/// Supabase Storage / Neon metadata) is enforced simply by this screen
/// having no code path that could do otherwise.
///
/// Reads the Hotel to complete from the shared `HotelContextController` —
/// the authenticated Manager's own, already-resolved Hotel — never an id
/// passed in from the caller, so this screen has no way to target any other
/// Hotel.
class HotelProfileFormScreen extends StatefulWidget {
  const HotelProfileFormScreen({
    super.key,
    this.pickImage = pickImageFromGallery,
    this.showLocationMapTiles = true,
  });

  /// Injectable so tests never drive the real platform image picker (no
  /// platform channel in `flutter test`) — defaults to the real gallery
  /// picker for actual app use.
  final ImagePickerFn pickImage;
  final bool showLocationMapTiles;

  @override
  State<HotelProfileFormScreen> createState() => _HotelProfileFormScreenState();
}

class _HotelProfileFormScreenState extends State<HotelProfileFormScreen> {
  /// Onboarding wording (`REGISTERED`, completing the initial profile) vs.
  /// edit wording (`REJECTED`/`APPROVED_ACTIVE`, changing an already-set
  /// profile) — same form, same fields, the backend already tells us which
  /// case this is via the Hotel's own status
  /// (`hotel.controller.js#updateHotel`); this screen just reflects it
  /// rather than always claiming to be "completing" something already done.
  bool get _isOnboarding => _hotelStatus == 'REGISTERED';
  late final String? _hotelStatus;

  final _formKey = GlobalKey<FormState>();
  final _customFieldsKey = GlobalKey<HotelProfileDataEditorState>();
  late final HotelProfileFormController _controller;
  late final HotelMediaController _mediaController;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _emailController;
  late final Map<String, dynamic> _existingCustomFields;
  HotelLocationResult? _location;
  String? _legacyLocation;

  @override
  void initState() {
    super.initState();
    final hotelContext = context.read<HotelContextController>();
    _hotelStatus = hotelContext.hotel?.status;
    final repository = HotelRepository(context.read<ApiClient>());
    _controller = HotelProfileFormController(
      repository: repository,
      hotelContext: hotelContext,
    );
    _mediaController = HotelMediaController(
      repository: repository,
      hotelId: hotelContext.hotel!.id,
      pickImage: widget.pickImage,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _mediaController.load(),
    );

    final existing =
        hotelContext.hotel?.profileData ?? const <String, dynamic>{};
    _nameController = TextEditingController(
      text: existing['name']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing['description']?.toString() ?? '',
    );
    final existingLocation = existing['location'];
    if (existingLocation is Map) {
      final latitude = (existingLocation['latitude'] as num?)?.toDouble();
      final longitude = (existingLocation['longitude'] as num?)?.toDouble();
      final address = existingLocation['address']?.toString() ?? '';
      if (latitude != null && longitude != null && address.isNotEmpty) {
        _location = HotelLocationResult(
          latitude: latitude,
          longitude: longitude,
          address: address,
        );
      }
    } else if (existingLocation is String &&
        existingLocation.trim().isNotEmpty) {
      _legacyLocation = existingLocation.trim();
    }
    _contactPhoneController = TextEditingController(
      text: existing['contactPhone']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: existing['email']?.toString() ?? '',
    );
    _existingCustomFields = Map.fromEntries(
      existing.entries.where(
        (entry) =>
            !HotelProfileFormController.standardFieldKeys.contains(entry.key),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contactPhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final standardFields = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _location!.toJson(),
      'contactPhone': _contactPhoneController.text.trim(),
      if (email.isNotEmpty) 'email': email,
    };
    final customFields = _customFieldsKey.currentState!.collect();

    final ok = await _controller.submitProfile(
      standardFields: standardFields,
      customFields: customFields,
    );
    if (ok && mounted) {
      // The caller (MyHotelScreen) is still alive and already watches
      // HotelContextController, which submitProfile() just updated — pop
      // with a result flag so it can show success feedback on its own
      // Scaffold, the same pattern HallFormScreen uses.
      Navigator.of(context).pop(true);
    } else {
      setState(() {});
    }
  }

  Future<void> _openLocationPicker() async {
    final hotelId = context.read<HotelContextController>().hotel!.id;
    final repository = HotelRepository(context.read<ApiClient>());
    final result = await Navigator.of(context).push<HotelLocationResult>(
      MaterialPageRoute(
        builder: (_) => HotelLocationPickerScreen(
          initialLocation: _location,
          showMapTiles: widget.showLocationMapTiles,
          reverseGeocode: (latitude, longitude) =>
              repository.reverseGeocode(hotelId, latitude, longitude),
        ),
      ),
    );
    if (result != null && mounted) setState(() => _location = result);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HotelProfileFormController>.value(
          value: _controller,
        ),
        ChangeNotifierProvider<HotelMediaController>.value(
          value: _mediaController,
        ),
      ],
      child: Consumer2<HotelProfileFormController, HotelMediaController>(
        builder: (context, controller, mediaController, _) {
          return Scaffold(
            backgroundColor: HHColors.surfacePage,
            appBar: AppBar(title: Text(_isOnboarding ? 'Complete Hotel Profile' : 'Edit Hotel Profile')),
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
                      const HHSectionLabel('HOTEL INFORMATION'),
                      HHCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                      HHTextField(
                        label: 'Hotel Name',
                        controller: _nameController,
                        enabled: !controller.isBusy,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Hotel Name is required.'
                            : null,
                      ),
                      const SizedBox(height: HHSpacing.space5),
                      HHTextField(
                        label: 'Description',
                        controller: _descriptionController,
                        enabled: !controller.isBusy,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Description is required.'
                            : null,
                      ),
                      const SizedBox(height: HHSpacing.space5),
                      FormField<HotelLocationResult>(
                        initialValue: _location,
                        validator: (_) =>
                            _location == null ? 'Location is required.' : null,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Location *',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: HHSpacing.space3),
                            InkWell(
                              onTap: controller.isBusy
                                  ? null
                                  : () async {
                                      await _openLocationPicker();
                                      field.didChange(_location);
                                    },
                              borderRadius: BorderRadius.circular(HHRadii.card),
                              child: Container(
                                padding: const EdgeInsets.all(HHSpacing.space5),
                                decoration: BoxDecoration(
                                  color: HHColors.surfaceSunken,
                                  borderRadius: BorderRadius.circular(
                                    HHRadii.card,
                                  ),
                                  border: Border.all(
                                    color: field.hasError
                                        ? HHColors.danger700
                                        : HHColors.borderDefault,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.map_outlined,
                                      color: HHColors.actionPrimary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: HHSpacing.space4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _location == null
                                                ? 'Open map and place pin'
                                                : _location!.address,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),
                                          if (_location != null)
                                            Text(
                                              '${_location!.latitude.toStringAsFixed(6)}, ${_location!.longitude.toStringAsFixed(6)}',
                                              style: TextStyle(
                                                color: HHColors.textMuted,
                                                fontSize: HHTypeScale.textXs,
                                              ),
                                            )
                                          else if (_legacyLocation != null)
                                            Text(
                                              'Previous address: $_legacyLocation. Select its exact map location.',
                                              style: TextStyle(
                                                color: HHColors.textMuted,
                                                fontSize: HHTypeScale.textXs,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: HHSpacing.space2,
                                  left: HHSpacing.space3,
                                ),
                                child: Text(
                                  field.errorText!,
                                  style: TextStyle(
                                    color: HHColors.danger700,
                                    fontSize: HHTypeScale.textXs,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: HHSpacing.space5),
                      HHTextField(
                        label: 'Contact Phone',
                        controller: _contactPhoneController,
                        enabled: !controller.isBusy,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Contact Phone is required.'
                            : null,
                      ),
                      const SizedBox(height: HHSpacing.space5),
                      HHTextField(
                        label: 'Email (optional)',
                        controller: _emailController,
                        enabled: !controller.isBusy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                      ),
                          ],
                        ),
                      ),
                      const SizedBox(height: HHSpacing.space8),
                      const HHSectionLabel('HOTEL MEDIA'),
                      if (mediaController.errorMessage != null) ...[
                        HHErrorBanner(message: mediaController.errorMessage!),
                        const SizedBox(height: HHSpacing.space4),
                      ],
                      HHCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LogoSection(mediaController: mediaController),
                            const SizedBox(height: HHSpacing.space6),
                            _PhotosSection(mediaController: mediaController),
                          ],
                        ),
                      ),
                      const SizedBox(height: HHSpacing.space8),
                      const HHSectionLabel('ADDITIONAL INFORMATION'),
                      Text(
                        'Add any other details about your Hotel. These cannot replace the required '
                        'information above.',
                        style: TextStyle(
                          color: HHColors.textMuted,
                          fontSize: HHTypeScale.textSm,
                        ),
                      ),
                      const SizedBox(height: HHSpacing.space4),
                      HHCard(
                        child: HotelProfileDataEditor(
                          key: _customFieldsKey,
                          initialData: _existingCustomFields,
                          enabled: !controller.isBusy,
                        ),
                      ),
                      const SizedBox(height: HHSpacing.space7),
                      HHPrimaryButton(
                        label: _isOnboarding ? 'Save & Continue' : 'Save Changes',
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

class _LogoSection extends StatelessWidget {
  const _LogoSection({required this.mediaController});

  final HotelMediaController mediaController;

  @override
  Widget build(BuildContext context) {
    final logo = mediaController.logo;
    final isDeleting =
        logo != null && mediaController.deletingMediaId == logo.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotel Logo',
          style: TextStyle(
            fontWeight: HHTypeScale.weightSemibold,
            fontSize: HHTypeScale.textMd,
          ),
        ),
        const SizedBox(height: HHSpacing.space3),
        if (logo != null) ...[
          Row(
            children: [
              // A broken/unreachable URL shows a fallback icon rather than
              // crashing the screen — the same defensive posture this app
              // already takes for every other API failure.
              HHNetworkImage(url: logo.url, width: 64, height: 64),
              const SizedBox(width: HHSpacing.space4),
              IconButton(
                tooltip: 'Delete logo',
                onPressed: isDeleting || mediaController.deletingMediaId != null
                    ? null
                    : () => mediaController.deleteMedia(logo.id),
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.delete_outline, color: HHColors.danger700),
              ),
            ],
          ),
          const SizedBox(height: HHSpacing.space3),
        ],
        HHSecondaryButton(
          label: logo != null ? 'Replace Logo' : 'Upload Logo',
          isLoading: mediaController.isUploadingLogo,
          icon: Icons.image_outlined,
          onPressed: mediaController.uploadLogo,
        ),
      ],
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.mediaController});

  final HotelMediaController mediaController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotel Photos',
          style: TextStyle(
            fontWeight: HHTypeScale.weightSemibold,
            fontSize: HHTypeScale.textMd,
          ),
        ),
        const SizedBox(height: HHSpacing.space3),
        if (mediaController.photos.isNotEmpty) ...[
          Wrap(
            spacing: HHSpacing.space3,
            runSpacing: HHSpacing.space3,
            children: [
              for (final photo in mediaController.photos)
                _PhotoThumbnail(photo: photo, mediaController: mediaController),
            ],
          ),
          const SizedBox(height: HHSpacing.space3),
        ],
        HHSecondaryButton(
          label: 'Add Photos',
          isLoading: mediaController.isUploadingPhoto,
          icon: Icons.photo_library_outlined,
          onPressed: mediaController.uploadPhoto,
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo, required this.mediaController});

  final HotelMedia photo;
  final HotelMediaController mediaController;

  @override
  Widget build(BuildContext context) {
    final isDeleting = mediaController.deletingMediaId == photo.id;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        HHNetworkImage(url: photo.url, width: 72, height: 72),
        Positioned(
          top: -8,
          right: -8,
          child: InkWell(
            onTap: isDeleting || mediaController.deletingMediaId != null
                ? null
                : () => mediaController.deleteMedia(photo.id),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: HHColors.danger700,
              child: isDeleting
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
