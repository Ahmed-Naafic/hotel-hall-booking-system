/**
 * Hotel lifecycle status data — single source of truth for how every Hotel
 * Management screen labels, colors, and explains a Hotel's `status`
 * (backend Technical Design §6.2's `HotelStatus` enum, exactly as
 * implemented in `lifecycle.service.js`). No status is invented here; this
 * only formats what the API already returns. The `StatusBadge` component
 * that renders these lives in `StatusBadge.jsx` (react-refresh requires
 * component files to only export components).
 */

export const HOTEL_STATUSES = [
  'REGISTERED',
  'PROFILE_COMPLETE',
  'UNDER_REVIEW',
  'APPROVED_ACTIVE',
  'REJECTED',
  'WITHDRAWN',
  'SUSPENDED',
  'DEACTIVATED',
  'RESTRICTED_UNDER_REVIEW',
]

// The subset of statuses that only exist because an Application was
// submitted (application.service.js) — the statuses the "Applications"
// area of the product concerns itself with, as distinct from the full
// Hotel registry ("Hotels"). REGISTERED/PROFILE_COMPLETE precede any
// application; SUSPENDED/DEACTIVATED/RESTRICTED_UNDER_REVIEW are later
// operational states layered on top of an already-decided application.
export const APPLICATION_STATUSES = ['UNDER_REVIEW', 'APPROVED_ACTIVE', 'REJECTED', 'WITHDRAWN']

export const STATUS_TONE = {
  REGISTERED: { fg: 'var(--navy-400)', bg: 'var(--navy-050)' },
  PROFILE_COMPLETE: { fg: 'var(--navy-500)', bg: 'var(--navy-050)' },
  UNDER_REVIEW: { fg: 'var(--info-700)', bg: 'var(--info-100)' },
  APPROVED_ACTIVE: { fg: 'var(--success-700)', bg: 'var(--success-100)' },
  REJECTED: { fg: 'var(--danger-700)', bg: 'var(--danger-100)' },
  WITHDRAWN: { fg: 'var(--navy-400)', bg: 'var(--navy-050)' },
  SUSPENDED: { fg: 'var(--danger-700)', bg: 'var(--danger-100)' },
  DEACTIVATED: { fg: 'var(--danger-700)', bg: 'var(--danger-100)' },
  RESTRICTED_UNDER_REVIEW: { fg: 'var(--gold-700)', bg: 'var(--gold-100)' },
}

// Plain-language gloss of the Hotel's current lifecycle state — grounded
// in Technical Design §6 and the approved Business Specification §6/§7,
// not new business logic.
const STATUS_DESCRIPTION = {
  REGISTERED: 'The Hotel account has been created but has not yet completed its business profile.',
  PROFILE_COMPLETE: 'The Hotel has completed its profile and has not yet submitted an application for review.',
  UNDER_REVIEW: 'The Hotel has an application awaiting Platform Administrator review.',
  APPROVED_ACTIVE: 'The Hotel is approved and active — eligible to list Halls and receive Bookings.',
  REJECTED: 'The Hotel’s application was rejected. The Hotel may edit and resubmit it for another review.',
  WITHDRAWN: 'The Hotel withdrew its application before a decision was made.',
  SUSPENDED: 'The Hotel has been suspended by a Platform Administrator and is not currently operating.',
  DEACTIVATED: 'The Hotel has been deactivated by a Platform Administrator.',
  RESTRICTED_UNDER_REVIEW: 'The Hotel’s required information was found invalid and is under review.',
}

// A second, narrower gloss — specifically about where the Hotel's
// *application* stands, for the Hotel Details "Application" section
// (distinct from the general "Lifecycle Status" section above). Still
// derived only from the same real `status` field; no application record
// (submittedAt/decidedAt/decidedBy) is available from any admin-facing
// endpoint to say more than this (BR-HOTEL-14 — Administration & Platform
// Management, Module 13, not yet built).
const APPLICATION_DESCRIPTION = {
  REGISTERED: 'This Hotel has not yet submitted an application — its profile isn’t complete.',
  PROFILE_COMPLETE: 'This Hotel’s profile is complete but no application has been submitted yet.',
  UNDER_REVIEW: 'This Hotel has an application currently awaiting Platform Administrator review.',
  APPROVED_ACTIVE: 'This Hotel’s application was approved.',
  REJECTED: 'This Hotel’s most recent application was rejected. It may edit its profile and resubmit.',
  WITHDRAWN: 'This Hotel withdrew its application before a decision was made.',
  SUSPENDED: 'This Hotel’s application was approved; its operational status has since changed to suspended.',
  DEACTIVATED: 'This Hotel’s application was approved; its operational status has since changed to deactivated.',
  RESTRICTED_UNDER_REVIEW:
    'This Hotel’s application was approved; it is now under review again due to invalid required information.',
}

export function formatStatusLabel(status) {
  if (typeof status !== 'string') return status
  return status
    .toLowerCase()
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}

export function describeStatus(status) {
  return STATUS_DESCRIPTION[status] ?? ''
}

export function describeApplicationStatus(status) {
  return APPLICATION_DESCRIPTION[status] ?? ''
}
