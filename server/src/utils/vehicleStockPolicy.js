/**
 * أصناف تُدار مخزون المحطة لها عبر التحميل على المركبة ثم البيع من السيارة:
 * عند التحميل يُحجَز من `station_stock`؛ عند البيع يُستهلك من سجل التحميل فقط
 * (لا خصم ثانٍ من المحطة). انظر `vehicleLoad.service.js` و `vehicleSale.service.js`.
 */
export function stationStockReservedOnVehicleLoad(product) {
  const t = product.unitType;
  return t === 'carton' || t === 'coupon';
}
