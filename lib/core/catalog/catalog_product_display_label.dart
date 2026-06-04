import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_product_columns.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_api_product_names.dart';

/// تسمية عربية للعرض من اسم المنتج في الكتالوج (قوائم الدين، إلخ).
String catalogProductArabicDisplayLabel(String? raw) {
  final String trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '—';
  }

  final String? homeLabel = vehicleProductDisplayLabelByNameMatch(
    place: VehicleProductColumnPlace.home,
    productName: trimmed,
  );
  if (homeLabel != null) {
    return homeLabel;
  }

  final String? storeLabel = vehicleProductDisplayLabelByNameMatch(
    place: VehicleProductColumnPlace.store,
    productName: trimmed,
  );
  if (storeLabel != null) {
    return storeLabel;
  }

  for (var i = 0; i < StationSaleApiProductNames.filling.length; i++) {
    if (stationBalanceProductNamesMatch(
      trimmed,
      StationSaleApiProductNames.filling[i],
    )) {
      return _fillingColumnArabicLabel(i);
    }
  }

  for (var i = 0; i < StationSaleApiProductNames.emptySale.length; i++) {
    if (stationBalanceProductNamesMatch(
      trimmed,
      StationSaleApiProductNames.emptySale[i],
    )) {
      return _emptySaleColumnArabicLabel(i);
    }
  }

  for (var row = 0; row < StationBalanceProductLookup.nameCandidates.length; row++) {
    for (final String c in StationBalanceProductLookup.nameCandidates[row]) {
      if (stationBalanceProductNamesMatch(trimmed, c)) {
        return _stationBalanceRowArabicLabel(row);
      }
    }
  }

  return trimmed;
}

String _fillingColumnArabicLabel(int index) => switch (index) {
      0 => 'جالون',
      1 => 'قاروره',
      2 => 'جالون صغير',
      3 => 'قاروره صغير',
      4 => 'مهدي',
      5 => 'كوبون ١٢',
      6 => 'كوبون ٢٤',
      7 => 'كوبون ٥٠',
      _ => '',
    };

String _emptySaleColumnArabicLabel(int index) => switch (index) {
      0 => 'ق سعودي',
      1 => 'ق اردني',
      2 => 'ج فارغ',
      3 => 'ق صغير فارغ',
      4 => 'ج صغير فارغ',
      _ => '',
    };

String _stationBalanceRowArabicLabel(int row) => switch (row) {
      0 => 'ك مهدي',
      1 => 'ك يافا',
      2 => 'شرنك كبير',
      3 => 'شرنك وسط',
      4 => 'شرنك صغير',
      5 => 'ق سعودي',
      6 => 'ق اردني',
      7 => 'ج فارغ',
      8 => 'ق ارضية',
      9 => 'ج ارضية',
      10 => 'كوبون ١٢',
      11 => 'كوبون ٢٤',
      12 => 'كوبون ٥٠',
      13 => 'ق صغير فارغ',
      14 => 'ج صغير فارغ',
      _ => '',
    };
