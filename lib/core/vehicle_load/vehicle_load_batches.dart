import 'package:amethyst/core/utils/parse_api_datetime.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_aggregates.dart';

/// حملة واحدة (ضغطة «إنشاء تحميل») — قد تشمل عدة منتجات.
final class VehicleLoadBatch {
  const VehicleLoadBatch({
    required this.batchKey,
    required this.lines,
    this.createdAt,
  });

  final String batchKey;
  final List<Map<String, dynamic>> lines;
  final DateTime? createdAt;

  int get lineCount => lines.length;

  int get totalQuantityLoaded {
    var sum = 0;
    for (final Map<String, dynamic> line in lines) {
      final Object? v = line['quantityLoaded'];
      if (v is int) {
        sum += v;
      } else if (v is num) {
        sum += v.toInt();
      } else {
        sum += int.tryParse(v?.toString() ?? '') ?? 0;
      }
    }
    return sum;
  }

  int get totalRemaining {
    var sum = 0;
    for (final Map<String, dynamic> line in lines) {
      sum += vehicleLoadRemainingQty(line);
    }
    return sum;
  }

  bool get isFullyClosed {
    for (final Map<String, dynamic> line in lines) {
      if (vehicleLoadEffectiveStatus(line) != 'closed') {
        return false;
      }
    }
    return lines.isNotEmpty;
  }
}

/// مفتاح تجميع السطور: `loadBatchId` (ضغطة إنشاء تحميل) أو سطر مستقل.
String vehicleLoadBatchKey(Map<String, dynamic> load) {
  final String? batchId = load['loadBatchId']?.toString().trim();
  if (batchId != null && batchId.isNotEmpty) {
    return batchId;
  }
  final String? id = load['id']?.toString();
  if (id != null && id.isNotEmpty) {
    return 'id_$id';
  }
  return 'unknown';
}

/// يجمع سطور التحميل إلى حمولات (الأحدث أولاً).
List<VehicleLoadBatch> groupVehicleLoadsIntoBatches(
  List<Map<String, dynamic>> loads,
) {
  final Map<String, List<Map<String, dynamic>>> byKey =
      <String, List<Map<String, dynamic>>>{};
  for (final Map<String, dynamic> load in loads) {
    final String key = vehicleLoadBatchKey(load);
    byKey.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(load);
  }
  final List<VehicleLoadBatch> batches = byKey.entries
      .map(
        (MapEntry<String, List<Map<String, dynamic>>> e) {
          final List<Map<String, dynamic>> lines =
              List<Map<String, dynamic>>.from(e.value);
          lines.sort(
            (Map<String, dynamic> a, Map<String, dynamic> b) {
              final DateTime? ta = parseApiDateTime(a['createdAt']);
              final DateTime? tb = parseApiDateTime(b['createdAt']);
              if (ta == null && tb == null) {
                return 0;
              }
              if (ta == null) {
                return 1;
              }
              if (tb == null) {
                return -1;
              }
              return ta.compareTo(tb);
            },
          );
          final DateTime? created = parseApiDateTime(lines.first['createdAt']);
          return VehicleLoadBatch(
            batchKey: e.key,
            lines: lines,
            createdAt: created,
          );
        },
      )
      .toList(growable: false);
  batches.sort(
    (VehicleLoadBatch a, VehicleLoadBatch b) {
      final DateTime? ta = a.createdAt;
      final DateTime? tb = b.createdAt;
      if (ta == null && tb == null) {
        return 0;
      }
      if (ta == null) {
        return 1;
      }
      if (tb == null) {
        return -1;
      }
      return tb.compareTo(ta);
    },
  );
  return batches;
}

/// عدد الحمولات في يوم معيّن لمركبة.
int vehicleLoadBatchCountForDay({
  required List<Map<String, dynamic>> loads,
  required String vehicleId,
  required DateTime day,
}) {
  final DateTime dayOnly = DateTime(day.year, day.month, day.day);
  final List<Map<String, dynamic>> dayLines = loads
      .where(
        (Map<String, dynamic> l) =>
            l['vehicleId']?.toString() == vehicleId &&
            vehicleLoadCalendarDay(l) == dayOnly,
      )
      .toList(growable: false);
  return groupVehicleLoadsIntoBatches(dayLines).length;
}
