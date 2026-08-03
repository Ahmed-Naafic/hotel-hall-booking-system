import express from 'express'
import { requestId } from './shared/middleware/requestId.js'
import { notFoundHandler } from './shared/middleware/notFoundHandler.js'
import { errorHandler } from './shared/middleware/errorHandler.js'
import { authenticationRouter } from './modules/authentication/authentication.routes.js'

/**
 * The Express app, separate from the listener (index.js) so integration
 * tests can import and exercise it on an ephemeral port
 * (testing-standards.md §6) without touching the configured PORT.
 */
export function createApp() {
  const app = express()

  app.use(requestId)
  app.use(express.json())

  // Feature-based modules, mounted under the versioned API prefix
  // (api-standards.md §3). One line per module as each is implemented.
  app.use('/api/v1/auth', authenticationRouter)

  app.use(notFoundHandler)
  app.use(errorHandler)

  return app
}
