import * as hotelRepository from './hotel.repository.js'
import * as criticalChangeRepository from './criticalChange.repository.js'
import * as lifecycleService from './lifecycle.service.js'
import { recordAuditEvent } from './audit.js'
import { BusinessRuleError, ConflictError } from '../../shared/errors/errorTypes.js'

/**
 * Profile Component (Technical Design §3, §8) — profile completion
 * (BR-HOTEL-02) and ordinary/critical change routing (BR-HOTEL-11,
 * BR-HOTEL-12).
 *
 * The field classification (which fields are "critical") is Pending
 * Business Decision #5 — genuinely undefined. Per Technical Design §8, the
 * routing *mechanism* is fully specified and implemented below; the
 * classification *data* is an injectable ruleset, defaulted to empty (no
 * field pre-classified as critical) so every change is ordinary until a
 * real ruleset is supplied. This default is NOT a business decision that
 * "nothing is critical" — it is the absence of one, and must not be relied
 * on as final production behavior once Pending Business Decision #5
 * resolves.
 */
const DEFAULT_CRITICAL_FIELDS = []

/**
 * Profile completion (HM2) — from REGISTERED only. Required-field content
 * is Pending Business Decision #7 (Required Business-Profile Content); the
 * only check made here — that some profile data was actually supplied — is
 * generic and does not assume any specific field.
 */
export async function completeProfile(hotel, profileData) {
  if (hotel.status !== 'REGISTERED') {
    throw new BusinessRuleError(
      'Only a newly-registered Hotel can complete its initial profile.',
    )
  }
  if (!profileData || typeof profileData !== 'object' || Object.keys(profileData).length === 0) {
    throw new BusinessRuleError('Profile information is required to complete a Hotel profile.')
  }

  await hotelRepository.updateProfileData(hotel.id, profileData)
  const updated = await lifecycleService.transition(hotel, 'PROFILE_COMPLETE')
  recordAuditEvent('PROFILE_COMPLETED', { hotelId: hotel.id, actorUserId: hotel.registeredByUserId })
  return updated
}

/**
 * Editing a rejected application's draft profile (HM7, BR-HOTEL-06) — the
 * Hotel remains REJECTED throughout (Technical Design §6: "Rejected —
 * Editing" is a client-side/workflow distinction, not a persisted status);
 * no Lifecycle transition happens here. Resubmission
 * (application.service.js) is the separate action that moves the Hotel
 * back to UNDER_REVIEW.
 */
export async function editRejectedApplication(hotel, changedFields) {
  if (hotel.status !== 'REJECTED') {
    throw new BusinessRuleError('Only a Rejected Hotel can edit its application.')
  }
  if (!changedFields || typeof changedFields !== 'object' || Object.keys(changedFields).length === 0) {
    throw new BusinessRuleError('At least one profile field must be provided to edit.')
  }

  const updated = await hotelRepository.updateProfileData(hotel.id, {
    ...(hotel.profileData ?? {}),
    ...changedFields,
  })
  recordAuditEvent('APPLICATION_EDITED_AFTER_REJECTION', {
    hotelId: hotel.id,
    actorUserId: hotel.registeredByUserId,
  })
  return updated
}

/**
 * Ordinary/critical profile change (HM12, HM13) — only for an
 * Approved/Active Hotel. Any critical field present in `changedFields`
 * routes the *entire* change to review (a conservative default that never
 * weakens BR-HOTEL-12's review requirement by silently splitting a request).
 */
export async function changeProfile(hotel, changedFields, { criticalFields } = {}) {
  if (hotel.status !== 'APPROVED_ACTIVE') {
    throw new BusinessRuleError(
      "This Hotel's current status does not permit profile changes.",
    )
  }
  if (!changedFields || typeof changedFields !== 'object' || Object.keys(changedFields).length === 0) {
    throw new BusinessRuleError('At least one profile field must be provided to change.')
  }

  const classificationRuleset = criticalFields ?? DEFAULT_CRITICAL_FIELDS
  const touchesCriticalField = Object.keys(changedFields).some((field) =>
    classificationRuleset.includes(field),
  )

  if (!touchesCriticalField) {
    const updated = await hotelRepository.updateProfileData(hotel.id, {
      ...(hotel.profileData ?? {}),
      ...changedFields,
    })
    recordAuditEvent('ORDINARY_PROFILE_CHANGE_APPLIED', {
      hotelId: hotel.id,
      actorUserId: hotel.registeredByUserId,
    })
    return { applied: true, hotel: updated, criticalChangeRequest: null }
  }

  const existingOpen = await criticalChangeRepository.findOpenByHotelId(hotel.id)
  if (existingOpen) {
    throw new ConflictError(
      'This Hotel already has a critical information change pending review.',
    )
  }

  const criticalChangeRequest = await criticalChangeRepository.create(hotel.id, changedFields)
  recordAuditEvent('CRITICAL_PROFILE_CHANGE_SUBMITTED', {
    hotelId: hotel.id,
    actorUserId: hotel.registeredByUserId,
    details: { criticalChangeRequestId: criticalChangeRequest.id },
  })
  return { applied: false, hotel, criticalChangeRequest }
}

/**
 * Records a Platform Administrator's decision on a Critical Information
 * Change Request (BR-HOTEL-12). Called only through the internal interface
 * Module 13's own, separately-authorized review workflow invokes
 * (BR-HOTEL-14, Technical Design §7's pattern applied to §8).
 */
export async function recordCriticalChangeDecision(hotel, requestId, decision, decidedByUserId) {
  const request = await criticalChangeRepository.findById(requestId)
  if (!request || request.hotelId !== hotel.id) {
    throw new BusinessRuleError('Critical information change request not found for this Hotel.')
  }
  if (request.status !== 'PENDING') {
    throw new ConflictError('This change request has already been decided.')
  }

  if (decision === 'APPLIED') {
    await hotelRepository.updateProfileData(hotel.id, {
      ...(hotel.profileData ?? {}),
      ...request.proposedData,
    })
  }

  const decided = await criticalChangeRepository.decide(request.id, {
    status: decision,
    decidedByUserId,
  })
  recordAuditEvent('CRITICAL_PROFILE_CHANGE_DECIDED', {
    hotelId: hotel.id,
    actorUserId: decidedByUserId,
    details: { criticalChangeRequestId: request.id, decision },
  })
  return decided
}
