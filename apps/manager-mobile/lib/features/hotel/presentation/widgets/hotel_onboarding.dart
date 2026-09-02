import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../application/hotel_context_controller.dart';
import '../../data/hotel_models.dart';
import '../screens/hotel_profile_form_screen.dart';

/// Purely presentational — maps the backend's own status string to a
/// visual tone, never a business judgment. Every branch renders the exact
/// same status text; only the color changes. Shared by [MyHotelScreen] and
/// the Dashboard's Home tab so both render the identical status→tone
/// mapping rather than two copies that could drift.
HHBadgeTone toneForHotelStatus(String status) {
  switch (status) {
    case 'APPROVED_ACTIVE':
      return HHBadgeTone.success;
    case 'UNDER_REVIEW':
    case 'RESTRICTED_UNDER_REVIEW':
      return HHBadgeTone.warning;
    case 'REJECTED':
    case 'SUSPENDED':
    case 'DEACTIVATED':
    case 'WITHDRAWN':
      return HHBadgeTone.danger;
    case 'REGISTERED':
    case 'PROFILE_COMPLETE':
      return HHBadgeTone.info;
    default:
      return HHBadgeTone.neutral;
  }
}

class HotelIdentityCard extends StatelessWidget {
  const HotelIdentityCard({super.key, required this.hotel, this.onTap});

  final Hotel hotel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = hotel.profileData?['name']?.toString().trim();

    return HHCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: HHColors.surfaceNavyTint,
                  borderRadius: BorderRadius.circular(HHRadii.control),
                ),
                child: Icon(Icons.apartment, color: HHColors.actionPrimary),
              ),
              const SizedBox(width: HHSpacing.space4),
              Expanded(
                child: Text(
                  (name == null || name.isEmpty) ? 'My Hotel' : name,
                  style: TextStyle(
                    fontWeight: HHTypeScale.weightSemibold,
                    fontSize: HHTypeScale.textXl,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: HHSpacing.space5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const SizedBox(height: HHSpacing.space2),
                    HHStatusBadge(
                      label: ManagerFormatters.status(hotel.status),
                      tone: toneForHotelStatus(hotel.status),
                    ),
                  ],
                ),
              ),
              Text(
                'Since ${hotel.createdAt.toLocal().year}-${hotel.createdAt.toLocal().month.toString().padLeft(2, '0')}-${hotel.createdAt.toLocal().day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: HHColors.textSubtle,
                  fontSize: HHTypeScale.textXs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single onboarding step — either informational (no `actionLabel`) or
/// actionable (`actionLabel` + `onAction`), matching the existing "Set up
/// your Hotel" empty-state visual language.
class HotelOnboardingCard extends StatelessWidget {
  const HotelOnboardingCard({
    super.key,
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
    return HHCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(HHRadii.control),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: HHSpacing.space4),
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
              height: 1.4,
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
    );
  }
}

/// The Hotel Manager Onboarding flow's current step (Hotel Management
/// Business Specification §6, §8) — determined entirely from the Hotel's
/// own backend `status`, never a locally-invented state machine. Only the
/// steps this app actually implements (HM2 profile completion, HM3
/// application submission) get a dedicated action; every other status
/// (`REJECTED`, `SUSPENDED`, `DEACTIVATED`, `RESTRICTED_UNDER_REVIEW`,
/// `WITHDRAWN`) is already visible verbatim in the identity card above and
/// gets no extra block here rather than an invented one. Shared by
/// [MyHotelScreen] and the Dashboard's Home tab.
List<Widget> hotelOnboardingSteps(
  BuildContext context,
  HotelContextController hotelContext,
  Hotel hotel,
) {
  switch (hotel.status) {
    case 'REGISTERED':
      return [
        const SizedBox(height: HHSpacing.space5),
        HotelOnboardingCard(
          icon: Icons.assignment_outlined,
          iconColor: HHColors.actionAccent,
          title: 'Complete your Hotel profile',
          message:
              "Add your Hotel's business-profile information before you can submit it for review.",
          actionLabel: 'Complete Hotel Profile',
          onAction: () async {
            final done = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const HotelProfileFormScreen()),
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
        HotelOnboardingCard(
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
                const SnackBar(content: Text('Application submitted for review.')),
              );
            }
          },
        ),
      ];

    case 'UNDER_REVIEW':
      return [
        const SizedBox(height: HHSpacing.space5),
        HotelOnboardingCard(
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
