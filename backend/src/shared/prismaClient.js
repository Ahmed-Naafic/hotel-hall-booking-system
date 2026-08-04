import { PrismaPg } from '@prisma/adapter-pg'
import { PrismaClient } from '../generated/prisma/client.ts'
import { env } from '../config/env.js'

/**
 * The single Prisma Client instance for the whole backend process. Only
 * repository files import this (coding-standards.md §5, "the only place
 * Prisma Client is called") — a service never imports it directly.
 *
 * Prisma 7's client generator requires an explicit driver adapter
 * (@prisma/adapter-pg for PostgreSQL, per technology-stack.md) rather than
 * connecting from the datasource URL alone.
 */
const adapter = new PrismaPg({ connectionString: env.databaseUrl })

export const prisma = new PrismaClient({ adapter })
