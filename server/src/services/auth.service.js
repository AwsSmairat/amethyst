import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { hashPassword, comparePassword } from '../utils/password.js';
import { signToken } from '../utils/jwt.js';
import { serializeUser } from '../utils/serialize.js';

/** Bootstrap only: creates the first super_admin when the database has no users. */
export async function register(body) {
  const count = await prisma.user.count();
  if (count > 0) {
    throw new AppError(
      'Registration is closed. Ask a super admin to create your account.',
      403,
      'FORBIDDEN'
    );
  }
  if (body.role !== 'super_admin') {
    throw new AppError(
      'First user must have role super_admin',
      400,
      'VALIDATION_ERROR'
    );
  }
  const passwordHash = await hashPassword(body.password);
  const user = await prisma.user.create({
    data: {
      fullName: body.fullName,
      phone: body.phone,
      email: body.email.toLowerCase(),
      passwordHash,
      role: 'super_admin',
      isActive: true,
    },
  });
  const token = signToken({ sub: user.id, role: user.role });
  return { user: serializeUser(user), token };
}

export async function login({ email, password }) {
  const user = await prisma.user.findUnique({
    where: { email: email.toLowerCase() },
  });
  if (!user) {
    throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
  }
  let passwordOk = false;
  try {
    passwordOk = await comparePassword(password, user.passwordHash);
  } catch (e) {
    console.error('[auth] password compare failed', e);
    throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
  }
  if (!passwordOk) {
    throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
  }
  if (!user.isActive) {
    throw new AppError('Account is inactive', 403, 'FORBIDDEN');
  }
  const token = signToken({ sub: user.id, role: user.role });
  return {
    user: serializeUser(user),
    token,
  };
}

export async function me(userId) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new AppError('User not found', 404, 'NOT_FOUND');
  }
  return serializeUser(user);
}
