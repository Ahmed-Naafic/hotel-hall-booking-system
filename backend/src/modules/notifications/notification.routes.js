import { Router } from 'express'
import * as controller from './notification.controller.js'
import * as validation from './notification.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'

/**
 * A Notification's scope is the caller's own identity, not a role-gated
 * capability (Business Specification "Recipients") — every account type
 * (Customer, Hotel Manager, Platform Administrator) uses these same routes,
 * so only `authenticate` applies here, never `requireAccountType`.
 *
 * `DELETE /device-tokens` takes `token` as a query parameter rather than a
 * URL path segment or a request body — an FCM token's character set is not
 * guaranteed URL-path-safe (a query parameter is always correctly
 * percent-encoded), and the shared Flutter `ApiClient.delete()` does not
 * support a request body.
 */
export const notificationRouter = Router()
notificationRouter.use(authenticate)

notificationRouter.get('/', validation.validateList, controller.list)
notificationRouter.get('/unread-count', controller.unreadCount)
notificationRouter.post('/read-all', controller.markAllRead)
notificationRouter.post('/:id/read', controller.markRead)
notificationRouter.put('/device-tokens', validation.validateDeviceToken, controller.registerDeviceToken)
notificationRouter.delete('/device-tokens', validation.validateDeviceTokenQuery, controller.unregisterDeviceToken)
