/** Serializes all schedule writes for one Hall inside the caller's transaction. */
export function lockHallSchedule(hallId, client) {
  return client.$executeRawUnsafe('SELECT pg_advisory_xact_lock(hashtext($1))', hallId)
}
