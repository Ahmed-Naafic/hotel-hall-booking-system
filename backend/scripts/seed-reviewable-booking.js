import { randomBytes } from 'node:crypto'
import { prisma } from '../src/shared/prismaClient.js'
import { hashPassword } from '../src/modules/authentication/credential.service.js'

/**
 * Creates a Booking that is already COMPLETED, so "Leave a Review" is
 * reachable on Customer Mobile straight away.
 *
 * Reviewing is gated on a Booking that genuinely ran its course: a Booking
 * must start in the future (booking.service.js — "A booking must start in
 * the future."), may only be completed once it has ended ("A booking can
 * only be completed after it ends."), and only a COMPLETED Booking may be
 * reviewed (review.service.js). Those rules are correct, but they put the
 * review screen out of reach of a manual test session — you would have to
 * book a slot and then wait out the entire event. This writes the finished
 * Booking directly instead, bypassing the clock and nothing else.
 *
 * Manual-testing aid only — never wire this into application code, and
 * never run it against production.
 *
 * Usage:
 *   node scripts/seed-reviewable-booking.js [--mobile +15551234567] [--password "Some Password"]
 *
 * `--mobile` reuses an existing Customer (so you can seed onto the account
 * already signed in on your device); omit it and a fresh verified Customer
 * is created and its credentials printed once.
 */

const HOTEL_NAME = 'Review Test Hotel'

function parseArgs(argv) {
  const args = {}
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--mobile') args.mobile = argv[++i]
    if (argv[i] === '--password') args.password = argv[++i]
  }
  return args
}

// Digits only — this number is typed into the login screen by hand, and the
// mobile-number format the auth module accepts has no room for hex letters.
const generateMobileNumber = () => `+1${(100000000 + (randomBytes(4).readUInt32BE(0) % 899999999))}`
const generatePassword = () => randomBytes(18).toString('base64url')

async function resolveCustomer({ mobile, password }) {
  if (mobile) {
    const existing = await prisma.user.findUnique({ where: { mobileNumber: mobile } })
    if (!existing) throw new Error(`No user with mobileNumber ${mobile}.`)
    if (existing.accountType !== 'CUSTOMER') {
      throw new Error(`${mobile} is a ${existing.accountType}, not a CUSTOMER.`)
    }
    // A Booking is only reviewable by a Customer who can reach it at all.
    if (!existing.isVerified) {
      await prisma.user.update({ where: { id: existing.id }, data: { isVerified: true } })
    }
    return { user: existing, plainPassword: null }
  }

  const mobileNumber = generateMobileNumber()
  const plainPassword = password ?? generatePassword()
  const user = await prisma.user.create({
    data: {
      mobileNumber,
      passwordHash: await hashPassword(plainPassword),
      accountType: 'CUSTOMER',
      fullName: 'Review Test Customer',
      isVerified: true,
      customerProfile: { create: {} },
    },
  })
  return { user, plainPassword }
}

/**
 * Reused across runs rather than recreated, so repeated seeding doesn't fill
 * the shared database with near-identical Hotels — the same reason the Halls
 * integration suites clean up after themselves.
 */
async function resolveHotelAndHall() {
  const existing = await prisma.hotel.findFirst({
    where: { deletedAt: null, status: 'APPROVED_ACTIVE', profileData: { path: ['name'], equals: HOTEL_NAME } },
    include: { halls: { where: { deletedAt: null }, take: 1 } },
  })
  if (existing?.halls.length) {
    return { hotel: existing, hall: existing.halls[0], reused: true }
  }

  const manager = await prisma.user.create({
    data: {
      mobileNumber: generateMobileNumber(),
      passwordHash: await hashPassword(generatePassword()),
      accountType: 'HOTEL_MANAGER',
      fullName: 'Review Test Manager',
      isVerified: true,
    },
  })
  const hotel = await prisma.hotel.create({
    data: {
      registeredByUserId: manager.id,
      status: 'APPROVED_ACTIVE',
      profileData: {
        name: HOTEL_NAME,
        description: 'Seeded Hotel used to exercise Ratings & Reviews by hand.',
        location: { latitude: 2.0469, longitude: 45.3182, address: 'Mogadishu' },
        contactPhone: '+15550001111',
      },
    },
  })
  const hall = await prisma.hall.create({
    data: {
      hotelId: hotel.id,
      profileData: { name: 'Review Test Hall', capacity: 100, description: 'Seeded Hall.' },
      rentAmountCents: 50000,
      rentDurationHours: 24,
      advancePaymentPercent: 30,
      customerServiceNumber: '+252610000001',
      paymentReceivingNumber: '+252610000002',
    },
  })
  return { hotel, hall, reused: false }
}

async function main() {
  const { mobile, password } = parseArgs(process.argv.slice(2))
  const { user, plainPassword } = await resolveCustomer({ mobile, password })
  const { hotel, hall, reused } = await resolveHotelAndHall()

  const endsAt = new Date(Date.now() - 86400000)
  const startsAt = new Date(endsAt.getTime() - 4 * 3600000)
  const totalRentCents = hall.rentAmountCents
  const requiredAdvanceCents = Math.round(totalRentCents * 0.3)

  const booking = await prisma.booking.create({
    data: {
      customerUserId: user.id,
      hotelId: hotel.id,
      hallId: hall.id,
      startsAt,
      endsAt,
      numberOfGuests: 20,
      eventType: 'WEDDING',
      status: 'COMPLETED',
      paymentStatus: 'PAID',
      paymentDeadlineAt: startsAt,
      totalRentCents,
      advancePercentSnapshot: 30,
      requiredAdvanceCents,
      reportedAmountCents: requiredAdvanceCents,
      paymentReportedAt: startsAt,
      paymentVerifiedAt: startsAt,
      completedAt: endsAt,
    },
  })

  console.log('Reviewable Booking created:')
  console.log(`  booking id:   ${booking.id}  (COMPLETED, PAID)`)
  console.log(`  hotel:        ${HOTEL_NAME} ${reused ? '(reused)' : '(created)'} — ${hotel.id}`)
  console.log(`  hall:         ${hall.id}`)
  console.log(`  customer:     ${user.mobileNumber}`)
  if (plainPassword) {
    console.log(`  password:     ${plainPassword}`)
    console.log('\nStore the password now — it is not recoverable from the database.')
  }
  console.log('\nOpen My Bookings as this Customer; the Booking offers "Leave a Review".')
}

main()
  .catch((err) => {
    console.error(err.message)
    process.exitCode = 1
  })
  .finally(() => prisma.$disconnect())
