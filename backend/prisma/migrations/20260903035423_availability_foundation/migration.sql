-- CreateTable
CREATE TABLE "hall_availability_blocks" (
    "id" UUID NOT NULL,
    "hall_id" UUID NOT NULL,
    "starts_at" TIMESTAMP(3) NOT NULL,
    "ends_at" TIMESTAMP(3) NOT NULL,
    "reason" TEXT,
    "created_by_user_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "hall_availability_blocks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_hall_availability_blocks_hall_starts_at" ON "hall_availability_blocks"("hall_id", "starts_at");

-- AddForeignKey
ALTER TABLE "hall_availability_blocks" ADD CONSTRAINT "hall_availability_blocks_hall_id_fkey" FOREIGN KEY ("hall_id") REFERENCES "halls"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "hall_availability_blocks" ADD CONSTRAINT "hall_availability_blocks_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Approved Technical Design (Availability & Calendar V1), decision 2: the
-- authoritative anti-overlap guarantee, immune to application-level races.
-- btree_gist supplies the GiST operator class needed for the equality
-- comparison on "hall_id" (a non-range column) inside a GiST index that
-- also compares ranges via "&&". Additive only — enables an extension and
-- adds one constraint, alters no existing table.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ExcludeConstraint
ALTER TABLE "hall_availability_blocks" ADD CONSTRAINT "hall_availability_blocks_no_overlap"
  EXCLUDE USING gist (
    "hall_id" WITH =,
    tsrange("starts_at", "ends_at", '[)') WITH &&
  );
