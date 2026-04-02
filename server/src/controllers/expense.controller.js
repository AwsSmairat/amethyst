import * as service from '../services/expense.service.js';
import { success, paginated } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const list = asyncHandler(async (req, res) => {
  const result = await service.listExpenses(req.query, req.user);
  return paginated(res, result);
});

export const getById = asyncHandler(async (req, res) => {
  const e = await service.getExpenseById(req.params.id, req.user);
  return success(res, e);
});

export const create = asyncHandler(async (req, res) => {
  const receiptUrl = req.file ? `/uploads/receipts/${req.file.filename}` : null;
  const e = await service.createExpense(
    { ...req.body, receiptUrl },
    req.user
  );
  return success(res, e, 'Expense recorded', 201);
});

export const update = asyncHandler(async (req, res) => {
  const e = await service.updateExpense(req.params.id, req.body, req.user);
  return success(res, e, 'Expense updated');
});

export const remove = asyncHandler(async (req, res) => {
  const r = await service.deleteExpense(req.params.id, req.user);
  return success(res, r, 'Expense deleted');
});

export const myExpenses = asyncHandler(async (req, res) => {
  const result = await service.myExpenses(req.query, req.user);
  return paginated(res, result);
});
