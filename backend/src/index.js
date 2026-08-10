import { createApp } from './app.js'
import { env } from './config/env.js'
import { logger } from './config/logger.js'
import { prisma } from './shared/prismaClient.js'

const app = createApp()

try {
  // A trivial round-trip query, not just $connect() — confirms the
  // database is actually reachable and answering, not merely that a
  // connection object was constructed.
  await prisma.$queryRaw`SELECT 1`
  logger.info('Database connected successfully.')
} catch (error) {
  logger.error('Database connection failed — the server will not start.', {
    message: error.message,
  })
  process.exit(1)
}

app.listen(env.port, () => {
  logger.info(`Backend workspace bootstrapped, listening on port ${env.port}`)
})
