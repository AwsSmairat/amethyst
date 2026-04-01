export function serializeUser(user) {
  if (!user) return null;
  const { passwordHash, ...rest } = user;
  return rest;
}

export function serializeDecimal(obj) {
  if (obj === null || obj === undefined) return obj;
  if (typeof obj === 'object' && obj !== null && 'toNumber' in obj) {
    return obj.toNumber();
  }
  return obj;
}

export function mapProduct(p) {
  if (!p) return p;
  return {
    ...p,
    price: serializeDecimal(p.price),
    /** API alias for `unitType` */
    type: p.unitType,
    /** API alias for `stationStock` */
    stock: p.stationStock,
  };
}

export function mapStationSale(s) {
  if (!s) return s;
  return {
    ...s,
    unitPrice: serializeDecimal(s.unitPrice),
    totalAmount: serializeDecimal(s.totalAmount),
    product: s.product ? mapProduct(s.product) : s.product,
  };
}

export function mapVehicleSale(s) {
  if (!s) return s;
  return {
    ...s,
    unitPrice: serializeDecimal(s.unitPrice),
    totalAmount: serializeDecimal(s.totalAmount),
    product: s.product ? mapProduct(s.product) : s.product,
  };
}

export function mapExpense(e) {
  if (!e) return e;
  return {
    ...e,
    amount: serializeDecimal(e.amount),
  };
}
