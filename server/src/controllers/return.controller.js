import * as service from '../services/return.service.js';
import { success, paginated } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const list = asyncHandler(async (req, res) => {
  const result = await service.listReturns(req.query, req.user);
  return paginated(res, result);
});

export const getById = asyncHandler(async (req, res) => {
  const row = await service.getReturnById(req.params.id, req.user);
  return success(res, row);
});

export const create = asyncHandler(async (req, res) => {
  const row = await service.recordReturn(req.body, req.user);
  return success(res, row, 'Return recorded', 201);
});
