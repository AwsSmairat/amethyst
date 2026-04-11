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
  const phone =
    body.phone != null && String(body.phone).trim() !== ''
      ? String(body.phone).trim()
      : null;
  const user = await prisma.user.create({
    data: {
      fullName: body.fullName,
      phone,
      email: body.email.toLowerCase(),
      passwordHash,
      role: 'super_admin',
      isActive: true,
    },
  });
  let token;
  try {
    token = signToken({ sub: user.id, role: user.role });
  } catch (e) {
    console.error('[auth] JWT sign failed', e);
    throw new AppError('Login service error', 503, 'TOKEN_SIGN_FAILED');
  }
  return { user: serializeUser(user), token };
}

export async function login({ email, password }) {
  const emailNorm = String(email ?? '')
    .trim()
    .toLowerCase();
  const debugLogin = process.env.AUTH_DEBUG_LOGIN === '1';

  const user = await prisma.user.findUnique({
    where: { email: emailNorm },
  });
  if (debugLogin) {
    console.log('[auth][login-debug] emailNorm=%s userFound=%s', emailNorm, Boolean(user));
  }
  if (!user) {
    if (debugLogin) {
      console.log('[auth][login-debug] reject: no user for email');
    }
    throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
  }
  const hasHash =
    typeof user.passwordHash === 'string' && user.passwordHash.length > 0;
  if (debugLogin) {
    console.log(
      '[auth][login-debug] passwordHashPresent=%s hashLen=%s',
      hasHash,
      typeof user.passwordHash === 'string' ? user.passwordHash.length : 0,
    );
  }
  let passwordOk = false;
  try {
    passwordOk = await comparePassword(password, user.passwordHash);
  } catch (e) {
    console.error('[auth] password compare failed', e);
    if (debugLogin) {
      console.log('[auth][login-debug] reject: bcrypt.compare threw');
    }
    throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
  }
  if (debugLogin) {
    console.log('[auth][login-debug] bcrypt.compare result=%s', passwordOk);
  }
  if (!passwordOk) {
    if (debugLogin) {
      console.log('[auth][login-debug] reject: password mismatch');
    }
    throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
  }
  if (!user.isActive) {
    throw new AppError('Account is inactive', 403, 'FORBIDDEN');
  }
  let token;
  try {
    token = signToken({ sub: user.id, role: user.role });
  } catch (e) {
    console.error('[auth] JWT sign failed', e);
    throw new AppError('Login service error', 503, 'TOKEN_SIGN_FAILED');
  }
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
