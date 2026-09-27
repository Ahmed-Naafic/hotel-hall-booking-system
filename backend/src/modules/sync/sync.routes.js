import { Router } from 'express'
import * as syncController from './sync.controller.js'
import * as syncValidation from './sync.validation.js'
import { authenticate } from '../../shared/middleware/authenticate.js'

/**
 * Route definitions only (coding-standards.md §5). Mounted at /api/v1/sync.
 *
 * One route, and the collection is a path parameter validated against an
 * explicit allowlist — never a table name the caller chooses. Authentication is
 * unconditional: every Phase 1 collection is private. Public collections are
 * Phase 3 and will need `optionalAuthenticate`, which is deliberately not wired
 * here so no private collection can be reached anonymously today.
 */
export const syncRouter = Router()

syncRouter.get(
  '/:collection',
  authenticate,
  syncValidation.validateChanges,
  syncController.changes,
)
