import dotenv from 'dotenv'

dotenv.config()

function required(name) {
  const value = process.env[name]
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`)
  }
  return value
}

export const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: process.env.PORT || 3000,
  databaseUrl: required('DATABASE_URL'),

  auth: {
    jwtSecret: required('JWT_SECRET'),
    jwtRefreshSecret: required('JWT_REFRESH_SECRET'),

    // Session Validity Duration is Business Specification Pending Business
    // Decision #3 (docs/04-business/modules/01-authentication-and-account-management/business-specification.md
    // §10) — not yet a settled business rule. These are development
    // defaults, overridable via environment variables, not a business
    // decision made here (Technical Design §9, §17 Item 5).
    accessTokenTtlMinutes: Number(process.env.ACCESS_TOKEN_TTL_MINUTES || 15),
    refreshTokenTtlDays: Number(process.env.REFRESH_TOKEN_TTL_DAYS || 7),

    // Argon2id parameters — OWASP Password Storage Cheat Sheet baseline
    // (Technical Design §11: "tuned ... against OWASP's published baseline
    // guidance"). Revisit once real hosting hardware is known
    // (Project-Overview.md §13 — hosting remains TBD).
    argon2: {
      memoryCost: Number(process.env.ARGON2_MEMORY_COST_KIB || 19456),
      timeCost: Number(process.env.ARGON2_TIME_COST || 2),
      parallelism: Number(process.env.ARGON2_PARALLELISM || 1),
    },
  },
}
