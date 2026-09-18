import { prisma } from '../../shared/prismaClient.js'
import * as availabilityRepository from './availability.repository.js'
import * as hallService from '../halls/hall.service.js'
import * as visibilityService from '../halls/visibility.service.js'
import { recordAuditEvent } from './audit.js'
import { lockHallSchedule } from './hallScheduleLock.js'
import * as notificationEvents from '../notifications/notification.events.js'
import { BusinessRuleError, ConflictError, NotFoundError } from '../../shared/errors/errorTypes.js'

/**
 * Availability Component — given a Hall and a period, answers "can this
 * Hall be booked?". Combines Hall Management's existing own-Hotel/
 * visibility check (never re-implemented here, architecture-principles.md
 * §5) with this module's own manual blocks. Booking Management does not
 * exist yet (Approved Technical Design §2/§18) — `hasOverlap` currently
 * only ever sees other blocks; the day it needs to also see blocking
 * Bookings, only the repository query this module calls changes, never
 * this module's callers.
 */

const MOGADISHU_OFFSET_MINUTES = 3 * 60

/**
 * Mogadishu (East Africa Time) is a fixed UTC+3 offset, no DST — a full
 * IANA timezone database is unnecessary machinery for a single-city,
 * single-offset system (Approved Technical Design §4). `dateString` is
 * `YYYY-MM-DD`, interpreted as a Mogadishu calendar day.
 */
export function mogadishuDayToUtcRange(dateString) {
  const [year, month, day] = dateString.split('-').map(Number)
  const localMidnightUtcMillis = Date.UTC(year, month - 1, day, 0, 0, 0) - MOGADISHU_OFFSET_MINUTES * 60 * 1000
  const rangeStart = new Date(localMidnightUtcMillis)
  const rangeEnd = new Date(localMidnightUtcMillis + 24 * 60 * 60 * 1000)
  return { rangeStart, rangeEnd }
}

function combineMogadishuDateTime(dateString, timeString) {
  const [year, month, day] = dateString.split('-').map(Number)
  const [hour, minute] = timeString.split(':').map(Number)
  const utcMillis = Date.UTC(year, month - 1, day, hour, minute, 0) - MOGADISHU_OFFSET_MINUTES * 60 * 1000
  return new Date(utcMillis)
}

/**
 * `date` + `startTime` + `endTime` (business rule 1's own framing) collapse
 * into two absolute instants (Approved Technical Design §4). `endsAt` rolls
 * to the next calendar day whenever its raw time-of-day is not strictly
 * after `startsAt`'s (i.e. whenever `endsAt <= startsAt` before rollover) —
 * this single rule covers exactly three cases, and only these three:
 *
 *   - Normal same-day period (`startTime < endTime`, e.g. `10:00`→`14:00`):
 *     no rollover; `startsAt`/`endsAt` both land on `date`.
 *   - Overnight period (`endTime <= startTime`, e.g. `22:00`→`02:00`):
 *     rolls forward one day; `endsAt` lands on the day after `date`.
 *   - Identical start/end time-of-day (e.g. `10:00`→`10:00`): also rolls
 *     forward one day (the `<=` above, not `<`, is what catches this) —
 *     this produces a full 24-hour period, *never* a zero-length one.
 *     There is deliberately no "zero-duration" case: every well-formed
 *     `(date, startTime, endTime)` triple produces `endsAt > startsAt` by
 *     construction, so there is no separate "end before/equal to start"
 *     business error for this function to raise.
 */
export function combineBlockPeriod({ date, startTime, endTime }) {
  const startsAt = combineMogadishuDateTime(date, startTime)
  let endsAt = combineMogadishuDateTime(date, endTime)
  // `<=`, not `<` — equal time-of-day (e.g. 10:00->10:00) must also roll
  // forward, producing a full 24-hour period rather than a zero-length one.
  if (endsAt <= startsAt) {
    endsAt = new Date(endsAt.getTime() + 24 * 60 * 60 * 1000) // overnight (or identical start/end): next calendar day
  }
  return { startsAt, endsAt }
}

/**
 * The `[start, end)` overlap rule (Approved Technical Design §5), as a
 * pure, independently-testable function — `availability.repository.js#hasOverlap`
 * expresses this identical rule as a SQL predicate (`starts_at < :end AND
 * ends_at > :start`) because only the database can see concurrent writes;
 * this function exists so the exact boundary semantics (e.g. adjacent
 * periods never overlap) can be unit-tested without a database.
 */
export function intervalsOverlap({ startA, endA, startB, endB }) {
  return startA < endB && startB < endA
}

/** Approved decision 5 — applies identically to create and edit. */
export function assertBlockStartsInFuture(startsAt) {
  if (startsAt <= new Date()) {
    throw new BusinessRuleError('A manual availability block must start in the future.')
  }
}

/**
 * Any DB-level rejection reaching here after the pre-check already passed
 * is, by construction, the `EXCLUDE` constraint catching a race the
 * pre-check missed (Approved Technical Design §5/§11) — never a different
 * kind of failure, since every other precondition was already validated
 * before this point. Mapped to the same 409 the pre-check itself raises,
 * so callers never see a distinction between "we caught it early" and "the
 * database caught it at the last instant".
 *
 * Empirically confirmed against the real Neon dev database (a genuine
 * concurrent-insert exclusion violation, not a guess): Prisma 7 +
 * `@prisma/adapter-pg` surfaces this as `PrismaClientKnownRequestError`
 * with `error.code === 'P2039'`, wrapping the original Postgres error
 * (`23P01`) at `error.meta.driverAdapterError.cause.code`. Both are
 * checked — `P2039` as the primary Prisma-level signal, the nested
 * Postgres code as a defensive fallback in case Prisma's own wrapper code
 * ever changes.
 */
function isExclusionViolation(error) {
  const pgCode = error?.meta?.driverAdapterError?.cause?.code ?? error?.meta?.driverAdapterError?.cause?.originalCode
  return error?.code === 'P2039' || pgCode === '23P01'
}

/**
 * The Availability Query Interface's write-side guard — throws on conflict.
 *
 * Deliberately does not fire the Booking-expired Notification (C8) for any
 * row this expires: `client` here is frequently an in-progress
 * `prisma.$transaction` (block/Booking creation) that can still roll back
 * for an unrelated reason (e.g. an exclusion-constraint conflict on the
 * very write this guard is checking for) — a Notification persisted
 * against the ambient global Prisma client would not roll back with it,
 * which could announce a Booking as expired when it, in fact, was not.
 * `isPeriodFree`/`getPublicAvailability` below (never transactional) and
 * `booking.repository.js#expireOverdue` (covering every ordinary
 * list/get) all independently sweep the same overdue Bookings, so this
 * omission only ever delays a correct Notification to the next safe,
 * non-transactional touch point — it never skips one.
 */
export async function assertPeriodIsFree({ hallId, startsAt, endsAt, excludeBlockId, excludeBookingId, client }) {
  await availabilityRepository.expireOverdueBookings({ hallId, now: new Date() }, client)
  const overlapping = await availabilityRepository.hasOverlap(
    { hallId, startsAt, endsAt, excludeId: excludeBlockId },
    client,
  )
  if (overlapping) {
    throw new ConflictError('This period conflicts with an existing availability block.')
  }
  const bookingOverlap = await availabilityRepository.hasBlockingBookingOverlap(
    { hallId, startsAt, endsAt, excludeBookingId },
    client,
  )
  if (bookingOverlap) {
    throw new ConflictError('This period conflicts with an existing booking.')
  }
}

/** The Availability Query Interface's read-side check — never throws. Never transactional, so it is safe to notify on any Booking it expires. */
export async function isPeriodFree({ hallId, startsAt, endsAt, excludeBlockId }) {
  const expired = await availabilityRepository.expireOverdueBookings({ hallId, now: new Date() })
  await Promise.all(expired.map((booking) => notificationEvents.onBookingExpired(booking)))
  const [blockOverlap, bookingOverlap] = await Promise.all([
    availabilityRepository.hasOverlap({ hallId, startsAt, endsAt, excludeId: excludeBlockId }),
    availabilityRepository.hasBlockingBookingOverlap({ hallId, startsAt, endsAt }),
  ])
  return !blockOverlap && !bookingOverlap
}

/** Manager day-view — caller (controller) has already asserted own-Hotel ownership. */
export async function getBlocksForHall({ hallId, date }) {
  const { rangeStart, rangeEnd } = mogadishuDayToUtcRange(date)
  return availabilityRepository.listForHallInRange({ hallId, rangeStart, rangeEnd })
}

export async function createBlock({ hallId, date, startTime, endTime, reason, createdByUserId }) {
  const { startsAt, endsAt } = combineBlockPeriod({ date, startTime, endTime })
  assertBlockStartsInFuture(startsAt)

  let block
  try {
    block = await prisma.$transaction(async (client) => {
      await lockHallSchedule(hallId, client)
      await assertPeriodIsFree({ hallId, startsAt, endsAt, client })
      return availabilityRepository.create({ hallId, startsAt, endsAt, reason, createdByUserId }, client)
    // Same widened timeout as `authentication.service.js#register`, same
    // reason (Neon serverless Postgres latency) — this transaction also
    // does a schedule lock plus an overlap check before its write.
    }, { maxWait: 10000, timeout: 10000 })
  } catch (error) {
    if (isExclusionViolation(error)) {
      throw new ConflictError('This period conflicts with an existing availability block.')
    }
    throw error
  }

  recordAuditEvent('BLOCK_CREATED', { blockId: block.id, hallId, actorUserId: createdByUserId })
  return block
}

export async function updateBlock({ hallId, blockId, date, startTime, endTime, reason }) {
  const existing = await availabilityRepository.findByIdForHall(blockId, hallId)
  if (!existing) {
    throw new NotFoundError('Availability block not found.')
  }

  const nextDate = date ?? null
  const usingCombinedPeriod = date !== undefined || startTime !== undefined || endTime !== undefined
  let startsAt = existing.startsAt
  let endsAt = existing.endsAt
  if (usingCombinedPeriod) {
    // Merge semantics (Hall's own PATCH precedent): a field not supplied
    // falls back to the existing block's own current value, never a guess.
    const existingDateIso = existing.startsAt.toISOString()
    const combined = combineBlockPeriod({
      date: nextDate ?? existingDateIso.slice(0, 10),
      startTime: startTime ?? existingDateIso.slice(11, 16),
      endTime: endTime ?? existing.endsAt.toISOString().slice(11, 16),
    })
    startsAt = combined.startsAt
    endsAt = combined.endsAt
  }

  assertBlockStartsInFuture(startsAt)

  let updated
  try {
    updated = await prisma.$transaction(async (client) => {
      await lockHallSchedule(hallId, client)
      await assertPeriodIsFree({ hallId, startsAt, endsAt, excludeBlockId: blockId, client })
      return availabilityRepository.update(blockId, { startsAt, endsAt, reason: reason ?? existing.reason }, client)
    // Same widened timeout as `authentication.service.js#register` — see
    // `createBlock` above for why.
    }, { maxWait: 10000, timeout: 10000 })
  } catch (error) {
    if (isExclusionViolation(error)) {
      throw new ConflictError('This period conflicts with an existing availability block.')
    }
    throw error
  }

  recordAuditEvent('BLOCK_UPDATED', { blockId, hallId })
  return updated
}

export async function deleteBlock({ hallId, blockId }) {
  const existing = await availabilityRepository.findByIdForHall(blockId, hallId)
  if (!existing) {
    throw new NotFoundError('Availability block not found.')
  }
  await availabilityRepository.deleteById(blockId)
  recordAuditEvent('BLOCK_DELETED', { blockId, hallId })
}

/**
 * Public read — resolves the Hall directly (this endpoint is flat, no
 * `:hotelId` in its path) and reuses Hall Management's own Visibility
 * Component unmodified. A Hidden Hall (Hotel not APPROVED_ACTIVE) never
 * exposes its availability, same as it never exposes anything else.
 */
export async function getPublicAvailability({ hallId, date }) {
  const hall = await hallService.getHallById(hallId)
  const visible = await visibilityService.isHallVisible(hall, { isOwner: false })
  if (!visible) {
    throw new NotFoundError('Hall not found.')
  }
  const { rangeStart, rangeEnd } = mogadishuDayToUtcRange(date)
  const expired = await availabilityRepository.expireOverdueBookings({ hallId, now: new Date() })
  await Promise.all(expired.map((booking) => notificationEvents.onBookingExpired(booking)))
  const [blocks, bookings] = await Promise.all([
    availabilityRepository.listForHallInRange({ hallId, rangeStart, rangeEnd }),
    availabilityRepository.listBlockingBookingsForHallInRange({ hallId, rangeStart, rangeEnd }),
  ])
  return [...blocks, ...bookings].sort((a, b) => a.startsAt - b.startsAt)
}

export async function checkAvailability({ hallId, date, startTime, endTime }) {
  const hall = await hallService.getHallById(hallId)
  const visible = await visibilityService.isHallVisible(hall, { isOwner: false })
  if (!visible) {
    throw new NotFoundError('Hall not found.')
  }
  const { startsAt, endsAt } = combineBlockPeriod({ date, startTime, endTime })
  const available = await isPeriodFree({ hallId, startsAt, endsAt })
  return { available }
}
