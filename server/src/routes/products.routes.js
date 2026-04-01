import { Router } from 'express';
import * as ctrl from '../controllers/product.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  createProductSchema,
  updateProductSchema,
  patchStockSchema,
} from '../validators/product.validators.js';
import { listQuerySchema, uuidParam } from '../validators/common.js';

const r = Router();

r.use(authenticate);

r.get('/', validate(listQuerySchema, 'query'), ctrl.list);
r.get('/:id', validate(uuidParam, 'params'), ctrl.getById);
r.post(
  '/',
  authorize('super_admin', 'admin'),
  validate(createProductSchema),
  ctrl.create
);
r.put(
  '/:id',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  validate(updateProductSchema),
  ctrl.update
);
r.patch(
  '/:id/stock',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  validate(patchStockSchema),
  ctrl.patchStock
);
r.delete(
  '/:id',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  ctrl.remove
);

export default r;
