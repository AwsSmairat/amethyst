import * as service from '../services/stationSale.service.js';
import { success, paginated } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const list = asyncHandler(async (req, res) => {
  const result = await service.listStationSales(req.query, req.user);
  return paginated(res, result);
});

export const getById = asyncHandler(async (req, res) => {
  const sale = await service.getStationSaleById(req.params.id, req.user);
  return success(res, sale);
});

export const create = asyncHandler(async (req, res) => {
  const sale = await service.createStationSale(req.body, req.user);
  return success(res, sale, 'Station sale recorded', 201);
});

export const dailySummary = asyncHandler(async (req, res) => {
  const data = await service.summaryDaily(req.query, req.user);
  return success(res, data);
});

export const monthlySummary = asyncHandler(async (req, res) => {
  const data = await service.summaryMonthly(req.query, req.user);
  return success(res, data);
});
