import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../halls/presentation/screens/hall_list_screen.dart';
import '../../../../core/presentation/manager_formatters.dart';
import '../../application/hotel_context_controller.dart';
import '../../data/hotel_models.dart';
import 'hotel_profile_form_screen.dart';

/// Manager → My Hotel — the minimal navigation level between Home and
/// Halls the requested nav tree calls for. Shows the Hotel's own real
/// `status` field verbatim (no client-side translation into a Visible/
/// Hidden judgment — that stays server-computed, Hall Management Technical
/// Design §6).
class MyHotelScreen extends StatefulWidget {
  const MyHotelScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MyHotelScreen> createState() => _MyHotelScreenState();
}

class _MyHotelScreenState extends State<MyHotelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelContextController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotelContext = context.watch<HotelContextController>();

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('My Hotel'),
      ),
      body: SafeArea(child: _body(hotelContext)),
    );
  }

  Widget _body(HotelContextController hotelContext) {
    switch (hotelContext.status) {
      case HotelContextStatus.unknown:
      case HotelContextStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case HotelContextStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(HHSpacing.space7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: HHColors.danger700, size: 32),
                const SizedBox(height: HHSpacing.space3),
                Text(
                  hotelContext.errorMessage ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HHColors.textMuted),
                ),
                const SizedBox(height: HHSpacing.space5),
                ElevatedButton(
                  onPressed: hotelContext.load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );

      case HotelContextStatus.none:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(HHSpacing.space7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apartment_outlined,
                  color: HHColors.navy300,
                  size: 40,
                ),
                const SizedBox(height: HHSpacing.space5),
                Text(
                  'Set up your Hotel',
                  style: HHTypography.displaySm,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: HHSpacing.space3),
                Text(
                  "You haven't connected a Hotel to your account yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HHColors.textMuted,
                    fontSize: HHTypeScale.textMd,
                  ),
                ),
                if (hotelContext.errorMessage != null) ...[
                  const SizedBox(height: HHSpacing.space4),
                  HHErrorBanner(message: hotelContext.errorMessage!),
                ],
                const SizedBox(height: HHSpacing.space6),
                HHPrimaryButton(
                  label: 'Set up my Hotel',
                  onPressed: hotelContext.createHotel,
                  isLoading: false,
                ),
              ],
            ),
          ),
        );

      case HotelContextStatus.ready:
        final hotel = hotelContext.hotel!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(HHSpacing.cardPad),
                  child: Row(
                    children: [
                      Icon(Icons.apartment, color: HHColors.actionPrimary),
                      const SizedBox(width: HHSpacing.space4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hotel status',
                              style: TextStyle(
                                color: HHColors.textMuted,
                                fontSize: HHTypeScale.textXs,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ManagerFormatters.status(hotel.status),
                              style: TextStyle(
                                fontWeight: HHTypeScale.weightSemibold,
                                fontSize: HHTypeScale.textLg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hotelContext.errorMessage != null) ...[
                const SizedBox(height: HHSpacing.space5),
                HHErrorBanner(message: hotelContext.errorMessage!),
              ],
              ..._onboardingStep(context, hotelContext, hotel),
              const SizedBox(height: HHSpacing.space7),
              HHPrimaryButton(
                label: 'Manage Halls',
                isLoading: false,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HallListScreen(hotelId: hotel.id),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  /// The Hotel Manager Onboarding flow's current step (Hotel Management
  /// Business Specification §6, §8) — determined entirely from the Hotel's
  /// own backend `status`, never a locally-invented state machine. Only the
  /// steps this app actually implements (HM2 profile completion, HM3
  /// application submission) get a dedicated action; every other status
  /// (`REJECTED`, `SUSPENDED`, `DEACTIVATED`, `RESTRICTED_UNDER_REVIEW`,
  /// `WITHDRAWN`) is already visible verbatim in the status card above and
  /// gets no extra block here rather than an invented one.
  List<Widget> _onboardingStep(
    BuildContext context,
    HotelContextController hotelContext,
    Hotel hotel,
  ) {
    switch (hotel.status) {
      case 'REGISTERED':
        return [
          const SizedBox(height: HHSpacing.space5),
          _OnboardingCard(
            icon: Icons.assignment_outlined,
            iconColor: HHColors.actionAccent,
            title: 'Complete your Hotel profile',
            message:
                "Add your Hotel's business-profile information before you can submit it for review.",
            actionLabel: 'Complete Hotel Profile',
            onAction: () async {
              final done = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const HotelProfileFormScreen(),
                ),
              );
              if (done == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hotel profile saved.')),
                );
              }
            },
          ),
        ];

      case 'PROFILE_COMPLETE':
        return [
          const SizedBox(height: HHSpacing.space5),
          _OnboardingCard(
            icon: Icons.send_outlined,
            iconColor: HHColors.actionGold,
            title: 'Ready to submit',
            message:
                'Your Hotel profile is complete. Submit your application for Platform Administrator review.',
            actionLabel: 'Submit Application',
            isLoading: hotelContext.isSubmittingApplication,
            onAction: () async {
              final ok = await hotelContext.submitApplication();
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Application submitted for review.'),
                  ),
                );
              }
            },
          ),
        ];

      case 'UNDER_REVIEW':
        return [
          const SizedBox(height: HHSpacing.space5),
          _OnboardingCard(
            icon: Icons.hourglass_top_outlined,
            iconColor: HHColors.warning700,
            title: 'Under review',
            message:
                'Your application has been submitted and is awaiting Platform Administrator review.',
          ),
        ];

      default:
        return const [];
    }
  }
}

/// A single onboarding step — either informational (no `actionLabel`) or
/// actionable (`actionLabel` + `onAction`), matching the existing "Set up
/// your Hotel" empty-state visual language on this same screen.
class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HHSpacing.cardPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: HHSpacing.space3),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: HHTypeScale.weightSemibold,
                      fontSize: HHTypeScale.textLg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: HHSpacing.space3),
            Text(
              message,
              style: TextStyle(
                color: HHColors.textMuted,
                fontSize: HHTypeScale.textSm,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: HHSpacing.space5),
              HHPrimaryButton(
                label: actionLabel!,
                isLoading: isLoading,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
