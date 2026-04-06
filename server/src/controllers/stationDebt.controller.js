import * as service from '../services/stationDebt.service.js';
import { success, paginated } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const create = asyncHandler(async (req, res) => {
  const result = await service.createStationDebtEntries(req.body, req.user);
  return success(res, result, 'Station debt entries recorded', 201);
});

export const list = asyncHandler(async (req, res) => {
  const result = await service.listStationDebtEntries(req.query, req.user);
  return paginated(res, result);
});

export const repay = asyncHandler(async (req, res) => {
  const result = await service.repayStationDebtForDebtor(req.body, req.user);
  return success(res, result, 'Debt repaid', 200);
});
