import { z } from 'zod';
import { userRoleEnum } from './common.js';

export const registerSchema = z.object({
  fullName: z.string().min(2).max(200),
  phone: z.string().min(8).max(20).optional(),
  email: z.string().email(),
  password: z.string().min(8).max(128),
  role: userRoleEnum,
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});
