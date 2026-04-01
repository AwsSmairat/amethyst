import * as authService from '../services/auth.service.js';
import { success } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const register = asyncHandler(async (req, res) => {
  const result = await authService.register(req.body);
  return success(res, result, 'Registered', 201);
});

export const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body);
  return success(res, result, 'Logged in');
});

export const me = asyncHandler(async (req, res) => {
  const user = await authService.me(req.user.id);
  return success(res, user);
});
