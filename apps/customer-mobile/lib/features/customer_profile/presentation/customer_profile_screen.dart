import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../core/push_notification_service.dart';
import '../../notifications/application/notification_controller.dart';
import '../application/customer_profile_controller.dart';
import '../application/image_picker_service.dart';
import '../data/customer_profile_repository.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key, this.pickImage = pickImageFromGallery});

  // Injected (default: the real gallery picker) so tests can supply a fake
  // that returns fixed bytes instead of driving the real platform picker,
  // which needs a platform channel `flutter test` doesn't provide — the
  // same pattern apps/manager-mobile's `HotelProfileFormScreen` already
  // establishes for its own photo picking.
  final ImagePickerFn pickImage;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => CustomerProfileController(
      CustomerProfileRepository(context.read<ApiClient>()),
    )..load(),
    child: _CustomerProfileView(pickImage: pickImage),
  );
}

class _CustomerProfileView extends StatefulWidget {
  const _CustomerProfileView({required this.pickImage});
  final ImagePickerFn pickImage;
  @override
  State<_CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<_CustomerProfileView> {
  final _fullNameController = TextEditingController();
  bool _canSave = false;
  bool _editingName = false;
  // Whether the editor has already been opened automatically once for a
  // Customer with no name on file yet (a pre-BDR-018 account) — done only
  // the first time `snapshot` loads, never re-forced open after a Cancel.
  bool _autoOpenedOnce = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(() {
      final canSave = _fullNameController.text.trim().isNotEmpty;
      if (canSave != _canSave) setState(() => _canSave = canSave);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  String? _fullNameFrom(CustomerSnapshot? snapshot) {
    final profileData = snapshot?.profile?['profileData'];
    if (profileData is! Map) return null;
    final value = profileData['fullName'] as String?;
    return value?.trim().isEmpty == true ? null : value;
  }

  String? _avatarUrlFrom(CustomerSnapshot? snapshot) =>
      snapshot?.profile?['avatarUrl'] as String?;

  String _initialsFrom(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }

  // A calendar-day-only fact ("member since"), not a precise instant, so
  // formatted straight from the backend's UTC value rather than the
  // device's local timezone (unlike a Booking's actual start/end time,
  // which genuinely needs `.toLocal()`) — deliberately timezone-stable.
  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _openEditor(String? currentName) {
    _fullNameController.text = currentName ?? '';
    setState(() {
      _editingName = true;
      _canSave = currentName?.trim().isNotEmpty ?? false;
    });
  }

  void _closeEditor() {
    setState(() => _editingName = false);
  }

  Future<void> _changeAvatar(CustomerProfileController controller, String? currentAvatarUrl) async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(_AvatarAction.pick),
            ),
            if (currentAvatarUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: context.hh.danger700),
                title: Text('Remove photo', style: TextStyle(color: context.hh.danger700)),
                onTap: () => Navigator.of(context).pop(_AvatarAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == _AvatarAction.remove) {
      await controller.deleteAvatar();
    } else {
      final picked = await widget.pickImage();
      if (picked == null || !mounted) return;
      await controller.uploadAvatar(bytes: picked.bytes, filename: picked.filename);
    }
    if (mounted && controller.avatarErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.avatarErrorMessage!)),
      );
    }
  }

  Future<void> _save(CustomerProfileController controller, CustomerSnapshot? snapshot) async {
    final value = _fullNameController.text.trim();
    if (value.isEmpty) return;
    if (snapshot?.profile == null) {
      await controller.createProfile(value);
    } else {
      await controller.updateFullName(value);
    }
    if (mounted && controller.errorMessage == null) _closeEditor();
  }

  /// Mirrors Manager Mobile's own `ProfileScreen._logout` exactly — unregisters
  /// this device's push token (best-effort) before the session that
  /// authorized it goes away, so a shared device never keeps receiving this
  /// account's Notifications after logging out, then clears the session.
  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    final token = await PushNotificationService.instance.getToken();
    if (mounted) {
      await context.read<NotificationController>().unregisterDeviceToken(token);
    }
    if (!mounted) return;
    await context.read<AuthController>().logout();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerProfileController>();
    final snapshot = controller.snapshot;
    final fullName = _fullNameFrom(snapshot);
    final avatarUrl = _avatarUrlFrom(snapshot);
    // This screen is only ever opened by an authenticated Customer, but the
    // session can end underneath it — an expired refresh token trips
    // `ApiClient`'s sessionExpiredHandler, which clears the session without
    // closing whatever screen is open. Offering "Log out" to someone who is
    // already logged out is the visible symptom of that.
    final isAuthenticated =
        context.watch<AuthController>().status == AuthStatus.authenticated;

    // A registration made after Full Name became required (BDR-018) always
    // has one; only an account registered before then can still lack it —
    // for that case, open the editor once, automatically, the first time
    // data loads (never re-forced after the Customer explicitly cancels).
    if (snapshot != null && fullName == null && !_editingName && !_autoOpenedOnce) {
      _autoOpenedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openEditor(null);
      });
    }

    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(title: const Text('My Profile')),
      body: controller.isLoading && snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null && snapshot == null
          ? Center(
              child: TextButton(
                onPressed: controller.load,
                child: const Text('Retry'),
              ),
            )
          : RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.all(HHSpacing.space7),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Avatar(
                        avatarUrl: avatarUrl,
                        initials: fullName != null ? _initialsFrom(fullName) : null,
                        isUploading: controller.isUploadingAvatar,
                        onTap: controller.isUploadingAvatar
                            ? null
                            : () => _changeAvatar(controller, avatarUrl),
                      ),
                      const SizedBox(width: HHSpacing.space5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName ?? 'Add your name',
                              style: TextStyle(
                                fontSize: HHTypeScale.textXl,
                                fontWeight: HHTypeScale.weightSemibold,
                                fontStyle: fullName == null ? FontStyle.italic : FontStyle.normal,
                                color: fullName == null ? context.hh.textMuted : context.hh.textHeading,
                              ),
                            ),
                            const SizedBox(height: HHSpacing.space1),
                            Text(
                              snapshot?.user['mobileNumber'] as String? ?? '',
                              style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textSm),
                            ),
                          ],
                        ),
                      ),
                      if (!_editingName)
                        IconButton(
                          onPressed: () => _openEditor(fullName),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit name',
                        ),
                    ],
                  ),
                  if (_editingName) ...[
                    const SizedBox(height: HHSpacing.space5),
                    HHCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HHSectionLabel('EDIT NAME'),
                          HHTextField(label: 'Full name', controller: _fullNameController),
                          if (controller.errorMessage != null) ...[
                            const SizedBox(height: HHSpacing.space2),
                            Text(controller.errorMessage!, style: TextStyle(color: context.hh.danger700, fontSize: HHTypeScale.textSm)),
                          ],
                          const SizedBox(height: HHSpacing.space4),
                          Row(
                            children: [
                              Expanded(
                                child: HHPrimaryButton(
                                  label: 'Save',
                                  isLoading: controller.isLoading,
                                  onPressed: !_canSave || controller.isLoading ? null : () => _save(controller, snapshot),
                                ),
                              ),
                              if (fullName != null) ...[
                                const SizedBox(width: HHSpacing.space3),
                                TextButton(
                                  onPressed: controller.isLoading ? null : _closeEditor,
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: HHSpacing.space6),
                  HHCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HHSectionLabel('ACCOUNT'),
                        _accountRow(
                          'Mobile number',
                          Text(
                            snapshot?.user['mobileNumber'] as String? ?? '',
                            style: TextStyle(fontWeight: HHTypeScale.weightSemibold),
                          ),
                        ),
                        _accountRow(
                          'Verification',
                          HHStatusBadge(
                            label: snapshot?.user['isVerified'] == true ? 'Verified' : 'Not verified',
                            tone: snapshot?.user['isVerified'] == true ? HHBadgeTone.success : HHBadgeTone.neutral,
                          ),
                        ),
                        if (snapshot?.profile?['createdAt'] is String)
                          _accountRow(
                            'Member since',
                            Text(
                              _formatDate(DateTime.parse(snapshot!.profile!['createdAt'] as String)),
                              style: TextStyle(fontWeight: HHTypeScale.weightSemibold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: HHSpacing.space7),
                  const HHSectionLabel('APPEARANCE'),
                  const SizedBox(height: HHSpacing.space3),
                  Consumer<ThemeController>(
                    builder: (context, themeController, _) => HHThemeModeToggle(
                      mode: themeController.mode,
                      onChanged: themeController.setMode,
                    ),
                  ),
                  if (isAuthenticated) ...[
                    const SizedBox(height: HHSpacing.space7),
                    HHSecondaryButton(
                      label: 'Log out',
                      icon: Icons.logout,
                      isLoading: _loggingOut,
                      onPressed: _loggingOut ? null : _logout,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _accountRow(String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: HHSpacing.space2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.hh.textMuted)),
        value,
      ],
    ),
  );
}

enum _AvatarAction { pick, remove }

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.initials,
    required this.isUploading,
    required this.onTap,
  });

  final String? avatarUrl;
  final String? initials;
  final bool isUploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: context.hh.surfaceNavyTint, shape: BoxShape.circle),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, _) => _fallback(context),
                  )
                : _fallback(context),
          ),
          if (isUploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .35),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: context.hh.actionPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: context.hh.surfacePage, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context) => initials != null
      ? Text(
          initials!,
          style: TextStyle(fontSize: HHTypeScale.textXl, fontWeight: HHTypeScale.weightSemibold, color: context.hh.textHeading),
        )
      : Icon(Icons.person_outline_rounded, size: 32, color: context.hh.textSubtle);
}
