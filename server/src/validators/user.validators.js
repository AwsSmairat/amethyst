import { z } from 'zod';
import { userRoleEnum } from './common.js';

/** No `phone` field — creation is email-only; service stores `phone: null` (DB allows null). */
export const createUserSchema = z.object({
  fullName: z.string().min(2).max(200),
  email: z.string().email(),
  password: z.string().min(8).max(128),
  role: z.enum(['admin', 'driver']),
});

export const updateUserSchema = z.object({
  fullName: z.string().min(2).max(200).optional(),
  phone: z.string().min(8).max(20).optional(),
  email: z.string().email().optional(),
  password: z.string().min(8).max(128).optional(),
});

export const patchUserStatusSchema = z.object({
  isActive: z.boolean(),
});
