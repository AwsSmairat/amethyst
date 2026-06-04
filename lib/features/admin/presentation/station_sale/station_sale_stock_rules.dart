import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';

bool stationSaleColumnSkipsStationStock({
  required StationSaleEntryKind entryKind,
  required int columnIndex,
  required Map<String, dynamic>? product,
}) {
  if (entryKind != StationSaleEntryKind.filling) {
    return false;
  }
  if (kStationFillingSkipStockColumnIndices.contains(columnIndex)) {
    return true;
  }
  if (product == null) {
    return false;
  }
  final String unit = (product['unitType'] ?? product['type'])?.toString() ?? '';
  if (unit == 'gallon' || unit == 'bottle') {
    return true;
  }
  return productNameSuggestsFillingSkipStock(product['name']?.toString());
}

bool productNameSuggestsFillingSkipStock(String? name) {
  if (name == null) {
    return false;
  }
  final String t = name.trim();
  if (t.isEmpty) {
    return false;
  }
  const Set<String> exact = <String>{
    'Water Gallon',
    'Water Bottle',
    'جالون صغير',
    'قاروره صغير',
    'Water Small Gallon',
    'Water Small Bottle',
  };
  if (exact.contains(t)) {
    return true;
  }
  final String lower = t.toLowerCase();
  for (final String e in exact) {
    if (lower == e.toLowerCase()) {
      return true;
    }
  }
  if (t.contains('جالون')) {
    return true;
  }
  if (t.contains('قاروره') || t.contains('قارورة')) {
    return true;
  }
  return false;
}
