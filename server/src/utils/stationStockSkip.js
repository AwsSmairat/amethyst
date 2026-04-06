/**
 * يطابق منطق خصم مخزون المحطة في `stationSale.service.js` لمنتجات الجالون/القارورة.
 * يُستخدم لبيع التعبئة ولتسجيل الدين.
 */

const FILLING_SKIP_STATION_STOCK_BY_NAME = new Set([
  'Water Gallon',
  'Water Bottle',
]);

const FILLING_SKIP_STATION_STOCK_BY_NAME_LOWER = new Set(
  [...FILLING_SKIP_STATION_STOCK_BY_NAME].map((n) => n.toLowerCase())
);

export function productNameSuggestsFillingSkipStock(name) {
  if (!name || typeof name !== 'string') {
    return false;
  }
  const t = name.trim();
  if (FILLING_SKIP_STATION_STOCK_BY_NAME.has(t)) {
    return true;
  }
  const lower = t.toLowerCase();
  if (FILLING_SKIP_STATION_STOCK_BY_NAME_LOWER.has(lower)) {
    return true;
  }
  if (t.includes('جالون')) {
    return true;
  }
  if (t.includes('قارورة') || t.includes('قاروره')) {
    return true;
  }
  return false;
}

/**
 * لا يُخصم مخزون المحطة لدين الجالون/القارورة (وما يطابق الاسم).
 */
export function shouldSkipStationStockForDebtProduct(product) {
  const unitType = product.unitType;
  if (unitType === 'gallon' || unitType === 'bottle') {
    return true;
  }
  const trimmedName =
    typeof product.name === 'string' ? product.name.trim() : '';
  if (trimmedName.length > 0 && productNameSuggestsFillingSkipStock(trimmedName)) {
    return true;
  }
  return false;
}
