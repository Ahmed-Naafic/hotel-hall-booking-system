/**
 * Test-only environment override, preloaded via `node --test --import
 * ./scripts/testEnv.js` (package.json's `test` script) — runs before any
 * test file (and therefore before `config/env.js`'s own `dotenv.config()`
 * call) is imported.
 *
 * The same `backend/.env` this override runs alongside also carries real
 * Supabase credentials, used when running the actual dev server for manual
 * device testing of Hotel/Hall media uploads. Without this override, the
 * automated test suite would inherit those same credentials, and
 * `shared/providers/storageProvider.js#selectProvider` — which chooses
 * `SupabaseStorageProvider` over `MockStorageProvider` purely based on
 * whether `SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY` are present — would
 * select the real provider for every test run. That means every test run
 * would both hit a real external service (never appropriate for an
 * automated test, testing-standards.md §6) and silently break any test that
 * exercises `MockStorageProvider`-only behavior (`failNextUpload()`, its
 * in-memory `objects` map) with a `TypeError`, since `SupabaseStorageProvider`
 * has neither.
 *
 * Setting (not deleting) these to `''` is deliberate: `dotenv.config()`
 * only fills in variables that are not already present in `process.env`, so
 * an explicit empty string here is preserved rather than being re-populated
 * from `.env` a moment later. `env.js` already treats an empty value as
 * absent (`process.env.SUPABASE_URL || undefined`), so this reliably forces
 * `MockStorageProvider` for the whole test run without touching `.env`
 * itself or affecting the real dev server in any way.
 */
process.env.SUPABASE_URL = ''
process.env.SUPABASE_SERVICE_ROLE_KEY = ''
process.env.SUPABASE_STORAGE_BUCKET = ''

// Same reasoning, applied pre-emptively to Firebase Cloud Messaging
// (Notification Management, Module 10) — no real credentials exist yet,
// but forcing MockPushProvider here now means a future developer adding
// real FIREBASE_* values to `.env` for manual device testing does not
// silently flip the automated test suite over to real push delivery later.
process.env.FIREBASE_PROJECT_ID = ''
process.env.FIREBASE_CLIENT_EMAIL = ''
process.env.FIREBASE_PRIVATE_KEY = ''
