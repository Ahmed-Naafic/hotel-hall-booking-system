import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import express from 'express'
import swaggerUi from 'swagger-ui-express'
import { requestId } from './shared/middleware/requestId.js'
import { corsPolicy } from './shared/middleware/corsPolicy.js'
import { notFoundHandler } from './shared/middleware/notFoundHandler.js'
import { errorHandler } from './shared/middleware/errorHandler.js'
import { authenticationRouter } from './modules/authentication/authentication.routes.js'
import { hotelRouter } from './modules/hotels/hotel.routes.js'
import { hotelMediaRouter } from './modules/hotels/media.routes.js'
import { hallMediaRouter } from './modules/halls/media.routes.js'
import { hallRouter, hotelHallsRouter } from './modules/halls/hall.routes.js'
import { hallAvailabilityRouter, publicHallAvailabilityRouter } from './modules/availability/availability.routes.js'
import { administrationRouter } from './modules/administration/administration.routes.js'
import { customerRouter } from './modules/customers/customer.routes.js'
import { bookingRouter, hotelBookingRouter } from './modules/bookings/booking.routes.js'
import { favoriteRouter } from './modules/favorites/favorite.routes.js'
import { bookingReviewRouter, hotelReviewRouter } from './modules/reviews/review.routes.js'

const openapiSpecPath = fileURLToPath(new URL('./openapi/openapi.json', import.meta.url))
const openapiSpec = JSON.parse(readFileSync(openapiSpecPath, 'utf-8'))

/**
 * The Express app, separate from the listener (index.js) so integration
 * tests can import and exercise it on an ephemeral port
 * (testing-standards.md §6) without touching the configured PORT.
 */
export function createApp() {
  const app = express()

  app.use(requestId)
  app.use(corsPolicy)
  app.use(express.json())

  // Feature-based modules, mounted under the versioned API prefix
  // (api-standards.md §3). One line per module as each is implemented.
  app.use('/api/v1/auth', authenticationRouter)
  app.use('/api/v1/customers', customerRouter)
  app.use('/api/v1/bookings/:bookingId/review', bookingReviewRouter)
  app.use('/api/v1/bookings', bookingRouter)
  app.use('/api/v1/hotels/:hotelId/bookings', hotelBookingRouter)
  app.use('/api/v1/favorites', favoriteRouter)
  app.use('/api/v1/hotels/:hotelId/reviews', hotelReviewRouter)
  app.use('/api/v1/hotels', hotelRouter)
  app.use('/api/v1/hotels/:hotelId/media', hotelMediaRouter)
  app.use('/api/v1/hotels/:hotelId/halls/:hallId/media', hallMediaRouter)
  app.use('/api/v1/hotels/:hotelId/halls/:hallId/availability', hallAvailabilityRouter)
  app.use('/api/v1/hotels/:hotelId/halls', hotelHallsRouter)
  app.use('/api/v1/halls/:hallId/availability', publicHallAvailabilityRouter)
  app.use('/api/v1/halls', hallRouter)
  app.use('/api/v1/admin', administrationRouter)

  // OpenAPI/Swagger documentation (technology-stack.md, api-standards.md §16) —
  // a tooling/meta endpoint, unversioned like the health check pattern
  // system-architecture-overview.md §14 describes.
  app.use('/docs', swaggerUi.serve, swaggerUi.setup(openapiSpec))
  app.get('/openapi.json', (req, res) => res.json(openapiSpec))

  app.use(notFoundHandler)
  app.use(errorHandler)

  return app
}
