import * as applicationRepository from './application.repository.js'
import * as lifecycleService from './lifecycle.service.js'
import { recordAuditEvent } from './audit.js'
import { BusinessRuleError, ConflictError, NotFoundError } from '../../shared/errors/errorTypes.js'

/**
 * Application Component (Technical Design §3, §7) — the application
 * lifecycle: submission, resubmission after rejection, and withdrawal
 * (BR-HOTEL-03, BR-HOTEL-06–BR-HOTEL-08). Every resubmission creates a new
 * HotelApplication record (Technical Design §4) — a rejected one is never
 * reopened or overwritten.
 *
 * Approval/rejection decisions (HM5, HM6) are recorded here too
 * (recordDecision), but only ever reached through the internal interface
 * Administration & Platform Management (Module 13) will call — this
 * component never exposes a public approve/reject endpoint itself
 * (BR-HOTEL-14, Technical Design §11).
 */

/**
 * Submission (HM3, from PROFILE_COMPLETE) and resubmission (HM7–HM8, from
 * REJECTED) share the same mechanics — a new Application record and the
 * matching Lifecycle transition. Technical Design §16 distinguishes an
 * incomplete-profile failure (422) from an already-under-review conflict
 * (409); both are handled explicitly here rather than left to the
 * Lifecycle Component's generic transition-rejected 409.
 */
export async function submitOrResubmitApplication(hotel) {
  if (hotel.status === 'UNDER_REVIEW') {
    throw new ConflictError('This Hotel already has an application under review.')
  }
  if (hotel.status !== 'PROFILE_COMPLETE' && hotel.status !== 'REJECTED') {
    throw new BusinessRuleError(
      'This Hotel is not eligible to submit an application from its current status.',
    )
  }

  const wasRejected = hotel.status === 'REJECTED'
  const application = await applicationRepository.create(hotel.id)
  await lifecycleService.transition(hotel, 'UNDER_REVIEW')
  recordAuditEvent(wasRejected ? 'APPLICATION_RESUBMITTED' : 'APPLICATION_SUBMITTED', {
    hotelId: hotel.id,
    actorUserId: hotel.registeredByUserId,
    details: { applicationId: application.id },
  })
  return application
}

/** Withdrawal (HM9, BR-HOTEL-08) — only while the Application is still open. */
export async function withdrawApplication(hotel) {
  const openApplication = await applicationRepository.findOpenByHotelId(hotel.id)
  if (!openApplication) {
    throw new ConflictError('This Hotel has no open application to withdraw.')
  }

  const withdrawn = await applicationRepository.withdraw(openApplication.id)
  await lifecycleService.transition(hotel, 'WITHDRAWN')
  recordAuditEvent('APPLICATION_WITHDRAWN', {
    hotelId: hotel.id,
    actorUserId: hotel.registeredByUserId,
    details: { applicationId: openApplication.id },
  })
  return withdrawn
}

/**
 * Records a Platform Administrator's approval or rejection decision
 * (HM5, HM6, BDR-003). Called only through the internal interface Module
 * 13's own, separately-authorized review workflow invokes — this function
 * performs no role check itself (BR-HOTEL-14, Technical Design §7, §12).
 */
export async function recordDecision(hotel, applicationId, decision, decidedByUserId) {
  const application = await applicationRepository.findById(applicationId)
  if (!application || application.hotelId !== hotel.id) {
    throw new NotFoundError('Hotel application not found.')
  }
  if (application.status !== 'OPEN') {
    throw new ConflictError('This application has already been decided or withdrawn.')
  }

  const nextHotelStatus = decision === 'APPROVED' ? 'APPROVED_ACTIVE' : 'REJECTED'
  await applicationRepository.decide(application.id, { status: decision, decidedByUserId })
  await lifecycleService.transition(hotel, nextHotelStatus)
  recordAuditEvent(decision === 'APPROVED' ? 'APPLICATION_APPROVED' : 'APPLICATION_REJECTED', {
    hotelId: hotel.id,
    actorUserId: decidedByUserId,
    details: { applicationId: application.id },
  })
  return applicationRepository.findById(application.id)
}
