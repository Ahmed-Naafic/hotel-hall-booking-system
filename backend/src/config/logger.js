import winston from 'winston'
import { env } from './env.js'

/**
 * Temporary diagnostic addition (2026-08-25): a file transport alongside
 * the existing Console one, so an error's full stack trace can be read
 * back from disk instead of depending on whoever's terminal the process
 * happens to be running in. Purely additive — Console output is
 * unchanged, nothing is hidden or redirected away from it.
 */
export const logger = winston.createLogger({
  level: env.nodeEnv === 'production' ? 'info' : 'debug',
  format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/backend.log' }),
  ],
})
