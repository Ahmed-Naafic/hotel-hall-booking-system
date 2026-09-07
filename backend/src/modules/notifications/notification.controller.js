import * as service from './notification.service.js'
import { toNotification } from './notification.mapper.js'
import { sendSuccess, sendNoContent } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

const limitOf = (req) => Math.min(Number(req.query.limit ?? 20), 100)

export const list = asyncHandler(async (req, res) => {
  const limit = limitOf(req)
  const result = await service.listForUser({
    recipientUserId: req.identity.userId,
    status: req.query.status,
    cursor: req.query.cursor,
    limit,
  })
  sendSuccess(res, {
    message: 'Notifications retrieved successfully.',
    data: result.notifications.map(toNotification),
    pagination: { limit, hasNext: result.hasNext, nextCursor: result.nextCursor },
  })
})

export const unreadCount = asyncHandler(async (req, res) => {
  const count = await service.unreadCountForUser(req.identity.userId)
  sendSuccess(res, { message: 'Unread notification count retrieved successfully.', data: { count } })
})

export const markRead = asyncHandler(async (req, res) => {
  const notification = await service.markRead({ id: req.params.id, recipientUserId: req.identity.userId })
  sendSuccess(res, { message: 'Notification marked as read.', data: toNotification(notification) })
})

export const markAllRead = asyncHandler(async (req, res) => {
  await service.markAllRead(req.identity.userId)
  sendSuccess(res, { message: 'All notifications marked as read.', data: null })
})

export const registerDeviceToken = asyncHandler(async (req, res) => {
  await service.registerDeviceToken({ userId: req.identity.userId, token: req.body.token, platform: req.body.platform })
  sendSuccess(res, { statusCode: 200, message: 'Device token registered successfully.', data: null })
})

export const unregisterDeviceToken = asyncHandler(async (req, res) => {
  await service.unregisterDeviceToken(req.query.token)
  sendNoContent(res)
})
