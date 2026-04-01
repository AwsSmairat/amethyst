import { Router } from 'express';
import * as ctrl from '../controllers/return.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { returnCreateSchema } from '../validators/return.validators.js';
import { listQuerySchema, uuidParam } from '../validators/common.js';

const r = Router();

r.use(authenticate);

r.get(
  '/',
  authorize('super_admin', 'admin'),
  validate(listQuerySchema, 'query'),
  ctrl.list
);
r.get('/:id', authorize('super_admin', 'admin'), validate(uuidParam, 'params'), ctrl.getById);
r.post(
  '/',
  authorize('super_admin', 'admin', 'driver'),
  validate(returnCreateSchema),
  ctrl.create
);

export default r;
