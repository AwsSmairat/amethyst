import { Router } from 'express';
import * as ctrl from '../controllers/auth.controller.js';
import { validate } from '../middlewares/validate.js';
import { registerSchema, loginSchema } from '../validators/auth.validators.js';
import { authenticate } from '../middlewares/auth.js';

const r = Router();

r.post('/register', validate(registerSchema), ctrl.register);
r.post('/login', validate(loginSchema), ctrl.login);
r.get('/me', authenticate, ctrl.me);

export default r;
