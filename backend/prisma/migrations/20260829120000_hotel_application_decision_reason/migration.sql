ALTER TABLE "hotel_applications" ADD COLUMN "decision_reason" TEXT;

CREATE UNIQUE INDEX "uq_hotel_applications_open_by_hotel"
ON "hotel_applications"("hotel_id")
WHERE "status" = 'OPEN';
