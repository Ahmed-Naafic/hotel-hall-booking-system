ALTER TABLE "halls"
  ADD COLUMN "rent_amount_cents" INTEGER,
  ADD COLUMN "rent_duration_hours" INTEGER DEFAULT 24,
  ADD COLUMN "advance_payment_percent" DECIMAL(5,2),
  ADD COLUMN "customer_service_number" TEXT,
  ADD COLUMN "payment_receiving_number" TEXT;

CREATE TYPE "event_type" AS ENUM ('WEDDING', 'CONFERENCE', 'BIRTHDAY', 'MEETING', 'GRADUATION', 'OTHER');
CREATE TYPE "booking_status" AS ENUM ('PENDING', 'CONFIRMED', 'REJECTED', 'CANCELLED', 'COMPLETED', 'NO_SHOW', 'EXPIRED');
CREATE TYPE "payment_status" AS ENUM ('UNPAID', 'CUSTOMER_REPORTED', 'PAID', 'REJECTED');

CREATE TABLE "bookings" (
  "id" UUID NOT NULL,
  "customer_user_id" UUID NOT NULL,
  "hotel_id" UUID NOT NULL,
  "hall_id" UUID NOT NULL,
  "starts_at" TIMESTAMP(3) NOT NULL,
  "ends_at" TIMESTAMP(3) NOT NULL,
  "number_of_guests" INTEGER NOT NULL,
  "event_type" "event_type" NOT NULL,
  "special_request" TEXT,
  "status" "booking_status" NOT NULL DEFAULT 'PENDING',
  "payment_status" "payment_status" NOT NULL DEFAULT 'UNPAID',
  "payment_deadline_at" TIMESTAMP(3) NOT NULL,
  "total_rent_cents" INTEGER NOT NULL,
  "advance_percent_snapshot" DECIMAL(5,2) NOT NULL,
  "required_advance_cents" INTEGER NOT NULL,
  "reported_amount_cents" INTEGER,
  "payment_reported_at" TIMESTAMP(3),
  "payment_verified_at" TIMESTAMP(3),
  "payment_verified_by_id" UUID,
  "payment_rejection_reason" TEXT,
  "cancelled_at" TIMESTAMP(3),
  "cancelled_by_user_id" UUID,
  "completed_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "bookings_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "bookings_guests_positive" CHECK ("number_of_guests" > 0),
  CONSTRAINT "bookings_period_valid" CHECK ("ends_at" > "starts_at"),
  CONSTRAINT "bookings_amounts_valid" CHECK ("total_rent_cents" > 0 AND "required_advance_cents" >= 0)
);

CREATE INDEX "idx_bookings_customer_created_at" ON "bookings"("customer_user_id", "created_at");
CREATE INDEX "idx_bookings_hotel_status_created_at" ON "bookings"("hotel_id", "status", "created_at");
CREATE INDEX "idx_bookings_hall_period" ON "bookings"("hall_id", "starts_at", "ends_at");
CREATE INDEX "idx_bookings_status_payment_deadline" ON "bookings"("status", "payment_deadline_at");
CREATE INDEX "idx_bookings_payment_status" ON "bookings"("payment_status");

ALTER TABLE "bookings" ADD CONSTRAINT "bookings_customer_user_id_fkey" FOREIGN KEY ("customer_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_hotel_id_fkey" FOREIGN KEY ("hotel_id") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_hall_id_fkey" FOREIGN KEY ("hall_id") REFERENCES "halls"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_payment_verified_by_id_fkey" FOREIGN KEY ("payment_verified_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_cancelled_by_user_id_fkey" FOREIGN KEY ("cancelled_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_no_blocking_overlap"
  EXCLUDE USING gist (
    "hall_id" WITH =,
    tsrange("starts_at", "ends_at", '[)') WITH &&
  ) WHERE ("status" IN ('PENDING', 'CONFIRMED'));
