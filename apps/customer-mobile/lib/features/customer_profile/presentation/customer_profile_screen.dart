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

class _CustomerProfileView extends StatelessWidget {
  const _CustomerProfileView();
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerProfileController>();
    final snapshot = controller.snapshot;
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
                  Text(
                    snapshot?.user['mobileNumber'] as String? ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: HHSpacing.space4),
                  Text(
                    snapshot?.profile == null
                        ? 'No Customer profile has been created.'
                        : 'Customer profile created.',
                  ),
                  const SizedBox(height: HHSpacing.space4),
                  const Text(
                    'Profile fields and completion requirements are awaiting business approval.',
                  ),
                  if (snapshot?.profile == null) ...[
                    const SizedBox(height: HHSpacing.space6),
                    FilledButton(
                      onPressed: controller.isLoading
                          ? null
                          : controller.createProfile,
                      child: const Text('Create Profile'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
