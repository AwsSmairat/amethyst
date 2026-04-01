import * as vehicleService from '../services/vehicle.service.js';
import { success, paginated } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const list = asyncHandler(async (req, res) => {
  const result = await vehicleService.listVehicles(req.query, req.user);
  return paginated(res, result);
});

export const getById = asyncHandler(async (req, res) => {
  const v = await vehicleService.getVehicleById(req.params.id, req.user);
  return success(res, v);
});

export const create = asyncHandler(async (req, res) => {
  const v = await vehicleService.createVehicle(req.body, req.user);
  return success(res, v, 'Vehicle created', 201);
});

export const update = asyncHandler(async (req, res) => {
  const v = await vehicleService.updateVehicle(req.params.id, req.body, req.user);
  return success(res, v, 'Vehicle updated');
});

export const remove = asyncHandler(async (req, res) => {
  const r = await vehicleService.deleteVehicle(req.params.id, req.user);
  return success(res, r, 'Vehicle deleted');
});

export const assignDriver = asyncHandler(async (req, res) => {
  const v = await vehicleService.assignDriver(
    req.params.id,
    req.body.driverId,
    req.user
  );
  return success(res, v, 'Driver assigned');
});
