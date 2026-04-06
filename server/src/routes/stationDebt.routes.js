import { Router } from 'express';
import * as ctrl from '../controllers/stationDebt.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  stationDebtCreateBatchSchema,
  stationDebtRepaySchema,
} from '../validators/stationDebt.validators.js';
import { listQuerySchema } from '../validators/common.js';

const r = Router();

r.use(authenticate);

r.get(
  '/',
  authorize('super_admin', 'admin', 'driver'),
  validate(listQuerySchema, 'query'),
  ctrl.list
);
r.post(
  '/repay',
  authorize('admin'),
  validate(stationDebtRepaySchema),
  ctrl.repay
);
r.post(
  '/',
  authorize('super_admin', 'admin'),
  validate(stationDebtCreateBatchSchema),
  ctrl.create
);

export default r;
