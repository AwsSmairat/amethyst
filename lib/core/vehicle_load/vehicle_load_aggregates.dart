import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/expenses/expense_aggregates.dart';
/// ملخص تحميل مركبة: محمّل اليوم/الشهر والمتبقي على السيارة (مفتوح).
final class VehicleLoadTotals {
  const VehicleLoadTotals({
    this.todayLoaded = 0,
    this.monthLoaded = 0,
    this.remainingOnVehicle = 0,
  });

  final int todayLoaded;
  final int monthLoaded;
  final int remainingOnVehicle;
}

DateTime? vehicleLoadRowDate(Map<String, dynamic> load) {
  final Object? raw = load['loadDate'] ?? load['createdAt'];
  return expenseRowDate(raw);
}

int vehicleLoadRemainingQty(Map<String, dynamic> load) {
  final int loaded = _intField(load, 'quantityLoaded');
  final int sold = _intField(load, 'quantitySold');
  final int returned = _intField(load, 'quantityReturned');
  final int remaining = loaded - sold - returned;
  return remaining < 0 ? 0 : remaining;
}

int _intField(Map<String, dynamic> map, String key) {
  final Object? v = map[key];
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

/// مفتوح فقط إذا الحالة ليست مغلقة **و** ما زال هناك كمية على السيارة.
bool vehicleLoadIsOpen(Map<String, dynamic> load) {
  if (load['status']?.toString() == 'closed') {
    return false;
  }
  return vehicleLoadRemainingQty(load) > 0;
}

/// حالة العرض: مغلق عند انتهاء الحمل حتى لو بقي `status` قديماً «مفتوح».
String vehicleLoadEffectiveStatus(Map<String, dynamic> load) {
  if (vehicleLoadRemainingQty(load) <= 0) {
    return 'closed';
  }
  final String raw = load['status']?.toString() ?? 'open';
  return raw == 'closed' ? 'closed' : 'open';
}

Future<List<Map<String, dynamic>>> fetchAllVehicleLoadRows(
  AmethystApi api, {
  int limit = 100,
  int maxPages = 50,
}) async {
  final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
  for (var page = 1; page <= maxPages; page++) {
    final Map<String, dynamic> res =
        await api.listVehicleLoads(page: page, limit: limit);
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

Map<String, VehicleLoadTotals> summarizeVehicleLoadsByVehicleId(
  List<Map<String, dynamic>> loads, {
  DateTime? asOf,
}) {
  final DateTime now = asOf ?? DateTime.now();
  final Map<String, VehicleLoadTotals> out = <String, VehicleLoadTotals>{};

  for (final Map<String, dynamic> load in loads) {
    final String? vehicleId = load['vehicleId']?.toString();
    if (vehicleId == null || vehicleId.isEmpty) {
      continue;
    }
    final int qtyLoaded = _intField(load, 'quantityLoaded');
    final DateTime? loadDay = vehicleLoadRowDate(load);
    final bool isToday = expenseIsToday(loadDay, now);
    final bool isMonth = expenseIsCurrentMonth(loadDay, now);
    final VehicleLoadTotals cur = out[vehicleId] ?? const VehicleLoadTotals();
    var remaining = cur.remainingOnVehicle;
    if (vehicleLoadIsOpen(load)) {
      remaining += vehicleLoadRemainingQty(load);
    }
    out[vehicleId] = VehicleLoadTotals(
      todayLoaded: cur.todayLoaded + (isToday ? qtyLoaded : 0),
      monthLoaded: cur.monthLoaded + (isMonth ? qtyLoaded : 0),
      remainingOnVehicle: remaining,
    );
  }
  return out;
}
