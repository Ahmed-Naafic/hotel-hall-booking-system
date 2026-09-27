import * as service from './sync.service.js'
import * as mapper from './sync.mapper.js'
import { sendSuccess } from '../../shared/utils/responseEnvelope.js'
import { asyncHandler } from '../../shared/utils/asyncHandler.js'

export const changes = asyncHandler(async (req, res) => {
  const result = await service.changes({
    identity: req.identity,
    collection: req.params.collection,
    cursor: req.syncCursor,
    limit: req.syncLimit,
  })

  sendSuccess(res, {
    message: 'Changes retrieved successfully.',
    data: mapper.toSyncData(result),
    pagination: result.pagination,
  })
})
