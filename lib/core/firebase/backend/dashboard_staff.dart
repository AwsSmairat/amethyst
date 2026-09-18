part of '../amethyst_firebase_backend.dart';

mixin _FirebaseStaffDashboardsOps on _FirebaseBackendHelpers {
  Future<Map<String, dynamic>> getDashboardAdmin() async {
    await _requireStaff();
    if (_adminDashboardCache != null &&
        _adminDashboardCachedAt != null &&
        DateTime.now().difference(_adminDashboardCachedAt!) < _dashboardCacheTtl) {
      return _adminDashboardCache!;
    }
    final DateTime now = DateTime.now();
    final ({DateTime start, DateTime end}) day = businessDayRange(now);
    final ({DateTime start, DateTime end}) month = businessMonthRange(now);
    final List<Object> core = await Future.wait<Object>(<Future<Object>>[
      _db.collection(FirestorePaths.products).where('isActive', isEqualTo: true).get(),
      _db
          .collection(FirestorePaths.vehicleLoads)
          .where('status', isEqualTo: 'open')
          .get(),
      _db
          .collection(FirestorePaths.vehicleLoads)
          .where(
            'loadDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(day.start),
          )
          .where(
            'loadDate',
            isLessThanOrEqualTo: Timestamp.fromDate(day.end),
          )
          .get(),
      _db
          .collection(FirestorePaths.vehicleLoads)
          .where(
            'updatedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(day.start),
          )
          .where(
            'updatedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(day.end),
          )
          .get(),
      _db
          .collection(FirestorePaths.users)
          .where('role', isEqualTo: 'driver')
          .where('isActive', isEqualTo: true)
          .get(),
      _sumSales(FirestorePaths.stationSales, day.start, day.end),
      _sumVehicleCashSales(day.start, day.end),
      _sumSales(FirestorePaths.stationSales, month.start, month.end),
      _sumVehicleCashSales(month.start, month.end),
    ]);
    final QuerySnapshot<Map<String, dynamic>> products =
        core[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> openLoads =
        core[1] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> todayByLoadDate =
        core[2] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> updatedToday =
        core[3] as QuerySnapshot<Map<String, dynamic>>;
    final int activeDrivers =
        (core[4] as QuerySnapshot<Map<String, dynamic>>).docs.length;
    final double stationToday = core[5] as double;
    final double vehicleToday = core[6] as double;
    final double monthlyStation = core[7] as double;
    final double monthlyVehicle = core[8] as double;

    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> todayLoadById =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in todayByLoadDate.docs)
        doc.id: doc,
    };
    var returnedToday = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in updatedToday.docs) {
      returnedToday += (doc.data()['quantityReturned'] as num?)?.toInt() ?? 0;
    }
    final List<Map<String, dynamic>> loadsForDay =
        await _mapVehicleLoadsBatch(todayLoadById.values);
    final Map<String, dynamic> stock = _stockSnapshotFromProductsAndLoads(
      products: products.docs,
      openLoads: openLoads.docs,
    );
    final List<Map<String, dynamic>> lowStock = products.docs
        .map(mapProductDoc)
        .where((Map<String, dynamic> p) => ((p['stationStock'] as num?)?.toInt() ?? 0) < 50)
        .take(10)
        .toList(growable: false);
    final Map<String, dynamic> result = <String, dynamic>{
      'stationStockSummary': products.docs.map(mapProductDoc).toList(growable: false),
      'vehiclesLoadedToday': loadsForDay.length,
      'loadsToday': loadsForDay.take(20).toList(growable: false),
      'totalSalesToday': stationToday + vehicleToday,
      'stationSalesToday': stationToday,
      'vehicleSalesToday': vehicleToday,
      'totalMonthlySales': monthlyStation + monthlyVehicle,
      'returnedQuantitiesToday': returnedToday,
      'activeDrivers': activeDrivers,
      'remainingStationStock': stock['remainingStationStock'],
      'remainingOnVehicles': stock['remainingOnVehicles'],
      'lowStockProducts': lowStock,
    };
    _adminDashboardCache = result;
    _adminDashboardCachedAt = DateTime.now();
    return result;
  }

  Future<Map<String, dynamic>> getDashboardDriver() async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    if (actor['role'] != 'driver') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    final String actorId = actor['id']!.toString();
    if (_driverDashboardCache != null &&
        _driverDashboardCacheUserId == actorId &&
        _driverDashboardCachedAt != null &&
        DateTime.now().difference(_driverDashboardCachedAt!) < _dashboardCacheTtl) {
      return _driverDashboardCache!;
    }
    final DateTime now = DateTime.now();
    final ({DateTime start, DateTime end}) day = businessDayRange(now);
    final QuerySnapshot<Map<String, dynamic>> vehicles = await _db
        .collection(FirestorePaths.vehicles)
        .where('driverId', isEqualTo: actorId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (vehicles.docs.isEmpty) {
      return <String, dynamic>{
        'assignedVehicle': null,
        'productsLoadedToday': <dynamic>[],
        'soldQuantitiesToday': 0,
        'vehicleSalesAmountToday': 0,
        'remainingQuantities': <dynamic>[],
        'remainingOnVehicle': 0,
        'returnedQuantitiesToday': 0,
        'totalExpensesToday': 0,
        'notesSummary': <dynamic>[],
      };
    }
    final Map<String, dynamic> vehicle = mapVehicleDoc(vehicles.docs.first);
    final List<Object> driverData = await Future.wait<Object>(<Future<Object>>[
      _db
          .collection(FirestorePaths.vehicleLoads)
          .where('vehicleId', isEqualTo: vehicle['id'])
          .where('driverId', isEqualTo: actorId)
          .get(),
      _db.collection(FirestorePaths.vehicleSales).where('driverId', isEqualTo: actorId).get(),
      _db.collection(FirestorePaths.expenses).where('driverId', isEqualTo: actorId).get(),
    ]);
    final QuerySnapshot<Map<String, dynamic>> loads =
        driverData[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> sales =
        driverData[1] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> expenses =
        driverData[2] as QuerySnapshot<Map<String, dynamic>>;

    final List<Map<String, dynamic>> hydratedLoads =
        await _mapVehicleLoadsBatch(loads.docs);
    final List<Map<String, dynamic>> loadsToday = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> remainingQuantities = <Map<String, dynamic>>[];
    var returnedToday = 0;
    for (final Map<String, dynamic> load in hydratedLoads) {
      final DateTime? loadDate = timestampToDate(load['loadDate']);
      if (isInRange(loadDate, day.start, day.end)) {
        loadsToday.add(load);
      }
      final int loaded = (load['quantityLoaded'] as num?)?.toInt() ?? 0;
      final int sold = (load['quantitySold'] as num?)?.toInt() ?? 0;
      final int returned = (load['quantityReturned'] as num?)?.toInt() ?? 0;
      final DateTime? updated = timestampToDate(load['updatedAt']);
      if (isInRange(updated, day.start, day.end)) {
        returnedToday += returned;
      }
      final Map<String, dynamic>? product = load['product'] as Map<String, dynamic>?;
      remainingQuantities.add(<String, dynamic>{
        'productId': load['productId'],
        'productName': product?['name'] ?? '',
        'remaining': loaded - sold - returned,
        'quantityReturned': returned,
        'quantitySold': sold,
      });
    }
    var soldQty = 0;
    var salesAmount = 0.0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in sales.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (!isInRange(created, day.start, day.end)) {
        continue;
      }
      soldQty += (doc.data()['quantity'] as num?)?.toInt() ?? 0;
      salesAmount += _num(doc.data()['totalAmount']);
    }
    var totalExpensesToday = 0.0;
    final List<Map<String, dynamic>> notesSummary = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in expenses.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (!isInRange(created, day.start, day.end)) {
        continue;
      }
      totalExpensesToday += _num(doc.data()['amount']);
      final String? note = doc.data()['note'] as String?;
      if (note != null && note.isNotEmpty) {
        notesSummary.add(<String, dynamic>{'note': note, 'at': created});
      }
    }
    final int remainingOnVehicle = remainingQuantities.fold<int>(
      0,
      (int a, Map<String, dynamic> r) =>
          a + (((r['remaining'] as num?)?.toInt() ?? 0) > 0 ? (r['remaining'] as num).toInt() : 0),
    );
    final Map<String, dynamic> result = <String, dynamic>{
      'role': 'driver',
      'metrics': <String, dynamic>{
        'totalExpensesToday': totalExpensesToday,
        'vehicleSalesToday': salesAmount,
        'remainingOnVehicle': remainingOnVehicle,
      },
      'details': <String, dynamic>{
        'assignedVehicle': vehicle,
        'remainingQuantities': remainingQuantities,
        'notesSummary': notesSummary,
        'productsLoadedToday': loadsToday,
        'soldQuantitiesToday': soldQty,
        'returnedQuantitiesToday': returnedToday,
      },
      'assignedVehicle': vehicle,
      'productsLoadedToday': loadsToday,
      'soldQuantitiesToday': soldQty,
      'vehicleSalesAmountToday': salesAmount,
      'remainingQuantities': remainingQuantities,
      'remainingOnVehicle': remainingOnVehicle,
      'returnedQuantitiesToday': returnedToday,
      'totalExpensesToday': totalExpensesToday,
      'notesSummary': notesSummary,
    };
    _driverDashboardCache = result;
    _driverDashboardCachedAt = DateTime.now();
    _driverDashboardCacheUserId = actorId;
    return result;
  }
}
