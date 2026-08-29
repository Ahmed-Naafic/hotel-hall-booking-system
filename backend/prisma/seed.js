import 'dotenv/config'
import argon2 from 'argon2'
import { PrismaPg } from '@prisma/adapter-pg'
import { PrismaClient } from '../src/generated/prisma/client.ts'

const mobileNumber = process.env.ADMIN_MOBILE_NUMBER?.trim()
const password = process.env.ADMIN_PASSWORD
const databaseUrl = process.env.DATABASE_URL

if (!mobileNumber) {
  throw new Error('Missing required environment variable: ADMIN_MOBILE_NUMBER')
}

if (!password) {
  throw new Error('Missing required environment variable: ADMIN_PASSWORD')
}

if (!databaseUrl) {
  throw new Error('Missing required environment variable: DATABASE_URL')
}

const adapter = new PrismaPg({ connectionString: databaseUrl })
const prisma = new PrismaClient({ adapter })

try {
  const passwordHash = await argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: Number(process.env.ARGON2_MEMORY_COST_KIB || 19456),
    timeCost: Number(process.env.ARGON2_TIME_COST || 2),
    parallelism: Number(process.env.ARGON2_PARALLELISM || 1),
  })

  await prisma.user.upsert({
    where: { mobileNumber },
    create: {
      mobileNumber,
      passwordHash,
      accountType: 'PLATFORM_ADMINISTRATOR',
      isVerified: true,
      isActive: true,
    },
    update: {
      passwordHash,
      accountType: 'PLATFORM_ADMINISTRATOR',
      isVerified: true,
      isActive: true,
      deletedAt: null,
    },
  })

  console.log(`Platform administrator seeded for ${mobileNumber}`)
} finally {
  await prisma.$disconnect()
}
