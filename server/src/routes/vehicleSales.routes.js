import { Router } from 'express';
import * as ctrl from '../controllers/vehicleSale.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { vehicleSaleCreateSchema } from '../validators/sale.validators.js';
import { listQuerySchema, uuidParam } from '../validators/common.js';

const r = Router();

r.use(authenticate);

r.get('/summary/daily', authorize('super_admin', 'admin'), ctrl.dailySummary);
r.get('/summary/monthly', authorize('super_admin', 'admin'), ctrl.monthlySummary);
r.get('/my', authorize('driver'), validate(listQuerySchema, 'query'), ctrl.mySales);
r.get('/driver/my-sales', authorize('driver'), validate(listQuerySchema, 'query'), ctrl.mySales);
r.get(
  '/',
  authorize('super_admin', 'admin', 'driver'),
  validate(listQuerySchema, 'query'),
  ctrl.list
);
r.get('/:id', authorize('super_admin', 'admin', 'driver'), validate(uuidParam, 'params'), ctrl.getById);
r.post(
  '/',
  authorize('driver'),
  validate(vehicleSaleCreateSchema),
  ctrl.create
);

export default r;
