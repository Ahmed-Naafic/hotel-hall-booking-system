import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../application/customer_profile_controller.dart';
import '../data/customer_profile_repository.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => CustomerProfileController(
      CustomerProfileRepository(context.read<ApiClient>()),
    )..load(),
    child: const _CustomerProfileView(),
  );
}

class _CustomerProfileView extends StatefulWidget {
  const _CustomerProfileView();
  @override
  State<_CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<_CustomerProfileView> {
  final _fullNameController = TextEditingController();
  bool _canSave = false;

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
    return profileData['fullName'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerProfileController>();
    final snapshot = controller.snapshot;
    final fullName = _fullNameFrom(snapshot);
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(HHSpacing.space6),
        child: controller.isLoading && snapshot == null
            ? const Center(child: CircularProgressIndicator())
            : controller.errorMessage != null && snapshot == null
            ? Center(
                child: TextButton(
                  onPressed: controller.load,
                  child: const Text('Retry'),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A registration made after Full Name became required
                  // (BDR-018) always has one; only an account registered
                  // before then can still lack it.
                  if (fullName != null && fullName.isNotEmpty)
                    Text(fullName, style: Theme.of(context).textTheme.titleLarge)
                  else
                    Text(
                      'Full name not set yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  const SizedBox(height: HHSpacing.space2),
                  Text(
                    snapshot?.user['mobileNumber'] as String? ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (fullName == null || fullName.isEmpty) ...[
                    const SizedBox(height: HHSpacing.space6),
                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: HHSpacing.space4),
                    FilledButton(
                      onPressed: controller.isLoading || !_canSave
                          ? null
                          : () => snapshot?.profile == null
                              ? controller.createProfile(_fullNameController.text.trim())
                              : controller.updateFullName(_fullNameController.text.trim()),
                      child: const Text('Save name'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
