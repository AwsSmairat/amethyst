import { Router } from 'express';
import * as ctrl from '../controllers/expense.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { uploadExpenseReceipt } from '../middlewares/upload.js';
import {
  expenseCreateSchema,
  expenseUpdateSchema,
} from '../validators/expense.validators.js';
import { listQuerySchema, uuidParam } from '../validators/common.js';

const r = Router();

r.use(authenticate);

r.get('/my', authorize('driver'), validate(listQuerySchema, 'query'), ctrl.myExpenses);
r.get('/driver/my-expenses', authorize('driver'), validate(listQuerySchema, 'query'), ctrl.myExpenses);
r.get(
  '/',
  authorize('super_admin', 'admin', 'driver'),
  validate(listQuerySchema, 'query'),
  ctrl.list
);
r.get('/:id', authorize('super_admin', 'admin', 'driver'), validate(uuidParam, 'params'), ctrl.getById);
r.post(
  '/',
  authorize('driver', 'admin', 'super_admin'),
  uploadExpenseReceipt.single('receipt'),
  validate(expenseCreateSchema),
  ctrl.create
);
r.put(
  '/:id',
  authorize('driver'),
  validate(uuidParam, 'params'),
  validate(expenseUpdateSchema),
  ctrl.update
);
r.delete('/:id', authorize('driver'), validate(uuidParam, 'params'), ctrl.remove);

export default r;
