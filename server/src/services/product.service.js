import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { auditLog } from './audit.service.js';
import { parsePagination, parseSort } from '../utils/pagination.js';
import { mapProduct } from '../utils/serialize.js';

export async function listProducts(query) {
  const { page, limit, skip } = parsePagination(query);
  const { sortBy, order } = parseSort(query, ['createdAt', 'name', 'price'], 'createdAt');

  const where = {};
  if (query.isActive !== undefined) {
    const v = query.isActive;
    where.isActive = v === true || v === 'true' || v === '1';
  }

  const [total, items] = await prisma.$transaction([
    prisma.product.count({ where }),
    prisma.product.findMany({
      where,
      orderBy: { [sortBy]: order },
      skip,
      take: limit,
    }),
  ]);

  return {
    items: items.map(mapProduct),
    total,
    page,
    limit,
  };
}

export async function getProductById(id) {
  const p = await prisma.product.findUnique({ where: { id } });
  if (!p) throw new AppError('Product not found', 404, 'NOT_FOUND');
  return mapProduct(p);
}

export async function createProduct(body, actor) {
  const product = await prisma.product.create({
    data: {
      name: body.name,
      unitType: body.unitType,
      price: body.price,
      stationStock: body.stationStock ?? 0,
      isActive: body.isActive ?? true,
    },
  });
  await auditLog({
    userId: actor.id,
    action: 'PRODUCT_CREATE',
    entityType: 'Product',
    entityId: product.id,
  });
  return mapProduct(product);
}

export async function updateProduct(id, body, actor) {
  const product = await prisma.product.update({
    where: { id },
    data: {
      ...(body.name !== undefined && { name: body.name }),
      ...(body.unitType !== undefined && { unitType: body.unitType }),
      ...(body.price !== undefined && { price: body.price }),
      ...(body.stationStock !== undefined && { stationStock: body.stationStock }),
      ...(body.isActive !== undefined && { isActive: body.isActive }),
    },
  });
  await auditLog({
    userId: actor.id,
    action: 'PRODUCT_UPDATE',
    entityType: 'Product',
    entityId: id,
  });
  return mapProduct(product);
}

export async function patchStock(id, stationStock, actor) {
  const product = await prisma.product.update({
    where: { id },
    data: { stationStock },
  });
  await auditLog({
    userId: actor.id,
    action: 'PRODUCT_STOCK_ADJUST',
    entityType: 'Product',
    entityId: id,
    details: { stationStock },
  });
  return mapProduct(product);
}

function _isForeignKeyViolation(e) {
  const code = typeof e === 'object' && e !== null ? e.code : undefined;
  if (code === 'P2003' || code === 'P2014') {
    return true;
  }
  const msg = String(
    typeof e === 'object' && e !== null && 'message' in e
      ? /** @type {{ message?: string }} */ (e).message
      : e
  );
  return /foreign key|violates foreign key constraint/i.test(msg);
}

export async function deleteProduct(id, actor) {
  const existing = await prisma.product.findUnique({
    where: { id },
    select: { id: true },
  });
  if (!existing) {
    throw new AppError('Product not found', 404, 'NOT_FOUND');
  }
  try {
    await prisma.product.delete({ where: { id } });
  } catch (e) {
    if (_isForeignKeyViolation(e)) {
      /** Hard delete blocked — deactivate so UI can stop offering it without breaking history. */
      const updated = await prisma.product.update({
        where: { id },
        data: { isActive: false },
      });
      try {
        await auditLog({
          userId: actor.id,
          action: 'PRODUCT_UPDATE',
          entityType: 'Product',
          entityId: id,
          details: {
            reason: 'deactivated instead of delete (product still referenced)',
          },
        });
      } catch (logErr) {
        console.error('[audit] PRODUCT deactivate-after-fk log failed', logErr);
      }
      return {
        deleted: false,
        deactivated: true,
        product: mapProduct(updated),
      };
    }
    throw e;
  }
  try {
    await auditLog({
      userId: actor.id,
      action: 'PRODUCT_DELETE',
      entityType: 'Product',
      entityId: id,
    });
  } catch (logErr) {
    console.error('[audit] PRODUCT_DELETE log failed (product was removed)', logErr);
  }
  return { deleted: true };
}
