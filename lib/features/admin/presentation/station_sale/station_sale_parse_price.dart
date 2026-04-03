double? parseStationSalePrice(dynamic v) {
  if (v == null) {
    return null;
  }
  if (v is num) {
    return v.toDouble();
  }
  return double.tryParse(v.toString());
}
