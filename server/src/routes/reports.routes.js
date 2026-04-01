import { Router } from 'express';
import * as ctrl from '../controllers/reports.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { listQuerySchema } from '../validators/common.js';

const r = Router();

r.use(authenticate);
r.use(authorize('super_admin', 'admin'));

r.get('/sales/daily', validate(listQuerySchema, 'query'), ctrl.salesDaily);
r.get('/sales/monthly', validate(listQuerySchema, 'query'), ctrl.salesMonthly);
r.get('/sales/working-days', ctrl.salesWorkingDays);
r.get('/vehicles', validate(listQuerySchema, 'query'), ctrl.vehicles);
r.get('/drivers', validate(listQuerySchema, 'query'), ctrl.drivers);
r.get('/inventory', ctrl.inventory);
r.get('/expenses', validate(listQuerySchema, 'query'), ctrl.expenses);
r.get('/profit-loss', validate(listQuerySchema, 'query'), ctrl.profitLoss);

export default r;
