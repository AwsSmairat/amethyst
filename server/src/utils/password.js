import bcrypt from 'bcryptjs';
import { env } from '../config/env.js';

export async function hashPassword(plain) {
  return bcrypt.hash(plain, env.bcryptRounds);
}

export async function comparePassword(plain, hash) {
  return bcrypt.compare(plain, hash);
}
