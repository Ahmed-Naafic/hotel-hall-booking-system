import * as service from './chat.service.js'
import { toChatMessage } from './chat.mapper.js'
import { sendSuccess } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

const limitOf = (req) => Math.min(Number(req.query.limit ?? 20), 100)

export const send = asyncHandler(async (req, res) => {
  const message = await service.sendMessage({
    bookingId: req.params.bookingId,
    senderUserId: req.identity.userId,
    body: req.body.body.trim(),
  })
  sendSuccess(res, { statusCode: 201, message: 'Message sent successfully.', data: toChatMessage(message) })
})

export const list = asyncHandler(async (req, res) => {
  const limit = limitOf(req)
  const result = await service.listForBooking({
    bookingId: req.params.bookingId,
    userId: req.identity.userId,
    cursor: req.query.cursor,
    limit,
  })
  sendSuccess(res, {
    message: 'Messages retrieved successfully.',
    data: result.messages.map(toChatMessage),
    pagination: { limit, hasNext: result.hasNext, nextCursor: result.nextCursor },
  })
})

export const markConversationRead = asyncHandler(async (req, res) => {
  await service.markConversationRead({ bookingId: req.params.bookingId, userId: req.identity.userId })
  sendSuccess(res, { message: 'Conversation marked as read.', data: null })
})

export const unreadCount = asyncHandler(async (req, res) => {
  const count = await service.unreadCountForUser(req.identity.userId)
  sendSuccess(res, { message: 'Unread message count retrieved successfully.', data: { count } })
})
