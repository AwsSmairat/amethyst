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

bool shouldSkipStationStockForDebtProduct(Map<String, dynamic> product) {
  final String? unitType = product['unitType'] as String?;
  if (unitType == 'gallon' || unitType == 'bottle') {
    return true;
  }
  final String name = product['name'] as String? ?? '';
  if (name.trim().isNotEmpty && productNameSuggestsFillingSkipStock(name)) {
    return true;
  }
  return false;
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
