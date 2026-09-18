import * as applicationRepository from './application.repository.js'
import * as lifecycleService from './lifecycle.service.js'
import { recordAuditEvent } from './audit.js'
import { prisma } from '../../shared/prismaClient.js'
import * as notificationEvents from '../notifications/notification.events.js'
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
  let application
  try {
    application = await prisma.$transaction(async (client) => {
      const existingOpen = await applicationRepository.findOpenByHotelId(hotel.id, client)
      if (existingOpen) {
        throw new ConflictError('This Hotel already has an application under review.')
      }
      const created = await applicationRepository.create(hotel.id, client)
      await lifecycleService.transition(hotel, 'UNDER_REVIEW', { client })
      return created
    // Same widened timeout as `authentication.service.js#register`, same
    // reason (Neon serverless Postgres latency) — this transaction is a
    // read plus two writes, not a single query.
    }, { maxWait: 10000, timeout: 10000 })
  } catch (error) {
    if (error?.code === 'P2002') {
      throw new ConflictError('This Hotel already has an application under review.')
    }
    throw error
  }
  recordAuditEvent(wasRejected ? 'APPLICATION_RESUBMITTED' : 'APPLICATION_SUBMITTED', {
    hotelId: hotel.id,
    actorUserId: hotel.registeredByUserId,
    details: { applicationId: application.id },
  })
  await (wasRejected
    ? notificationEvents.onHotelApplicationResubmitted(application, hotel)
    : notificationEvents.onHotelApplicationSubmitted(application, hotel))
  return application
}

/** Withdrawal (HM9, BR-HOTEL-08) — only while the Application is still open. */
export async function withdrawApplication(hotel, applicationId) {
  const withdrawn = await prisma.$transaction(async (client) => {
    const application = await applicationRepository.findById(applicationId, client)
    if (!application || application.hotelId !== hotel.id) {
      throw new NotFoundError('Hotel application not found.')
    }
    if (application.status !== 'OPEN') {
      throw new ConflictError('This Hotel application is not open for withdrawal.')
    }
    const updated = await applicationRepository.withdraw(application.id, client)
    await lifecycleService.transition(hotel, 'WITHDRAWN', { client })
    return updated
  // Same widened timeout as `authentication.service.js#register` — see
  // `submitOrResubmitApplication` above for why.
  }, { maxWait: 10000, timeout: 10000 })
  recordAuditEvent('APPLICATION_WITHDRAWN', {
    hotelId: hotel.id,
    actorUserId: hotel.registeredByUserId,
    details: { applicationId: withdrawn.id },
  })
  await notificationEvents.onHotelApplicationWithdrawn(withdrawn, hotel)
  return withdrawn
}

/**
 * Records a Platform Administrator's approval or rejection decision
 * (HM5, HM6, BDR-003). Called only through the internal interface Module
 * 13's own, separately-authorized review workflow invokes — this function
 * performs no role check itself (BR-HOTEL-14, Technical Design §7, §12).
 */
export async function recordDecision(hotel, applicationId, decision, decidedByUserId, { decisionReason } = {}) {
  const nextHotelStatus = decision === 'APPROVED' ? 'APPROVED_ACTIVE' : 'REJECTED'
  const decided = await prisma.$transaction(async (client) => {
    const application = await applicationRepository.findById(applicationId, client)
    if (!application || application.hotelId !== hotel.id) {
      throw new NotFoundError('Hotel application not found.')
    }
    if (application.status !== 'OPEN') {
      throw new ConflictError('This application has already been decided or withdrawn.')
    }
    const updated = await applicationRepository.decide(
      application.id,
      { status: decision, decidedByUserId, decisionReason },
      client,
    )
    await lifecycleService.transition(hotel, nextHotelStatus, { client })
    return updated
  // Same widened timeout as `authentication.service.js#register` — see
  // `submitOrResubmitApplication` above for why.
  }, { maxWait: 10000, timeout: 10000 })
  recordAuditEvent(decision === 'APPROVED' ? 'APPLICATION_APPROVED' : 'APPLICATION_REJECTED', {
    hotelId: hotel.id,
    actorUserId: decidedByUserId,
    details: { applicationId: decided.id },
  })
  await (decision === 'APPROVED'
    ? notificationEvents.onHotelApplicationApproved(decided, hotel)
    : notificationEvents.onHotelApplicationRejected(decided, hotel))
  return decided
}

export function getLatestApplicationForHotel(hotelId) {
  return applicationRepository.findLatestByHotelId(hotelId)
}

export function listApplicationsForHotel(hotelId) {
  return applicationRepository.listByHotelId(hotelId)
}
