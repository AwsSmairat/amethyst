import { Router } from 'express';
import * as ctrl from '../controllers/user.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  createUserSchema,
  updateUserSchema,
  patchUserStatusSchema,
} from '../validators/user.validators.js';
import { listQuerySchema, uuidParam } from '../validators/common.js';

const r = Router();

r.use(authenticate);

r.get(
  '/',
  authorize('super_admin', 'admin'),
  validate(listQuerySchema, 'query'),
  ctrl.list
);
r.get('/:id', authorize('super_admin', 'admin', 'driver'), validate(uuidParam, 'params'), ctrl.getById);
r.post(
  '/',
  authorize('super_admin'),
  validate(createUserSchema),
  ctrl.create
);
r.put(
  '/:id',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  validate(updateUserSchema),
  ctrl.update
);
r.patch(
  '/:id/status',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  validate(patchUserStatusSchema),
  ctrl.patchStatus
);
r.delete('/:id', authorize('super_admin'), validate(uuidParam, 'params'), ctrl.remove);

export default r;
