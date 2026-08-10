-- CreateEnum
CREATE TYPE "hotel_status" AS ENUM ('REGISTERED', 'PROFILE_COMPLETE', 'UNDER_REVIEW', 'APPROVED_ACTIVE', 'REJECTED', 'WITHDRAWN', 'SUSPENDED', 'DEACTIVATED', 'RESTRICTED_UNDER_REVIEW');

-- CreateEnum
CREATE TYPE "hotel_application_status" AS ENUM ('OPEN', 'APPROVED', 'REJECTED', 'WITHDRAWN');

-- CreateEnum
CREATE TYPE "critical_change_status" AS ENUM ('PENDING', 'APPLIED', 'REJECTED');

-- CreateTable
CREATE TABLE "hotels" (
    "id" UUID NOT NULL,
    "registered_by_user_id" UUID NOT NULL,
    "status" "hotel_status" NOT NULL DEFAULT 'REGISTERED',
    "profile_data" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "hotels_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "hotel_applications" (
    "id" UUID NOT NULL,
    "hotel_id" UUID NOT NULL,
    "status" "hotel_application_status" NOT NULL DEFAULT 'OPEN',
    "decided_by_user_id" UUID,
    "decided_at" TIMESTAMP(3),
    "submitted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "hotel_applications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "critical_information_change_requests" (
    "id" UUID NOT NULL,
    "hotel_id" UUID NOT NULL,
    "status" "critical_change_status" NOT NULL DEFAULT 'PENDING',
    "proposed_data" JSONB NOT NULL,
    "decided_by_user_id" UUID,
    "decided_at" TIMESTAMP(3),
    "submitted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "critical_information_change_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_hotels_status" ON "hotels"("status");

-- CreateIndex
CREATE INDEX "idx_hotel_applications_hotel_id" ON "hotel_applications"("hotel_id");

-- CreateIndex
CREATE INDEX "idx_critical_information_change_requests_hotel_id" ON "critical_information_change_requests"("hotel_id");

-- AddForeignKey
ALTER TABLE "hotels" ADD CONSTRAINT "hotels_registered_by_user_id_fkey" FOREIGN KEY ("registered_by_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "hotel_applications" ADD CONSTRAINT "hotel_applications_hotel_id_fkey" FOREIGN KEY ("hotel_id") REFERENCES "hotels"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "hotel_applications" ADD CONSTRAINT "hotel_applications_decided_by_user_id_fkey" FOREIGN KEY ("decided_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "critical_information_change_requests" ADD CONSTRAINT "critical_information_change_requests_hotel_id_fkey" FOREIGN KEY ("hotel_id") REFERENCES "hotels"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "critical_information_change_requests" ADD CONSTRAINT "critical_information_change_requests_decided_by_user_id_fkey" FOREIGN KEY ("decided_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
