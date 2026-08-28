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

    // Verification/reset code validity windows — Business Specification
    // Pending Business Decision #2 (Mobile Number Verification Method,
    // §10) covers the code format/window; not yet settled. Development
    // defaults only, per the same pattern as the TTLs above.
    verificationCodeTtlMinutes: Number(process.env.VERIFICATION_CODE_TTL_MINUTES || 10),
    passwordResetCodeTtlMinutes: Number(process.env.PASSWORD_RESET_CODE_TTL_MINUTES || 30),

    // Explicit, opt-in dev/test convenience only — set
    // DEV_FIXED_VERIFICATION_CODE to receive the same 6-digit code every
    // time instead of a random one, so manual testing doesn't require
    // pulling the code out of the mock SMS provider by hand. Only ever
    // takes effect while MockSmsProvider is in use (no Twilio credentials
    // configured), and only for account verification (C3) — never password
    // reset, whose token is hashed into a globally-unique column
    // (PasswordResetRequest.tokenHash) a fixed value would collide against;
    // see verification.service.js. Unset, or once real Twilio credentials
    // are added, behavior reverts to a random code automatically; never a
    // production concern.
    devFixedVerificationCode: process.env.DEV_FIXED_VERIFICATION_CODE || undefined,
  },

  // SMS delivery (Twilio, ADR-0005) — intentionally NOT read via required().
  // Absent credentials are an expected, valid local-development state
  // (shared/providers/smsProvider.js falls back to MockSmsProvider); never
  // hardcode a placeholder value here.
  sms: {
    twilio: {
      accountSid: process.env.TWILIO_ACCOUNT_SID || undefined,
      authToken: process.env.TWILIO_AUTH_TOKEN || undefined,
      fromNumber: process.env.TWILIO_FROM_NUMBER || undefined,
    },
  },

  // Storage (Supabase, ADR-0006) — intentionally NOT read via required().
  // Absent credentials are an expected, valid local-development state
  // (shared/providers/storageProvider.js falls back to MockStorageProvider,
  // the same pattern sms.twilio above already uses); never hardcode a
  // placeholder value here. The service-role key is never sent to any
  // client (Technical Design §12) — read only here, used only server-side.
  storage: {
    supabase: {
      url: process.env.SUPABASE_URL || undefined,
      serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || undefined,
      bucket: process.env.SUPABASE_STORAGE_BUCKET || 'hotel-media',
    },
  },

  // CORS — Admin Web (BDR-007) is the only approved browser client; the
  // Flutter apps don't go through a browser, so CORS doesn't apply to them.
  // Comma-separated explicit origin allowlist, e.g.
  // "https://admin.example.com". In development, any http://localhost:*
  // origin is allowed instead (Vite picks a free port per run, so pinning
  // one exact dev port is brittle) — this is not a decision to loosen
  // security, only to keep local development workable.
  cors: {
    allowedOrigins: (process.env.ADMIN_WEB_ORIGINS || '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
  },
}
