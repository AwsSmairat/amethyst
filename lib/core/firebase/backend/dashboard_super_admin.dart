part of '../amethyst_firebase_backend.dart';

mixin _FirebaseSuperAdminDashboardOps on _FirebaseReportsOps {
  Future<Map<String, dynamic>> getDashboardSuperAdmin({
    void Function(Map<String, dynamic> partial)? onPartial,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh &&
          _dashboardCache != null &&
          _dashboardCachedAt != null &&
          DateTime.now().difference(_dashboardCachedAt!) < _dashboardCacheTtl) {
        return _dashboardCache!;
      }
      final Map<String, dynamic> result = await _getDashboardSuperAdminImpl(
        onPartial: onPartial,
      );
      _dashboardCache = result;
      _dashboardCachedAt = DateTime.now();
      return result;
    } on FirebaseException catch (e) {
      throw ApiException(
        e.message ?? 'Firestore error',
        code: e.code.toUpperCase(),
      );
    }
  }

  ({int superAdmins, int admins, int drivers}) _countUsersByRole(
    QuerySnapshot<Map<String, dynamic>> users,
  ) {
    int superAdmins = 0;
    int admins = 0;
    int drivers = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in users.docs) {
      switch (doc.data()['role']?.toString()) {
        case 'super_admin':
          superAdmins++;
        case 'admin':
          admins++;
        case 'driver':
          drivers++;
      }
    }
    return (superAdmins: superAdmins, admins: admins, drivers: drivers);
  }

  Map<String, dynamic> _buildSuperAdminDashboardPayload({
    required int superAdmins,
    required int admins,
    required int drivers,
    required int vehicleCount,
    required int productCount,
    required int priced,
    required Map<String, dynamic> stock,
    required List<Map<String, dynamic>> lowStock,
    required List<Map<String, dynamic>> debtPreview,
    double stationToday = 0,
    double vehicleToday = 0,
    double expensesToday = 0,
    double monthlyStation = 0,
    double monthlyVehicle = 0,
    double monthlyExpenses = 0,
    double monthlyCartonSales = 0,
    double stationCashTodayAmount = 0,
    double stationCashYesterdayAmount = 0,
    double totalProfitToday = 0,
    double totalProfitMonth = 0,
  }) {
    final int totalUsers = superAdmins + admins + drivers;
    return <String, dynamic>{
      'role': 'super_admin',
      'metrics': <String, dynamic>{
        'totalSalesToday': stationToday + vehicleToday,
        'stationSalesToday': stationToday,
        'vehicleSalesToday': vehicleToday,
        'totalExpensesToday': expensesToday,
        'totalMonthlyExpenses': monthlyExpenses,
        'totalProfitToday': totalProfitToday,
        'totalProfitMonth': totalProfitMonth,
        'totalMonthlySales': monthlyStation + monthlyVehicle,
        'totalMonthlyCartonSales': monthlyCartonSales,
        'stationCashTodayAmount': stationCashTodayAmount,
        'stationCashYesterdayAmount': stationCashYesterdayAmount,
      },
      'details': <String, dynamic>{
        'counts': <String, dynamic>{
          'users': totalUsers,
          'admins': admins,
          'drivers': drivers,
          'vehicles': vehicleCount,
          'products': productCount,
          'pricedProducts': priced,
        },
        'lowStockProducts': lowStock,
        'stationDebtOpenPreview': debtPreview,
        'remainingStationStock': stock['remainingStationStock'],
        'remainingOnVehicles': stock['remainingOnVehicles'],
      },
      'totalUsers': totalUsers,
      'totalAdmins': admins,
      'totalDrivers': drivers,
      'totalVehicles': vehicleCount,
      'totalProducts': productCount,
      'productsWithPrice': priced,
      'totalSalesToday': stationToday + vehicleToday,
      'stationSalesToday': stationToday,
      'vehicleSalesToday': vehicleToday,
      'totalExpensesToday': expensesToday,
      'totalMonthlyExpenses': monthlyExpenses,
      'totalProfitToday': totalProfitToday,
      'totalProfitMonth': totalProfitMonth,
      'totalMonthlySales': monthlyStation + monthlyVehicle,
      'totalMonthlyCartonSales': monthlyCartonSales,
      'stationCashTodayAmount': stationCashTodayAmount,
      'stationCashYesterdayAmount': stationCashYesterdayAmount,
      'remainingStationStock': stock['remainingStationStock'],
      'remainingOnVehicles': stock['remainingOnVehicles'],
      'lowStockProducts': lowStock,
      'stationDebtOpenPreview': debtPreview,
    };
  }

  Future<Map<String, dynamic>> _getDashboardSuperAdminImpl({
    void Function(Map<String, dynamic> partial)? onPartial,
  }) async {
    await _requireSuperAdmin();
    final DateTime now = DateTime.now();
    final ({DateTime start, DateTime end}) day = businessDayRange(now);
    final ({DateTime start, DateTime end}) month = businessMonthRange(now);

    final Future<List<Object>> coreSnapsFuture = Future.wait<Object>(<Future<Object>>[
      _db
          .collection(FirestorePaths.users)
          .where('role', whereIn: <String>['super_admin', 'admin', 'driver'])
          .get(),
      _db.collection(FirestorePaths.vehicles).where('isActive', isEqualTo: true).get(),
      _db.collection(FirestorePaths.products).where('isActive', isEqualTo: true).get(),
      _db.collection(FirestorePaths.vehicleLoads).where('status', isEqualTo: 'open').get(),
      _db
          .collection(FirestorePaths.stationDebtEntries)
          .where('repaidAt', isNull: true)
          .limit(400)
          .get(),
      _db
          .collection(FirestorePaths.vehicleSales)
          .where('isDebt', isEqualTo: true)
          .limit(400)
          .get(),
    ]);
    final Future<List<Object>> salesFastFuture = Future.wait<Object>(<Future<Object>>[
      _sumSales(FirestorePaths.stationSales, day.start, day.end),
      _sumVehicleCashSales(day.start, day.end),
      _sumExpenses(day.start, day.end),
      _sumSales(FirestorePaths.stationSales, month.start, month.end),
      _sumVehicleCashSales(month.start, month.end),
      _sumExpenses(month.start, month.end),
      _stationCashBalanceSnapshot(),
    ]);
    final Future<Map<String, dynamic>> cartonFuture =
        _superAdminCartonMetricsForRange(start: month.start, end: month.end);
    final Future<({double today, double month})> profitTotalsFuture =
        _profitKpiTotalsForDashboard(
      dayStart: day.start,
      dayEnd: day.end,
      monthStart: month.start,
      monthEnd: month.end,
    );

    final List<Object> coreSnaps = await coreSnapsFuture;
    final QuerySnapshot<Map<String, dynamic>> users =
        coreSnaps[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> vehicles =
        coreSnaps[1] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> products =
        coreSnaps[2] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> openLoads =
        coreSnaps[3] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> debtSnap =
        coreSnaps[4] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> vehicleDebtSnap =
        coreSnaps[5] as QuerySnapshot<Map<String, dynamic>>;
    final ({int superAdmins, int admins, int drivers}) roleCounts =
        _countUsersByRole(users);
    int priced = 0;
    final Map<String, Map<String, dynamic>> productById =
        <String, Map<String, dynamic>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> p in products.docs) {
      if (_num(p.data()['price']) > 0) {
        priced++;
      }
      productById[p.id] = mapProductDoc(p);
    }
    final Map<String, dynamic> stock = _stockSnapshotFromProductsAndLoads(
      products: products.docs,
      openLoads: openLoads.docs,
    );
    final List<Map<String, dynamic>> lowStock = products.docs
        .map(mapProductDoc)
        .where((Map<String, dynamic> p) => ((p['stationStock'] as num?)?.toInt() ?? 0) < 50)
        .take(10)
        .toList(growable: false);
    final List<Map<String, dynamic>> debtPreview = _debtOpenPreviewFromEntries(
      entries: _openDebtPreviewRowsFromStationSnap(
        debtSnap,
        productById: productById,
      )..addAll(
          _openDebtPreviewRowsFromVehicleDebtSnap(
            vehicleDebtSnap,
            productById: productById,
          ),
        ),
      productById: productById,
    );

    void emitPartial({
      double stationToday = 0,
      double vehicleToday = 0,
      double expensesToday = 0,
      double monthlyStation = 0,
      double monthlyVehicle = 0,
      double monthlyExpenses = 0,
      double monthlyCartonSales = 0,
      double stationCashTodayAmount = 0,
      double stationCashYesterdayAmount = 0,
      double totalProfitToday = 0,
      double totalProfitMonth = 0,
    }) {
      onPartial?.call(
        _buildSuperAdminDashboardPayload(
          superAdmins: roleCounts.superAdmins,
          admins: roleCounts.admins,
          drivers: roleCounts.drivers,
          vehicleCount: vehicles.docs.length,
          productCount: products.docs.length,
          priced: priced,
          stock: stock,
          lowStock: lowStock,
          debtPreview: debtPreview,
          stationToday: stationToday,
          vehicleToday: vehicleToday,
          expensesToday: expensesToday,
          monthlyStation: monthlyStation,
          monthlyVehicle: monthlyVehicle,
          monthlyExpenses: monthlyExpenses,
          monthlyCartonSales: monthlyCartonSales,
          stationCashTodayAmount: stationCashTodayAmount,
          stationCashYesterdayAmount: stationCashYesterdayAmount,
          totalProfitToday: totalProfitToday,
          totalProfitMonth: totalProfitMonth,
        ),
      );
    }

    emitPartial();

    final List<Object> salesFast = await salesFastFuture;
    final ({double today, double yesterday}) cashSnapshot =
        salesFast[6] as ({double today, double yesterday});
    emitPartial(
      stationToday: salesFast[0] as double,
      vehicleToday: salesFast[1] as double,
      expensesToday: salesFast[2] as double,
      monthlyStation: salesFast[3] as double,
      monthlyVehicle: salesFast[4] as double,
      monthlyExpenses: salesFast[5] as double,
      stationCashTodayAmount: cashSnapshot.today,
      stationCashYesterdayAmount: cashSnapshot.yesterday,
    );

    final List<Object> slowResults = await Future.wait<Object>(<Future<Object>>[
      cartonFuture,
      profitTotalsFuture,
    ]);
    final Map<String, dynamic> cartonMetrics =
        slowResults[0] as Map<String, dynamic>;
    final ({double today, double month}) profitTotals =
        slowResults[1] as ({double today, double month});

    return _buildSuperAdminDashboardPayload(
      superAdmins: roleCounts.superAdmins,
      admins: roleCounts.admins,
      drivers: roleCounts.drivers,
      vehicleCount: vehicles.docs.length,
      productCount: products.docs.length,
      priced: priced,
      stock: stock,
      lowStock: lowStock,
      debtPreview: debtPreview,
      stationToday: salesFast[0] as double,
      vehicleToday: salesFast[1] as double,
      expensesToday: salesFast[2] as double,
      monthlyStation: salesFast[3] as double,
      monthlyVehicle: salesFast[4] as double,
      monthlyExpenses: salesFast[5] as double,
      monthlyCartonSales:
          _num(cartonMetrics['monthlyCartonSalesTotalAmount']),
      stationCashTodayAmount: cashSnapshot.today,
      stationCashYesterdayAmount: cashSnapshot.yesterday,
      totalProfitToday: profitTotals.today,
      totalProfitMonth: profitTotals.month,
    );
  }

  Future<Map<String, dynamic>> _superAdminCartonMetricsForRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final List<Object> snaps = await Future.wait<Object>(<Future<Object>>[
      _db.collection(FirestorePaths.products).where('isActive', isEqualTo: true).get(),
      _db
          .collection(FirestorePaths.stationSales)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(end),
          )
          .get(),
      _db
          .collection(FirestorePaths.vehicleSales)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(end),
          )
          .get(),
      _db
          .collection(FirestorePaths.vehicleSales)
          .where('isDebt', isEqualTo: true)
          .get(),
      _db
          .collection(FirestorePaths.stationDebtEntries)
          .where('repaidAt', isNull: true)
          .get(),
      _db
          .collection(FirestorePaths.expenses)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(end),
          )
          .get(),
    ]);
    final QuerySnapshot<Map<String, dynamic>> productsSnap =
        snaps[0] as QuerySnapshot<Map<String, dynamic>>;
    final Map<String, Map<String, dynamic>> productById =
        <String, Map<String, dynamic>>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in productsSnap.docs)
        doc.id: mapProductDoc(doc),
    };

    final List<Map<String, dynamic>> products = productById.values.toList(
      growable: false,
    );
    final int cartonStock = aggregateStationStockForBalanceRow(
      products: products,
      rowIndex: 0,
    );

    double monthlyAmount = 0;
    int homeQty = 0;
    int storeQty = 0;
    var debtQty = 0;
    var debtAmount = 0.0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[1] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final Map<String, dynamic> sale = doc.data();
      if (isStationDebtRepaymentSale(sale)) {
        continue;
      }
      final String? note = sale['note']?.toString();
      if (note != null && note.startsWith('سداد دين')) {
        continue;
      }
      final String? productId = sale['productId']?.toString();
      final Map<String, dynamic>? product = productById[productId];
      if (!isCartonSaleRow(productId: productId, product: product)) {
        continue;
      }
      monthlyAmount += _num(sale['totalAmount']);
      homeQty += (sale['quantity'] as num?)?.toInt() ?? 0;
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[2] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final Map<String, dynamic> sale = doc.data();
      final String? productId = sale['productId']?.toString();
      final Map<String, dynamic>? product = productById[productId];
      if (!isCartonSaleRow(productId: productId, product: product)) {
        continue;
      }
      if (sale['isDebt'] == true) {
        continue;
      }
      // يشمل البيع النقدي + سداد الدين (settledFromDebtSaleId) في شهر السداد.
      monthlyAmount += _num(sale['totalAmount']);
      final int qty = (sale['quantity'] as num?)?.toInt() ?? 0;
      if (sale['saleDestination']?.toString() == 'store') {
        storeQty += qty;
      } else {
        homeQty += qty;
      }
    }

    // دين مركبة مفتوح (كل الوقت) — من استعلام isDebt المنفصل.
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[3] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final Map<String, dynamic> sale = doc.data();
      if (sale['repaidAt'] != null) {
        continue;
      }
      final String? productId = sale['productId']?.toString();
      final Map<String, dynamic>? product = productById[productId];
      if (!isCartonSaleRow(productId: productId, product: product)) {
        continue;
      }
      debtQty += (sale['quantity'] as num?)?.toInt() ?? 0;
      debtAmount += _num(sale['totalAmount']);
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[4] as QuerySnapshot<Map<String, dynamic>>).docs) {
      if (doc.data()['repaidAt'] != null) {
        continue;
      }
      final Map<String, dynamic> e = doc.data();
      final String? productId = e['productId']?.toString();
      final Map<String, dynamic>? product = productById[productId];
      if (!isCartonSaleRow(productId: productId, product: product)) {
        continue;
      }
      debtQty += (e['quantity'] as num?)?.toInt() ?? 0;
      debtAmount += _num(e['totalAmount']);
    }

    double cartonExpenses = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[5] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final Map<String, dynamic> e = doc.data();
      if (e['driverId'] != null || e['vehicleId'] != null) {
        continue;
      }
      final String? note = e['note'] as String?;
      if (note != null &&
          (note.startsWith('STATION_CARTON_WATER:') || note.contains('كراتين مي'))) {
        cartonExpenses += _num(e['amount']);
      }
    }

    return <String, dynamic>{
      'cartonStock': cartonStock,
      'monthlyCartonExpensesTotalAmount': cartonExpenses,
      'monthlyCartonSalesTotalAmount': monthlyAmount,
      'monthlyCartonSalesTotalQty': homeQty + storeQty,
      'monthlyCartonSalesHomeQty': homeQty,
      'monthlyCartonSalesStoreQty': storeQty,
      'cartonDebtUnpaidQuantity': debtQty,
      'cartonDebtUnpaidTotalAmount': debtAmount,
    };
  }

  Future<Map<String, dynamic>> getSuperAdminCartonSummary({
    int? year,
    int? month,
  }) async {
    await _requireSuperAdmin();
    final DateTime n = DateTime.now();
    final int y = year ?? n.year;
    final int m = month ?? n.month;
    final ({DateTime start, DateTime end}) range = businessMonthRangeFor(y, m);
    return _superAdminCartonMetricsForRange(start: range.start, end: range.end);
  }
}
