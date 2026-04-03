import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { hashPassword } from '../utils/password.js';
import { serializeUser } from '../utils/serialize.js';
import { auditLog } from './audit.service.js';
import { parsePagination, parseSort } from '../utils/pagination.js';

const userSelect = {
  id: true,
  fullName: true,
  phone: true,
  email: true,
  role: true,
  isActive: true,
  createdAt: true,
  updatedAt: true,
};

function canManageUser(actor, targetRole, targetId) {
  if (actor.role === 'super_admin') return true;
  if (actor.role === 'admin') {
    if (targetRole === 'super_admin') return false;
    if (targetRole === 'admin' && targetId !== actor.id) return false;
    return true;
  }
  return false;
}

export async function listUsers(query, actor) {
  const { page, limit, skip } = parsePagination(query);
  const { sortBy, order } = parseSort(query, ['createdAt', 'fullName', 'email'], 'createdAt');

  const where = {};
  if (actor.role === 'admin') {
    where.role = { in: ['admin', 'driver'] };
  }

  const [total, items] = await prisma.$transaction([
    prisma.user.count({ where }),
    prisma.user.findMany({
      where,
      select: userSelect,
      orderBy: { [sortBy]: order },
      skip,
      take: limit,
    }),
  ]);

  return { items, total, page, limit };
}

export async function getUserById(id, actor) {
  const user = await prisma.user.findUnique({
    where: { id },
    select: userSelect,
  });
  if (!user) throw new AppError('User not found', 404, 'NOT_FOUND');
  if (actor.role === 'admin' && user.role === 'super_admin') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  if (actor.role === 'driver' && actor.id !== id) {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  return user;
}

export async function createUser(body, actor) {
  if (actor.role !== 'super_admin') {
    throw new AppError('Only super admin can create users', 403, 'FORBIDDEN');
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
      role: body.role,
      isActive: true,
    },
    select: userSelect,
  });
  await auditLog({
    userId: actor.id,
    action: 'USER_CREATE',
    entityType: 'User',
    entityId: user.id,
    details: { role: user.role },
  });
  return user;
}

export async function updateUser(id, body, actor) {
  const existing = await prisma.user.findUnique({ where: { id } });
  if (!existing) throw new AppError('User not found', 404, 'NOT_FOUND');
  if (!canManageUser(actor, existing.role, existing.id)) {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }

  const data = {};
  if (body.fullName !== undefined) data.fullName = body.fullName;
  if (body.phone !== undefined) data.phone = body.phone;
  if (body.email !== undefined) data.email = body.email.toLowerCase();
  if (body.password) data.passwordHash = await hashPassword(body.password);

  const user = await prisma.user.update({
    where: { id },
    data,
    select: userSelect,
  });
  await auditLog({
    userId: actor.id,
    action: 'USER_UPDATE',
    entityType: 'User',
    entityId: id,
  });
  return user;
}

export async function patchUserStatus(id, isActive, actor) {
  const existing = await prisma.user.findUnique({ where: { id } });
  if (!existing) throw new AppError('User not found', 404, 'NOT_FOUND');
  if (!canManageUser(actor, existing.role, existing.id)) {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }

  const user = await prisma.user.update({
    where: { id },
    data: { isActive },
    select: userSelect,
  });
  await auditLog({
    userId: actor.id,
    action: 'USER_STATUS',
    entityType: 'User',
    entityId: id,
    details: { isActive },
  });
  return user;
}

export async function deleteUser(id, actor) {
  if (actor.role !== 'super_admin') {
    throw new AppError('Only super admin can delete users', 403, 'FORBIDDEN');
  }
  const existing = await prisma.user.findUnique({ where: { id } });
  if (!existing) throw new AppError('User not found', 404, 'NOT_FOUND');
  if (existing.role === 'super_admin') {
    const superCount = await prisma.user.count({ where: { role: 'super_admin' } });
    if (superCount <= 1) {
      throw new AppError('Cannot delete the last super admin', 400, 'FORBIDDEN');
    }
  }
  await prisma.user.delete({ where: { id } });
  await auditLog({
    userId: actor.id,
    action: 'USER_DELETE',
    entityType: 'User',
    entityId: id,
  });
  return { deleted: true };
}
