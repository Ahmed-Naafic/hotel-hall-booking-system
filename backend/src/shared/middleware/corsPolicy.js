import cors from 'cors'
import { env } from '../../config/env.js'

const LOCALHOST_ORIGIN_PATTERN = /^http:\/\/localhost:\d+$/

/**
 * CORS policy for Admin Web (BDR-007) — the only approved browser client
 * (api-standards.md doesn't define one; this is a Technical Decision within
 * already-approved architecture, per Decision-Making-Principles.md §3, not
 * an architecture change). The Flutter apps never go through a browser, so
 * this middleware has no effect on them.
 */
export const corsPolicy = cors({
  origin(requestOrigin, callback) {
    if (!requestOrigin) {
      // Same-origin requests (curl, server-to-server, tests) carry no
      // Origin header at all — never subject to CORS in the first place.
      callback(null, true)
      return
    }
    const isAllowed =
      env.cors.allowedOrigins.includes(requestOrigin) ||
      (env.nodeEnv !== 'production' && LOCALHOST_ORIGIN_PATTERN.test(requestOrigin))
    callback(null, isAllowed)
  },
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
})
