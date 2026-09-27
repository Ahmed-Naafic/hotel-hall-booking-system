-- Local-first synchronisation, Phase 0 / S-04.
--
-- A sync scan is `WHERE <tenant predicate> AND sync_seq > :mark ORDER BY
-- sync_seq ASC LIMIT n`. Without an index leading with the tenant column
-- and ending in `sync_seq`, that is a sequential scan plus a sort on every
-- poll from every device — the cost grows with the table, not with how much
-- actually changed, which defeats the point of incremental sync.
--
-- The tenant column in each index is the scope predicate that endpoint will
-- actually use, taken from the repository functions that already enforce
-- ownership today (`findForCustomer`, `findForHotel`, `findByIdForUser`,
-- `findByIdForHotel`) rather than invented here.
--
-- `hotels` and `halls` get a bare `(sync_seq)` index as well: the public
-- marketplace scan has no tenant column, only the visibility predicate.
--
-- Plain CREATE INDEX, not CONCURRENTLY: Prisma runs a migration inside a
-- transaction and CONCURRENTLY cannot, and the largest table here is
-- roughly 4,000 rows, so the lock is momentary. At a volume where that
-- stopped being true these would move to a manual, concurrent build.

-- Public marketplace scans (no tenant column).
CREATE INDEX IF NOT EXISTS "idx_hotels_sync_seq" ON "hotels" ("sync_seq");
CREATE INDEX IF NOT EXISTS "idx_halls_sync_seq" ON "halls" ("sync_seq");

-- Hotel Manager scope: own Hotel, and everything hanging off it.
CREATE INDEX IF NOT EXISTS "idx_hotels_registered_by_sync_seq" ON "hotels" ("registered_by_user_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_halls_hotel_sync_seq" ON "halls" ("hotel_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_hotel_media_hotel_sync_seq" ON "hotel_media" ("hotel_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_hall_media_hall_sync_seq" ON "hall_media" ("hall_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_hall_blocks_hall_sync_seq" ON "hall_availability_blocks" ("hall_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_bookings_hotel_sync_seq" ON "bookings" ("hotel_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_hotel_applications_hotel_sync_seq" ON "hotel_applications" ("hotel_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_critical_changes_hotel_sync_seq" ON "critical_information_change_requests" ("hotel_id", "sync_seq");

-- Customer scope: own records only.
CREATE INDEX IF NOT EXISTS "idx_bookings_customer_sync_seq" ON "bookings" ("customer_user_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_notifications_recipient_sync_seq" ON "notifications" ("recipient_user_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_saved_hotels_customer_sync_seq" ON "saved_hotels" ("customer_user_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_customer_profiles_user_sync_seq" ON "customer_profiles" ("user_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_chat_messages_booking_sync_seq" ON "chat_messages" ("booking_id", "sync_seq");

-- Reviews are read per Hotel publicly, and per Customer privately.
CREATE INDEX IF NOT EXISTS "idx_reviews_hotel_sync_seq" ON "reviews" ("hotel_id", "sync_seq");
CREATE INDEX IF NOT EXISTS "idx_reviews_customer_sync_seq" ON "reviews" ("customer_user_id", "sync_seq");
