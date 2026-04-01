import { Router } from 'express';
import * as ctrl from '../controllers/vehicleLoad.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  createVehicleLoadSchema,
  updateVehicleLoadSchema,
} from '../validators/vehicleLoad.validators.js';
import { listQuerySchema, uuidParam } from '../validators/common.js';

const r = Router();

r.use(authenticate);

r.get('/driver/current', authorize('driver'), ctrl.driverCurrent);
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
  validate(createVehicleLoadSchema),
  ctrl.create
);
r.put(
  '/:id',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  validate(updateVehicleLoadSchema),
  ctrl.update
);
r.patch(
  '/:id/close',
  authorize('super_admin', 'admin'),
  validate(uuidParam, 'params'),
  ctrl.close
);

export default r;
