import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/expenses/expense_aggregates.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';

/// مبيعات نقدية لمركبة واحدة (يوم / شهر).
final class VehicleSalesTotals {
  const VehicleSalesTotals({
    this.today = 0,
    this.month = 0,
  });

  final double today;
  final double month;
}

bool isCashVehicleSaleRow(Map<String, dynamic> row) => row['isDebt'] != true;

/// سداد دين مسجّل كمبيع سيارة (نقدي، مرتبط بسطر الدين الأصلي).
bool isVehicleDebtRepaymentSale(Map<String, dynamic> row) {
  final String? settled = row['settledFromDebtSaleId']?.toString().trim();
  return settled != null && settled.isNotEmpty;
}

/// منتج دفتر كوبون (وليس مجرد سعر وحدة = ٠).
bool isVehicleCouponBookProductRow(Map<String, dynamic> row) {
  final Map<String, dynamic>? product = row['product'] is Map<String, dynamic>
      ? row['product'] as Map<String, dynamic>
      : null;
  if (product == null) {
    return false;
  }
  final String unitType =
      (product['unitType'] ?? product['type'])?.toString().trim().toLowerCase() ??
          '';
  if (unitType == 'coupon') {
    return true;
  }
  final String name = normalizeStationBalanceProductName(
    product['name']?.toString() ?? '',
  );
  return name.contains('coupon') || name.contains('كوبون');
}

/// شارة «كوبون» في قائمة المبيعات — لا تُعرض لسداد الدين ولا عندما الاسم يوضح أنه كوبون.
bool shouldShowVehicleSaleCouponBadge(
  Map<String, dynamic> row, {
  String? displayProductName,
}) {
  if (isVehicleDebtRepaymentSale(row)) {
    return false;
  }
  if (!isVehicleCouponBookProductRow(row)) {
    return false;
  }
  final String shown = normalizeStationBalanceProductName(
    displayProductName?.trim() ?? '',
  );
  if (shown.contains('coupon') || shown.contains('كوبون')) {
    return false;
  }
  return true;
}

/// يُعرض في قائمة/ملخص مبيعات المركبة: مبيع نقدي أو سداد دين — لا تسجيل دين مفتوح.
bool isVehicleSaleVisibleInSalesList(Map<String, dynamic> row) {
  if (row['isDebt'] == true) {
    return false;
  }
  return true;
}

double vehicleSaleRowMoney(Map<String, dynamic> row) =>
    parseDynamicDouble(row['totalAmount']) ?? 0;

Future<List<Map<String, dynamic>>> fetchAllVehicleRows(
  AmethystApi api, {
  int limit = 100,
  int maxPages = 50,
}) async {
  final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
  for (var page = 1; page <= maxPages; page++) {
    final Map<String, dynamic> res =
        await api.listVehicles(page: page, limit: limit);
    final List<Map<String, dynamic>> pageItems =
        (res['items'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    all.addAll(pageItems);
    final int total = switch (res['total']) {
      final int t => t,
      final num t => t.toInt(),
      _ => all.length,
    };
    if (pageItems.isEmpty || pageItems.length < limit || all.length >= total) {
      break;
    }
  }
  return all;
}

Future<List<Map<String, dynamic>>> fetchAllVehicleSaleRows(
  AmethystApi api, {
  int limit = 100,
  int maxPages = 50,
}) async {
  final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
  for (var page = 1; page <= maxPages; page++) {
    final Map<String, dynamic> res =
        await api.listVehicleSales(page: page, limit: limit);
    final List<Map<String, dynamic>> pageItems =
        (res['items'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    all.addAll(pageItems);
    final int total = switch (res['total']) {
      final int t => t,
      final num t => t.toInt(),
      _ => all.length,
    };
    if (pageItems.isEmpty || pageItems.length < limit || all.length >= total) {
      break;
    }
  }
  return all;
}

/// تجميع مبيعات نقدية (غير دين) لكل مركبة — اليوم والشهر الحاليين.
Map<String, VehicleSalesTotals> summarizeVehicleSalesByVehicleId(
  List<Map<String, dynamic>> sales, {
  DateTime? asOf,
}) {
  final DateTime now = asOf ?? DateTime.now();
  final Map<String, VehicleSalesTotals> out = <String, VehicleSalesTotals>{};

  for (final Map<String, dynamic> row in sales) {
    if (!isCashVehicleSaleRow(row)) {
      continue;
    }
    final String? vehicleId = row['vehicleId']?.toString();
    if (vehicleId == null || vehicleId.isEmpty) {
      continue;
    }
    final double amount = vehicleSaleRowMoney(row);
    if (amount <= 0) {
      continue;
    }
    final DateTime? created = expenseRowDate(row['createdAt']);
    final bool isToday = expenseIsToday(created, now);
    final bool isMonth = expenseIsCurrentMonth(created, now);
    final VehicleSalesTotals cur =
        out[vehicleId] ?? const VehicleSalesTotals();
    out[vehicleId] = VehicleSalesTotals(
      today: cur.today + (isToday ? amount : 0),
      month: cur.month + (isMonth ? amount : 0),
    );
  }
  return out;
}
