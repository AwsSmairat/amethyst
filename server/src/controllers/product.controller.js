import * as productService from '../services/product.service.js';
import { success, paginated } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const list = asyncHandler(async (req, res) => {
  const result = await productService.listProducts(req.query);
  return paginated(res, result);
});

export const getById = asyncHandler(async (req, res) => {
  const p = await productService.getProductById(req.params.id);
  return success(res, p);
});

export const create = asyncHandler(async (req, res) => {
  const p = await productService.createProduct(req.body, req.user);
  return success(res, p, 'Product created', 201);
});

export const update = asyncHandler(async (req, res) => {
  const p = await productService.updateProduct(req.params.id, req.body, req.user);
  return success(res, p, 'Product updated');
});

export const patchStock = asyncHandler(async (req, res) => {
  const p = await productService.patchStock(
    req.params.id,
    req.body.stationStock,
    req.user
  );
  return success(res, p, 'Stock updated');
});

export const remove = asyncHandler(async (req, res) => {
  const r = await productService.deleteProduct(req.params.id, req.user);
  return success(res, r, 'Product deleted');
});
