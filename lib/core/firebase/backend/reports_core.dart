part of '../amethyst_firebase_backend.dart';

mixin _FirebaseReportsCoreOps on _FirebaseStationSalesOps, _FirebaseExpensesCashOps {
  Future<Map<String, dynamic>> reportsInventory() async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> products =
        await _db.collection(FirestorePaths.products).orderBy('name').get();
    final QuerySnapshot<Map<String, dynamic>> loads = await _db
        .collection(FirestorePaths.vehicleLoads)
        .where('status', isEqualTo: 'open')
        .get();
    int onVehicles = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> l in loads.docs) {
      final Map<String, dynamic> d = l.data();
      final int rem = ((d['quantityLoaded'] as num?)?.toInt() ?? 0) -
          ((d['quantitySold'] as num?)?.toInt() ?? 0) -
          ((d['quantityReturned'] as num?)?.toInt() ?? 0);
      if (rem > 0) {
        onVehicles += rem;
      }
    }
    return <String, dynamic>{
      'stationProducts': products.docs.map(mapProductDoc).toList(growable: false),
      'openLoadLines': loads.docs.length,
      'estimatedUnitsOnVehicles': onVehicles,
    };
  }

  Future<Map<String, dynamic>> reportsSalesWorkingDays() async {
    await _requireStaff();
    final Map<String, double> byDay = <String, double>{};
    final DateTime now = DateTime.now();
    final DateTime from = startOfDay(now).subtract(const Duration(days: 60));
    final DateTime to = endOfDay(now);

    void addAmount(Object? createdAt, double amount) {
      if (amount == 0) {
        return;
      }
      final String? key = profitRowLocalYmd(timestampToDate(createdAt));
      if (key == null || key.isEmpty) {
        return;
      }
      byDay[key] = (byDay[key] ?? 0) + amount;
    }

    // مبيعات المحطة (بما فيها سداد الدين المسجّل كمبيع).
    final List<Object> snaps = await Future.wait<Object>(<Future<Object>>[
      _db
          .collection(FirestorePaths.stationSales)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(to),
          )
          .get(),
      _db
          .collection(FirestorePaths.vehicleSales)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(to),
          )
          .get(),
    ]);
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[0] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final Map<String, dynamic> data = doc.data();
      addAmount(data['createdAt'], _num(data['totalAmount']));
    }

    // مبيعات المركبة النقدية فقط — نفس منطق KPI «مبيعات اليوم»
    // (يستثني تسجيل الدين المفتوح؛ سداد الدين يُحسب لأنه isDebt != true).
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[1] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final Map<String, dynamic> data = doc.data();
      if (!isCashVehicleSaleRow(data)) {
        continue;
      }
      addAmount(data['createdAt'], _num(data['totalAmount']));
    }

    final List<MapEntry<String, double>> sorted = byDay.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.key.compareTo(a.key));
    return <String, dynamic>{
      'days': sorted
          .map((MapEntry<String, double> e) => <String, dynamic>{
                'date': e.key,
                'combined': e.value,
              })
          .toList(growable: false),
    };
  }
}
