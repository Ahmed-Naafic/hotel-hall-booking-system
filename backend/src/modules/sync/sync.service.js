import { collections, fetchPage } from './sync.collections.js'
import * as scopeResolver from './sync.scope.js'
import * as bookingService from '../bookings/booking.service.js'
import { AuthorizationError, NotFoundError } from '../../shared/errors/errorTypes.js'

/**
 * Synchronization Component — answers "what changed in this collection since
 * my mark?" for the authenticated caller's own scope
 * (Local-First Synchronization Technical Design §6, §7).
 *
 * Business rules live in the modules that own each entity; this module owns
 * only change detection and scoping. It never decides whether a Hotel is
 * eligible, whether a Hall is visible, or whether a Booking may transition —
 * those stay where they already are.
 */

export async function changes({ identity, collection, cursor, limit }) {
  const definition = collections[collection]
  if (!definition) {
    // Unknown collection names are rejected by validation before reaching here;
    // this is the structural backstop so a registry typo cannot become an
    // unscoped query.
    throw new NotFoundError('Unknown sync collection.')
  }

  if (!definition.accountTypes.includes(identity.accountType)) {
    throw new AuthorizationError('You are not authorized to synchronize this collection.')
  }

  const scope = await scopeResolver.resolve(identity)

  if (definition.prepare) {
    await definition.prepare({
      scope,
      advanceLifecycle: bookingService.advanceLifecycleForSync,
    })
  }

  const { data, deleted, hasNext, nextCursor } = await fetchPage(collection, { scope, cursor, limit })

  return {
    data,
    deleted,
    scopeId: scope.scopeId,
    // The client stores this and never its own clock: a device with a skewed
    // clock must not be able to construct a cursor.
    serverTime: new Date().toISOString(),
    pagination: { limit, hasNext, nextCursor },
  }
}
