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

  const updated = await hallRepository.updateProfileData(hall.id, {
    ...(hall.profileData ?? {}),
    ...changedFields,
  })
  recordAuditEvent('HALL_PROFILE_UPDATED', { hallId: hall.id, hotelId: hall.hotelId })
  return updated
}
