import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/expenses/expense_aggregates.dart';
import 'package:amethyst/core/utils/parse_api_datetime.dart';
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

/// يوم التحميل من `loadDate` فقط (بدون `createdAt`) — للتجميع والفلترة.
DateTime? vehicleLoadCalendarDay(Map<String, dynamic> load) {
  return parseApiDateOnly(load['loadDate']);
}

/// للتوافق مع مصروفات/تصدير — يفضّل [vehicleLoadCalendarDay] للتحميلات.
DateTime? vehicleLoadRowDate(Map<String, dynamic> load) {
  return vehicleLoadCalendarDay(load) ?? expenseRowDate(load['createdAt']);
}

/// تحميلات مفتوحة للعرض: تحميلات **اليوم** إن وُجدت، وإلا كل المفتوحة (كالسائق).
List<Map<String, dynamic>> vehicleOpenLoadsInScope({
  required List<Map<String, dynamic>> loads,
  required String vehicleId,
  DateTime? asOf,
}) {
  final DateTime now = asOf ?? DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final List<Map<String, dynamic>> open = loads
      .where(
        (Map<String, dynamic> l) =>
            l['vehicleId']?.toString() == vehicleId && vehicleLoadIsOpen(l),
      )
      .toList(growable: false);
  final List<Map<String, dynamic>> todayOpen = open
      .where(
        (Map<String, dynamic> l) => vehicleLoadCalendarDay(l) == today,
      )
      .toList(growable: false);
  return todayOpen.isNotEmpty ? todayOpen : open;
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

/// يجمع أسطر الحمولة المفتوحة للسائق حسب المنتج (عرض واحد: محمّل ١٨ بدل سطرين ٩).
List<Map<String, dynamic>> aggregateDriverLoadsByProduct(
  List<Map<String, dynamic>> lines,
) {
  final Map<String, Map<String, dynamic>> byProduct =
      <String, Map<String, dynamic>>{};
  for (final Map<String, dynamic> line in lines) {
    final String productId = line['productId']?.toString() ?? '';
    if (productId.isEmpty) {
      continue;
    }
    final Map<String, dynamic>? existing = byProduct[productId];
    if (existing == null) {
      byProduct[productId] = Map<String, dynamic>.from(line);
      continue;
    }
    existing['quantityLoaded'] =
        _intField(existing, 'quantityLoaded') + _intField(line, 'quantityLoaded');
    existing['quantitySold'] =
        _intField(existing, 'quantitySold') + _intField(line, 'quantitySold');
    existing['quantityReturned'] = _intField(existing, 'quantityReturned') +
        _intField(line, 'quantityReturned');
    final int remExisting = existing['remaining'] is int
        ? existing['remaining'] as int
        : vehicleLoadRemainingQty(existing);
    final int remLine = line['remaining'] is int
        ? line['remaining'] as int
        : vehicleLoadRemainingQty(line);
    existing['remaining'] = remExisting + remLine;
  }
  return byProduct.values.toList(growable: false);
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
  final DateTime today = DateTime(now.year, now.month, now.day);
  final Map<String, VehicleLoadTotals> out = <String, VehicleLoadTotals>{};
  final Set<String> vehicleIds = <String>{};

  for (final Map<String, dynamic> load in loads) {
    final String? vehicleId = load['vehicleId']?.toString();
    if (vehicleId == null || vehicleId.isEmpty) {
      continue;
    }
    vehicleIds.add(vehicleId);
    final int qtyLoaded = _intField(load, 'quantityLoaded');
    final DateTime? loadDay = vehicleLoadCalendarDay(load);
    final bool isToday = loadDay != null && loadDay == today;
    final bool isMonth = loadDay != null &&
        loadDay.year == now.year &&
        loadDay.month == now.month;
    final VehicleLoadTotals cur = out[vehicleId] ?? const VehicleLoadTotals();
    out[vehicleId] = VehicleLoadTotals(
      todayLoaded: cur.todayLoaded + (isToday ? qtyLoaded : 0),
      monthLoaded: cur.monthLoaded + (isMonth ? qtyLoaded : 0),
      remainingOnVehicle: cur.remainingOnVehicle,
    );
  }

  for (final String vehicleId in vehicleIds) {
    final int remaining = vehicleOpenLoadsInScope(
      loads: loads,
      vehicleId: vehicleId,
      asOf: now,
    ).fold<int>(
      0,
      (int sum, Map<String, dynamic> l) => sum + vehicleLoadRemainingQty(l),
    );
    final VehicleLoadTotals cur = out[vehicleId] ?? const VehicleLoadTotals();
    out[vehicleId] = VehicleLoadTotals(
      todayLoaded: cur.todayLoaded,
      monthLoaded: cur.monthLoaded,
      remainingOnVehicle: remaining,
    );
  }
  return out;
}
