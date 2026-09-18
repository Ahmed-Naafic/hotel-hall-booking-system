-- AlterEnum
ALTER TYPE "notification_type" ADD VALUE 'NEW_CHAT_MESSAGE';

-- CreateTable
CREATE TABLE "chat_messages" (
    "id" UUID NOT NULL,
    "booking_id" UUID NOT NULL,
    "sender_user_id" UUID NOT NULL,
    "body" TEXT NOT NULL,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_chat_messages_booking_created_at" ON "chat_messages"("booking_id", "created_at");

-- CreateIndex
CREATE INDEX "idx_chat_messages_unread_lookup" ON "chat_messages"("booking_id", "sender_user_id", "read_at");

-- AddForeignKey
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_sender_user_id_fkey" FOREIGN KEY ("sender_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
