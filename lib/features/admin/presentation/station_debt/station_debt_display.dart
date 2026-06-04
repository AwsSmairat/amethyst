import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_product_columns.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_kind.dart';
import 'package:amethyst/l10n/app_localizations.dart';

VehicleProductColumnPlace _placeFromEntry(Map<String, dynamic> entry) {
  final String dest = entry['saleDestination']?.toString() ?? 'home';
  return dest == 'store'
      ? VehicleProductColumnPlace.store
      : VehicleProductColumnPlace.home;
}

/// اسم المنتج المعروض في قائمة الدين — مطابق تسميات بيع/دين المركبة (منزل / متجر).
String debtEntryProductDisplayLabel(
  Map<String, dynamic> entry, {
  List<Map<String, dynamic>>? products,
}) {
  final Map<String, dynamic>? product = entry['product'] is Map<String, dynamic>
      ? entry['product'] as Map<String, dynamic>
      : null;
  final String fallback = product?['name']?.toString().trim() ?? '—';
  if (!isVehicleDebtEntry(entry)) {
    return catalogProductArabicDisplayLabel(fallback);
  }

  final VehicleProductColumnPlace place = _placeFromEntry(entry);
  final String? productId = entry['productId']?.toString();

  if (productId != null && productId.isNotEmpty) {
    final int? col = vehicleProductColumnIndexForSaleProductId(
      place: place,
      productId: productId,
      products: products,
    );
    if (col != null) {
      return vehicleProductDisplayLabel(place, col);
    }
  }

  final String? byName = vehicleProductDisplayLabelByNameMatch(
    place: place,
    productName: fallback,
  );
  if (byName != null) {
    return byName;
  }

  if (place == VehicleProductColumnPlace.store) {
    if (isStoreMahdiProductName(fallback) ||
        productId == 'p_store_mahdi' ||
        productId == 'p_mahdi_carton') {
      return kStoreMahdiProductApiName;
    }
    if (fallback.contains('جالون') || productId == 'p_store_gallon') {
      return kStoreGallonProductApiName;
    }
    if (fallback.contains('قارور') || productId == 'p_store_bottle') {
      return kStoreBottleProductApiName;
    }
  }

  return catalogProductArabicDisplayLabel(fallback);
}

String? debtEntryVehiclePlaceLabel(
  Map<String, dynamic> entry,
  AppLocalizations l10n,
) {
  if (!isVehicleDebtEntry(entry)) {
    return null;
  }
  return _placeFromEntry(entry) == VehicleProductColumnPlace.store
      ? l10n.vehicleSalePlaceStore
      : l10n.vehicleSalePlaceHome;
}

String stationDebtKindSummary(
  List<Map<String, dynamic>> entries, {
  AppLocalizations? l10n,
}) {
  if (entries.isEmpty) {
    return '';
  }
  final int station = entries.where(isStationDebtEntry).length;
  final List<Map<String, dynamic>> vehicle =
      entries.where(isVehicleDebtEntry).toList(growable: false);
  final int vehicleHome = vehicle
      .where(
        (Map<String, dynamic> e) =>
            _placeFromEntry(e) == VehicleProductColumnPlace.home,
      )
      .length;
  final int vehicleStore = vehicle.length - vehicleHome;

  if (station > 0 && vehicle.isNotEmpty) {
    if (l10n != null && (vehicleHome > 0 || vehicleStore > 0)) {
      final List<String> parts = <String>[
        '${l10n.stationDebtKindStation} ($station)',
      ];
      if (vehicleHome > 0) {
        parts.add('${l10n.vehicleSalePlaceHome} ($vehicleHome)');
      }
      if (vehicleStore > 0) {
        parts.add('${l10n.vehicleSalePlaceStore} ($vehicleStore)');
      }
      return parts.join(' · ');
    }
    return 'دين محطة ($station) · دين سيارة (${vehicle.length})';
  }
  if (station > 0) {
    return l10n?.stationDebtKindStation ?? 'دين محطة';
  }
  if (vehicleStore > 0 && vehicleHome > 0) {
    return l10n != null
        ? '${l10n.vehicleSalePlaceHome} ($vehicleHome) · '
            '${l10n.vehicleSalePlaceStore} ($vehicleStore)'
        : 'دين منزل ($vehicleHome) · دين متجر ($vehicleStore)';
  }
  if (vehicleStore > 0) {
    return l10n != null
        ? '${l10n.vehicleSalePlaceStore} ($vehicleStore)'
        : 'دين متجر ($vehicleStore)';
  }
  return l10n?.stationDebtKindVehicle ?? 'دين سيارة';
}
