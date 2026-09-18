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

/// The Hotel's own identity at a glance — logo, name, status, and creation
/// date. Deliberately never grows to show Description/Location/Contact
/// info: that fuller, Photos-inclusive view lives one tap away, at
/// `HotelDetailsScreen`, not inline here. Used by the Dashboard's Home tab
/// (its own compact summary card), which fetches the Logo separately (it's
/// Hotel Media, not part of the `Hotel` model itself) and passes it down.
/// `MyHotelScreen` shows its own richer profile presentation instead —
/// `HotelProfileHeader` — since the Hotel tab has room for it.
class HotelIdentityCard extends StatelessWidget {
  const HotelIdentityCard({super.key, required this.hotel, this.logoUrl, this.onTap});

  final Hotel hotel;

  /// The Hotel Logo's URL, when known — `null` until the caller's own
  /// separate media fetch resolves, or when there is no Logo yet.
  final String? logoUrl;
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
              (logoUrl == null || logoUrl!.isEmpty)
                  ? Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.hh.surfaceNavyTint,
                        borderRadius: BorderRadius.circular(HHRadii.control),
                      ),
                      child: Icon(Icons.apartment, color: context.hh.actionPrimary),
                    )
                  : HHNetworkImage(
                      url: logoUrl,
                      width: 48,
                      height: 48,
                      borderRadius: HHRadii.control,
                      fallbackIcon: Icons.apartment,
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
              if (onTap != null)
                Icon(Icons.chevron_right, color: context.hh.textSubtle),
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
                        color: context.hh.textMuted,
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
                  color: context.hh.textSubtle,
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
              color: context.hh.textMuted,
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
          iconColor: context.hh.actionAccent,
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
          iconColor: context.hh.actionGold,
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
          iconColor: context.hh.warning700,
          title: 'Under review',
          message:
              'Your application has been submitted and is awaiting Platform Administrator review.',
        ),
      ];

    default:
      return const [];
  }
}
