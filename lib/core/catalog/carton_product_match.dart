import 'package:amethyst/core/station_balance/station_balance_catalog.dart';

/// هل السطر يمثل بيع/دين كرتون (ك مهدي، مهدي متجر، unitType=carton).
bool isCartonSaleRow({
  required String? productId,
  Map<String, dynamic>? product,
}) {
  if (productId == 'p_mahdi_carton' || productId == 'p_store_mahdi') {
    return true;
  }
  if (product == null) {
    return false;
  }
  final String? id = product['id']?.toString();
  if (id == 'p_mahdi_carton' || id == 'p_store_mahdi') {
    return true;
  }
  final String? unit =
      product['unitType']?.toString() ?? product['type']?.toString();
  if (unit == 'carton') {
    return true;
  }
  final String name = product['name']?.toString() ?? '';
  if (isStoreMahdiProductName(name)) {
    return true;
  }
  final String normalized = normalizeStationBalanceProductName(name);
  for (final String c in kMahdiCartonStockNameCandidates) {
    if (normalized == normalizeStationBalanceProductName(c)) {
      return true;
    }
  }
  if (name.contains('مهدي') || name.toLowerCase().contains('mahdi')) {
    return true;
  }
  return false;
}
