import { Router } from 'express';
import * as ctrl from '../controllers/vehicle.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  createVehicleSchema,
  updateVehicleSchema,
  assignDriverSchema,
} from '../validators/vehicle.validators.js';
import { listQuerySchema, uuidParam } from '../validators/common.js';

const r = Router();

r.use(authenticate);

r.get(
  '/',
  authorize('super_admin', 'admin', 'driver'),
  validate(listQuerySchema, 'query'),
  ctrl.list
);
r.get('/:id', authorize('super_admin', 'admin', 'driver'), validate(uuidParam, 'params'), ctrl.getById);
r.post(
  '/',
  authorize('super_admin', 'admin'),
  validate(createVehicleSchema),
  ctrl.create
);
r.put(
  '/:id',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  validate(updateVehicleSchema),
  ctrl.update
);
r.delete(
  '/:id',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  ctrl.remove
);
r.patch(
  '/:id/assign-driver',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  validate(assignDriverSchema),
  ctrl.assignDriver
);

export default r;
