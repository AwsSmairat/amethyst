import * as service from '../services/dashboard.service.js';
import { success } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { normalizeDashboard } from '../utils/dashboardResponse.js';

export const superAdmin = asyncHandler(async (req, res) => {
  const raw = await service.superAdminDashboard();
  return success(res, normalizeDashboard('super_admin', raw));
});

export const admin = asyncHandler(async (req, res) => {
  const raw = await service.adminDashboard();
  return success(res, normalizeDashboard('admin', raw));
});

export const driver = asyncHandler(async (req, res) => {
  const raw = await service.driverDashboard(req.user);
  return success(res, normalizeDashboard('driver', raw));
});
