import 'package:amethyst/core/station_balance/station_balance_catalog.dart';

bool productNameSuggestsFillingSkipStock(String name) {
  final String t = name.trim();
  if (t == 'Water Gallon' || t == 'Water Bottle') {
    return true;
  }
  final String lower = t.toLowerCase();
  if (lower == 'water gallon' || lower == 'water bottle') {
    return true;
  }
  if (t.contains('جالون')) {
    return true;
  }
  if (t.contains('قارورة') || t.contains('قاروره')) {
    return true;
  }
  return false;
}

bool shouldSkipStationStockForDebtLine({
  required Map<String, dynamic> product,
  int? fillingLineSlot,
  bool fillingDebt = false,
}) {
  if (fillingDebt &&
      fillingLineSlot != null &&
      kStationFillingSkipStockColumnIndices.contains(fillingLineSlot)) {
    return true;
  }
  return shouldSkipStationStockForSale(
    product: product,
    fillingSale: fillingDebt,
    fillingLineSlot: fillingLineSlot,
  );
}

bool shouldSkipStationStockForSale({
  required Map<String, dynamic> product,
  required bool fillingSale,
  int? fillingLineSlot,
}) {
  final bool skipGallonBottleColumns =
      fillingSale && fillingLineSlot != null && (fillingLineSlot == 0 || fillingLineSlot == 1);
  final String trimmedName = (product['name'] as String? ?? '').trim();
  final bool nameMatchesFillingSkip = trimmedName.isNotEmpty &&
      productNameSuggestsFillingSkipStock(trimmedName);
  final String? unitType = product['unitType'] as String?;
  return skipGallonBottleColumns ||
      (fillingSale &&
          (unitType == 'gallon' || unitType == 'bottle' || nameMatchesFillingSkip));
}
