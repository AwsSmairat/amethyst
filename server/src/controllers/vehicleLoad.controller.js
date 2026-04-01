import * as service from '../services/vehicleLoad.service.js';
import { success, paginated } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const list = asyncHandler(async (req, res) => {
  const result = await service.listVehicleLoads(req.query, req.user);
  return paginated(res, result);
});

export const getById = asyncHandler(async (req, res) => {
  const load = await service.getVehicleLoadById(req.params.id, req.user);
  return success(res, load);
});

export const create = asyncHandler(async (req, res) => {
  const load = await service.createVehicleLoad(req.body, req.user);
  return success(res, load, 'Vehicle load created', 201);
});

export const update = asyncHandler(async (req, res) => {
  const load = await service.updateVehicleLoad(req.params.id, req.body, req.user);
  return success(res, load, 'Vehicle load updated');
});

export const close = asyncHandler(async (req, res) => {
  const load = await service.closeVehicleLoad(req.params.id, req.user);
  return success(res, load, 'Load closed');
});

export const driverCurrent = asyncHandler(async (req, res) => {
  const data = await service.getDriverCurrentLoads(req.user);
  return success(res, data);
});
