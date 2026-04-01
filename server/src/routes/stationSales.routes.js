import { Router } from 'express';
import * as ctrl from '../controllers/stationSale.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { stationSaleCreateSchema } from '../validators/sale.validators.js';
import { listQuerySchema, uuidParam } from '../validators/common.js';

const r = Router();

r.use(authenticate);

r.get('/summary/daily', authorize('super_admin', 'admin'), ctrl.dailySummary);
r.get('/summary/monthly', authorize('super_admin', 'admin'), ctrl.monthlySummary);
r.get(
  '/',
  authorize('super_admin', 'admin'),
  validate(listQuerySchema, 'query'),
  ctrl.list
);
r.get('/:id', authorize('super_admin', 'admin'), validate(uuidParam, 'params'), ctrl.getById);
r.post(
  '/',
  authorize('super_admin', 'admin'),
  validate(stationSaleCreateSchema),
  ctrl.create
);

export default r;
