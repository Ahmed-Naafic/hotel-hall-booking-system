import { collections, fetchPage } from './sync.collections.js'
import { INITIAL_WINDOW, SyncCursorExpiredError, snapshotXmax } from './sync.cursor.js'
import * as repository from './sync.repository.js'
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

  // A cursor either continues a batch (it carries the batch's upper snapshot)
  // or opens the next one. Opening a batch runs the collection's `prepare`
  // first and takes the upper snapshot after it, so the preparation's own
  // writes are inside the batch. Continuing a batch does neither: its row set
  // is fixed by its two snapshots, and re-running the sweep per page would be
  // up to one lifecycle sweep per page of a cold start (sync.cursor.js).
  // A cursor from a database whose transaction counter has since moved
  // *backwards* — a point-in-time restore, a Neon branch reset — would treat
  // every new write as already seen, and skip it silently forever. Its
  // snapshots are then ahead of the database's own, which no genuine cursor
  // can be; the only safe answer is a full resync of this collection.
  if (cursor) {
    const now = snapshotXmax(await repository.currentSnapshot())
    for (const bound of [cursor.lo, cursor.hi]) {
      if (bound !== null && snapshotXmax(bound) > now) throw new SyncCursorExpiredError()
    }
  }

  let window = cursor ?? INITIAL_WINDOW
  if (window.hi === null) {
    if (definition.prepare) {
      await definition.prepare({
        scope,
        advanceLifecycle: bookingService.advanceLifecycleForSync,
      })
    }
    window = { lo: window.lo, hi: await repository.currentSnapshot(), after: null }
  }

  const { data, deleted, hasNext, nextCursor } = await fetchPage(collection, { scope, window, limit })

  return {
    data,
    deleted,
    scopeId: scope.scopeId,
    // Informational only. A client never builds a cursor from a clock — its
    // own or this one — only from `nextCursor`.
    serverTime: new Date().toISOString(),
    pagination: { limit, hasNext, nextCursor },
  }
}
