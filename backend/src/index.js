import express from 'express'
import { env } from './config/env.js'
import { logger } from './config/logger.js'

const app = express()

app.use(express.json())

app.listen(env.port, () => {
  logger.info(`Backend workspace bootstrapped, listening on port ${env.port}`)
})
