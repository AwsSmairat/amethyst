import * as service from '../services/reports.service.js';
import { success } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const salesDaily = asyncHandler(async (req, res) => {
  const data = await service.salesDaily(req.query, req.user);
  return success(res, data);
});

export const salesMonthly = asyncHandler(async (req, res) => {
  const data = await service.salesMonthly(req.query, req.user);
  return success(res, data);
});

export const salesWorkingDays = asyncHandler(async (req, res) => {
  const data = await service.salesWorkingDays(req.user);
  return success(res, data);
});

export const vehicles = asyncHandler(async (req, res) => {
  const data = await service.vehiclesReport(req.query, req.user);
  return success(res, data);
});

export const drivers = asyncHandler(async (req, res) => {
  const data = await service.driversReport(req.query, req.user);
  return success(res, data);
});

export const inventory = asyncHandler(async (req, res) => {
  const data = await service.inventoryReport(req.user);
  return success(res, data);
});

export const expenses = asyncHandler(async (req, res) => {
  const data = await service.expensesReport(req.query, req.user);
  return success(res, data);
});

export const profitLoss = asyncHandler(async (req, res) => {
  const data = await service.profitLossReport(req.query, req.user);
  return success(res, data);
});
