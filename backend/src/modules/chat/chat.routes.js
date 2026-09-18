import { Router } from 'express'
import * as controller from './chat.controller.js'
import * as validation from './chat.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'

/**
 * A conversation's scope is "whichever of Customer/Hotel Manager this
 * Booking says", not a role-gated capability (Business Specification
 * "Recipients / Participants") — only `authenticate` applies here, never
 * `requireAccountType`, the same shape Notification V1's own routes use.
 * `chat.service.js#assertParticipant` (not this router) is what actually
 * enforces who may touch a given Booking's conversation.
 */
export const bookingMessagesRouter = Router({ mergeParams: true })
bookingMessagesRouter.use(authenticate)
bookingMessagesRouter.get('/', validation.validateList, controller.list)
bookingMessagesRouter.post('/', validation.validateSendMessage, controller.send)
bookingMessagesRouter.post('/read-all', controller.markConversationRead)

export const messagesRouter = Router()
messagesRouter.use(authenticate)
messagesRouter.get('/unread-count', controller.unreadCount)
