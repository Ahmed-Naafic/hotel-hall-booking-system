import * as hallRepository from './hall.repository.js'
import { recordAuditEvent } from './audit.js'
import { BusinessRuleError } from '../../shared/errors/errorTypes.js'

/**
 * Profile Component (Technical Design §3, §7–§8) — Hall information
 * updates. Unlike Hotel Management's Profile Component, there is no
 * ordinary/critical classification or review routing here: `BR-HALL-07`
 * establishes that no approved decision defines Hall update rules at all,
 * so there is no approved basis for inventing a review gate. Every
 * well-formed, authorized update simply applies (Technical Design §7) —
 * the necessary default absence of a decision, not a foreclosure of
 * Pending Decisions #2/#3/#7 eventually introducing one.
 */
export async function updateHallProfile(hall, changedFields) {
  if (!changedFields || typeof changedFields !== 'object' || Object.keys(changedFields).length === 0) {
    throw new BusinessRuleError('At least one profile field must be provided to update.')
  }

  const commercialKeys = ['rentAmountCents', 'rentDurationHours', 'advancePaymentPercent', 'customerServiceNumber', 'paymentReceivingNumber']
  // `isActive` is a real column (Hall.isActive), not profile content — kept
  // out of the profileData merge below the same way commercialKeys are.
  const directColumnKeys = ['isActive']
  const commercialData = Object.fromEntries(commercialKeys.filter((key) => changedFields[key] !== undefined).map((key) => [key, changedFields[key]]))
  const directData = Object.fromEntries(directColumnKeys.filter((key) => changedFields[key] !== undefined).map((key) => [key, changedFields[key]]))
  const profileChanges = Object.fromEntries(
    Object.entries(changedFields).filter(([key]) => ![...commercialKeys, ...directColumnKeys].includes(key)),
  )
  const updated = await hallRepository.update(hall.id, {
    profileData: { ...(hall.profileData ?? {}), ...profileChanges },
    ...commercialData,
    ...directData,
  })
  recordAuditEvent('HALL_PROFILE_UPDATED', { hallId: hall.id, hotelId: hall.hotelId })
  return updated
}
