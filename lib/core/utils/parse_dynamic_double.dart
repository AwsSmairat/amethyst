/// تحويل قيم الـ API (رقم، Decimal، أو نص) إلى `double`.
double? parseDynamicDouble(dynamic v) {
  if (v == null) {
    return null;
  }
  if (v is num) {
    return v.toDouble();
  }
  return double.tryParse(v.toString());
}
