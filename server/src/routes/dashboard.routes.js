import { Router } from 'express';
import * as ctrl from '../controllers/dashboard.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';

const r = Router();

r.use(authenticate);

r.get('/super-admin', authorize('super_admin'), ctrl.superAdmin);
r.get('/admin', authorize('super_admin', 'admin'), ctrl.admin);
r.get('/driver', authorize('driver'), ctrl.driver);

export default r;
