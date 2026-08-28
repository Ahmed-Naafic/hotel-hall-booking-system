import { randomBytes } from 'node:crypto'
import { prisma } from '../src/shared/prismaClient.js'
import { hashPassword } from '../src/modules/authentication/credential.service.js'

/**
 * One-off provisioning script for a Platform Administrator account.
 *
 * Per BR-AUTH-05 (backend/src/modules/authentication/authentication.validation.js),
 * Platform Administrator accounts are never self-registered through
 * /api/v1/auth/register — they must be provisioned directly. This is that
 * direct provisioning path for a real (e.g. Neon dev) database, mirroring
 * createPlatformAdministrator() in
 * backend/src/modules/hotels/__tests__/hotels.integration.test.js.
 *
 * Usage:
 *   node scripts/create-platform-admin.js [--mobile +15551234567] [--password "Some Password"]
 *
 * Both flags are optional — omitted values are generated and printed once.
 */

function parseArgs(argv) {
  const args = {}
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--mobile') args.mobile = argv[++i]
    if (argv[i] === '--password') args.password = argv[++i]
  }
  return args
}

function generateMobileNumber() {
  const digits = randomBytes(6).toString('hex').slice(0, 9).replace(/^0/, '1')
  return `+1${digits}`
}

function generatePassword() {
  return randomBytes(18).toString('base64url')
}

async function main() {
  const { mobile, password } = parseArgs(process.argv.slice(2))

  const mobileNumber = mobile ?? generateMobileNumber()
  const plainPassword = password ?? generatePassword()

  const existing = await prisma.user.findUnique({ where: { mobileNumber } })
  if (existing) {
    throw new Error(`A user with mobileNumber ${mobileNumber} already exists (id: ${existing.id}).`)
  }

  const passwordHash = await hashPassword(plainPassword)

  const admin = await prisma.user.create({
    data: {
      mobileNumber,
      passwordHash,
      accountType: 'PLATFORM_ADMINISTRATOR',
      isVerified: true,
    },
  })

  console.log('Platform Administrator account created:')
  console.log(`  id:           ${admin.id}`)
  console.log(`  mobileNumber: ${mobileNumber}`)
  console.log(`  password:     ${plainPassword}`)
  console.log('\nStore the password now — it is not recoverable from the database.')
}

main()
  .catch((err) => {
    console.error(err.message)
    process.exitCode = 1
  })
  .finally(() => prisma.$disconnect())
