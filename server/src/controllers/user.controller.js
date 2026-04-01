import * as userService from '../services/user.service.js';
import { success, paginated } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const list = asyncHandler(async (req, res) => {
  const result = await userService.listUsers(req.query, req.user);
  return paginated(res, result);
});

export const getById = asyncHandler(async (req, res) => {
  const user = await userService.getUserById(req.params.id, req.user);
  return success(res, user);
});

export const create = asyncHandler(async (req, res) => {
  const user = await userService.createUser(req.body, req.user);
  return success(res, user, 'User created', 201);
});

export const update = asyncHandler(async (req, res) => {
  const user = await userService.updateUser(req.params.id, req.body, req.user);
  return success(res, user, 'User updated');
});

export const patchStatus = asyncHandler(async (req, res) => {
  const user = await userService.patchUserStatus(
    req.params.id,
    req.body.isActive,
    req.user
  );
  return success(res, user, 'User status updated');
});

export const remove = asyncHandler(async (req, res) => {
  const result = await userService.deleteUser(req.params.id, req.user);
  return success(res, result, 'User deleted');
});
