part of 'prototype_sample_data.dart';

mixin _PrototypeSampleDash on _PrototypeSampleExpenses {
  Map<String, dynamic> getDashboardSuperAdmin() {
    final double stationToday = _stationSalesAmountToday();
    final double vehicleToday = _vehicleSalesAmountToday();
    final double salesToday = stationToday + vehicleToday;
    final double expensesToday = _expensesAmountToday();
    final double expensesMonth = _expensesAmountThisMonth();
    final double salesMonth =
        _stationSalesAmountThisMonth() + _vehicleSalesAmountThisMonth();
    final double profitToday =
        (_profitSnapshotForToday()['total'] as num?)?.toDouble() ?? 0.0;
    final double profitMonth =
        (_profitSnapshotForCurrentMonth()['total'] as num?)?.toDouble() ?? 0.0;
    final double monthlyCarton = _stationSalesAmountThisMonthCarton() +
        _vehicleSalesAmountThisMonth(cartonOnly: true);
    final List<Map<String, dynamic>> debtPreview = _openDebtPreview();
    final List<Map<String, dynamic>> lowStock = _lowStockProducts();
    final int remainingStock = _totalStationStock();
    final int remainingOnVehicles = _totalRemainingOnVehicles();
    final List<Map<String, dynamic>> cashEntries = stationCashEntries;
    final double cashYesterday = cashEntries.isEmpty
        ? 0.0
        : (cashEntries.first['previousAmount'] as num?)?.toDouble() ?? 0.0;
    return <String, dynamic>{
      'role': 'super_admin',
      'metrics': <String, dynamic>{
        'totalSalesToday': salesToday,
        'stationSalesToday': stationToday,
        'vehicleSalesToday': vehicleToday,
        'totalExpensesToday': expensesToday,
        'totalMonthlyExpenses': expensesMonth,
        'totalProfitToday': profitToday,
        'totalProfitMonth': profitMonth,
        'totalMonthlySales': salesMonth,
        'stationCashTodayAmount': stationCashAmount,
        'stationCashYesterdayAmount': cashYesterday,
      },
      'details': <String, dynamic>{
        'counts': <String, dynamic>{
          'users': users.length,
          'admins': 2,
          'drivers': 2,
          'vehicles': vehicles.length,
          'products': products.length,
          'pricedProducts': 3,
        },
        'lowStockProducts': lowStock,
        'stationDebtOpenPreview': debtPreview,
        'remainingStationStock': remainingStock,
        'remainingOnVehicles': remainingOnVehicles,
      },
      'totalUsers': users.length,
      'totalAdmins': 2,
      'totalDrivers': 2,
      'totalVehicles': vehicles.length,
      'totalProducts': products.length,
      'productsWithPrice': 3,
      'totalSalesToday': salesToday,
      'stationSalesToday': stationToday,
      'vehicleSalesToday': vehicleToday,
      'totalExpensesToday': expensesToday,
      'totalMonthlyExpenses': expensesMonth,
      'totalProfitToday': profitToday,
      'totalProfitMonth': profitMonth,
      'totalMonthlySales': salesMonth,
      'totalMonthlyCartonSales': monthlyCarton,
      'stationCashTodayAmount': stationCashAmount,
      'stationCashYesterdayAmount': cashYesterday,
      'remainingStationStock': remainingStock,
      'remainingOnVehicles': remainingOnVehicles,
      'lowStockProducts': lowStock,
      'stationDebtOpenPreview': debtPreview,
    };
  }

  Map<String, dynamic> getSuperAdminCartonSummary({
    int? year,
    int? month,
  }) {
    final DateTime now = DateTime.now();
    final int y = year ?? now.year;
    final int m = month ?? now.month;
    return _cartonMonthlySummary(DateTime(y, m));
  }

  Map<String, dynamic> getDashboardAdmin() => <String, dynamic>{
        'role': 'admin',
        'stationSalesToday': _stationSalesAmountToday(),
        'vehicleLoadsToday': _vehicleLoadsCountToday(),
        'openDebtCount': openStationDebtEntries.length,
        'productsCount': products.length,
      };

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _loadDateOnly(Map<String, dynamic> load) {
    final Object? raw = load['loadDate'];
    if (raw is DateTime) {
      return _dateOnly(raw);
    }
    if (raw is String) {
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return _dateOnly(parsed);
      }
    }
    return _today;
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

  int _remainingForLoad(Map<String, dynamic> load) {
    final int loaded = _intField(load, 'quantityLoaded');
    final int sold = _intField(load, 'quantitySold');
    final int returned = _intField(load, 'quantityReturned');
    final int remaining = loaded - sold - returned;
    return remaining < 0 ? 0 : remaining;
  }

  /// يغلق سطر التحميل عندما لا يبقى شيء على السيارة (مبيع + مرتجع = المحمّل).
  void _closeLoadLineIfSettled(Map<String, dynamic> load) {
    if (_remainingForLoad(load) <= 0) {
      load['status'] = 'closed';
    }
  }

  DateTime? _rowDateOnly(Map<String, dynamic> row) {
    final Object? raw = row['createdAt'] ?? row['loadDate'];
    if (raw is DateTime) {
      return _dateOnly(raw);
    }
    if (raw is String) {
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return _dateOnly(parsed);
      }
    }
    return null;
  }

  bool _isSameCalendarDay(DateTime? dt, DateTime day) =>
      dt != null &&
      dt.year == day.year &&
      dt.month == day.month &&
      dt.day == day.day;

  bool _isSameCalendarMonth(DateTime? dt, DateTime ref) =>
      dt != null && dt.year == ref.year && dt.month == ref.month;

  double _rowMoney(Map<String, dynamic> row) =>
      (row['totalAmount'] as num?)?.toDouble() ??
      (row['amount'] as num?)?.toDouble() ??
      0;

  bool _isCashVehicleSale(Map<String, dynamic> vs) =>
      vs['isDebt'] != true;

  bool _isCartonRow(Map<String, dynamic> row) {
    final String? productId = row['productId']?.toString();
    if (productId == 'p_mahdi_carton' || productId == 'p_store_mahdi') {
      return true;
    }
    final Map<String, dynamic>? product = row['product'] is Map<String, dynamic>
        ? row['product'] as Map<String, dynamic>
        : null;
    if (product != null) {
      final String? id = product['id']?.toString();
      if (id == 'p_mahdi_carton' || id == 'p_store_mahdi') {
        return true;
      }
      final String? unit =
          product['unitType']?.toString() ?? product['type']?.toString();
      if (unit == 'carton') {
        return true;
      }
      final String name = product['name']?.toString() ?? '';
      if (isStoreMahdiProductName(name)) {
        return true;
      }
      final String normalized = normalizeStationBalanceProductName(name);
      for (final String c in kMahdiCartonStockNameCandidates) {
        if (normalized == normalizeStationBalanceProductName(c)) {
          return true;
        }
      }
      if (name.contains('مهدي') || name.toLowerCase().contains('mahdi')) {
        return true;
      }
    }
    return false;
  }

  bool _vehicleCartonSaleIsStore(Map<String, dynamic> vs) {
    if (vs['saleDestination']?.toString() == 'store') {
      return true;
    }
    final Map<String, dynamic>? product = vs['product'] is Map<String, dynamic>
        ? vs['product'] as Map<String, dynamic>
        : null;
    return isStoreMahdiProductName(product?['name']?.toString());
  }

  double _stationSalesAmountToday() {
    var sum = 0.0;
    for (final Map<String, dynamic> s in _stationSales) {
      if (_isSameCalendarDay(_rowDateOnly(s), _today)) {
        sum += _rowMoney(s);
      }
    }
    return sum;
  }

  double _stationSalesAmountThisMonth() {
    var sum = 0.0;
    for (final Map<String, dynamic> s in _stationSales) {
      if (_isSameCalendarMonth(_rowDateOnly(s), _now)) {
        sum += _rowMoney(s);
      }
    }
    return sum;
  }

  double _stationSalesAmountThisMonthCarton() {
    var sum = 0.0;
    for (final Map<String, dynamic> s in _stationSales) {
      if (!_isCartonRow(s) || !_isSameCalendarMonth(_rowDateOnly(s), _now)) {
        continue;
      }
      sum += _rowMoney(s);
    }
    return sum;
  }

  double _vehicleSalesAmountToday({String? driverId}) {
    var sum = 0.0;
    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (!_isCashVehicleSale(vs)) {
        continue;
      }
      if (driverId != null &&
          driverId.isNotEmpty &&
          vs['driverId']?.toString() != driverId) {
        continue;
      }
      if (_isSameCalendarDay(_rowDateOnly(vs), _today)) {
        sum += _rowMoney(vs);
      }
    }
    return sum;
  }

  double _vehicleSalesAmountThisMonth({bool cartonOnly = false}) {
    var sum = 0.0;
    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (!_isCashVehicleSale(vs)) {
        continue;
      }
      if (cartonOnly && !_isCartonRow(vs)) {
        continue;
      }
      if (_isSameCalendarMonth(_rowDateOnly(vs), _now)) {
        sum += _rowMoney(vs);
      }
    }
    return sum;
  }

  double _expensesAmountToday({String? driverId}) {
    var sum = 0.0;
    for (final Map<String, dynamic> e in _expenses) {
      if (driverId != null &&
          driverId.isNotEmpty &&
          e['driverId']?.toString() != driverId) {
        continue;
      }
      if (_isSameCalendarDay(_rowDateOnly(e), _today)) {
        sum += _rowMoney(e);
      }
    }
    return sum;
  }

  double _expensesAmountThisMonth({String? driverId}) {
    var sum = 0.0;
    for (final Map<String, dynamic> e in _expenses) {
      if (driverId != null &&
          driverId.isNotEmpty &&
          e['driverId']?.toString() != driverId) {
        continue;
      }
      if (_isSameCalendarMonth(_rowDateOnly(e), _now)) {
        sum += _rowMoney(e);
      }
    }
    return sum;
  }

  int _totalStationStock() {
    var sum = 0;
    for (final Map<String, dynamic> p in _products) {
      sum += _intField(p, 'stationStock');
    }
    return sum;
  }

  int _totalRemainingOnVehicles() {
    reconcileVehicleLoadStatuses();
    var sum = 0;
    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (load['status']?.toString() == 'closed') {
        continue;
      }
      sum += _remainingForLoad(load);
    }
    return sum;
  }

  List<Map<String, dynamic>> _openDebtPreview() {
    final Map<String, Map<String, Map<String, dynamic>>> byDebtor =
        <String, Map<String, Map<String, dynamic>>>{};
    for (final Map<String, dynamic> e in openStationDebtEntries) {
      final String name = e['debtorName']?.toString().trim() ?? '';
      if (name.isEmpty) {
        continue;
      }
      final bool vehicle = e['vehicleSaleId'] != null ||
          e['recordingSource']?.toString() == 'vehicle';
      final String productId = e['productId']?.toString() ?? '';
      if (productId.isEmpty) {
        continue;
      }
      final String lineKey = vehicle
          ? '$productId:${e['saleDestination']?.toString() ?? 'home'}'
          : productId;
      final Map<String, dynamic>? product = e['product'] is Map<String, dynamic>
          ? e['product'] as Map<String, dynamic>
          : productById(productId);
      final String productName = product?['name']?.toString() ?? '';
      if (productName.isEmpty) {
        continue;
      }
      byDebtor.putIfAbsent(name, () => <String, Map<String, dynamic>>{});
      final Map<String, dynamic>? prev = byDebtor[name]![lineKey];
      final int qty = _intField(e, 'quantity');
      byDebtor[name]![lineKey] = <String, dynamic>{
        'productName': productName,
        'quantity': ((prev?['quantity'] as num?)?.toInt() ?? 0) + qty,
        'kind': vehicle ? 'vehicle' : 'station',
      };
    }
    return byDebtor.entries
        .map(
          (MapEntry<String, Map<String, Map<String, dynamic>>> e) =>
              <String, dynamic>{
            'debtorName': e.key,
            'lines': e.value.values.toList(growable: false),
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _lowStockProducts({int threshold = 20}) =>
      _products
          .where(
            (Map<String, dynamic> p) => _intField(p, 'stationStock') < threshold,
          )
          .map((Map<String, dynamic> p) => Map<String, dynamic>.from(p))
          .toList(growable: false);

  int _vehicleLoadsCountToday() {
    var count = 0;
    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (_isSameCalendarDay(_loadDateOnly(load), _today)) {
        count++;
      }
    }
    return count;
  }

  Map<String, dynamic> _cartonMonthlySummary(DateTime monthRef) {
    final int cartonStock = aggregateStationStockForBalanceRow(
      products: _products,
      rowIndex: 0,
    );
    var cartonExpenses = 0.0;
    var cartonSalesQtyHome = 0;
    var cartonSalesQtyStore = 0;
    var monthlyCartonSales = 0.0;
    for (final Map<String, dynamic> e in _expenses) {
      if (!_isSameCalendarMonth(_rowDateOnly(e), monthRef)) {
        continue;
      }
      final String note = e['note']?.toString() ?? '';
      if (note.contains('STATION_CARTON') ||
          note.contains('كرتون') ||
          note.toLowerCase().contains('carton')) {
        cartonExpenses += _rowMoney(e);
      }
    }
    for (final Map<String, dynamic> s in _stationSales) {
      if (isStationDebtRepaymentSale(s)) {
        continue;
      }
      final String? note = s['note']?.toString();
      if (note != null && note.startsWith('سداد دين')) {
        continue;
      }
      if (!_isCartonRow(s) ||
          !_isSameCalendarMonth(_rowDateOnly(s), monthRef)) {
        continue;
      }
      final int q = _intField(s, 'quantity');
      cartonSalesQtyHome += q;
      monthlyCartonSales += _rowMoney(s);
    }
    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (!_isCashVehicleSale(vs) ||
          !_isCartonRow(vs) ||
          !_isSameCalendarMonth(_rowDateOnly(vs), monthRef)) {
        continue;
      }
      // يشمل سداد الدين (نقدي) — الدين المفتوح يُحسب في unpaid فقط.
      final int q = _intField(vs, 'quantity');
      monthlyCartonSales += _rowMoney(vs);
      if (_vehicleCartonSaleIsStore(vs)) {
        cartonSalesQtyStore += q;
      } else {
        cartonSalesQtyHome += q;
      }
    }
    var debtQty = 0;
    var debtAmount = 0.0;
    for (final Map<String, dynamic> e in openStationDebtEntries) {
      if (!_isCartonRow(e)) {
        continue;
      }
      debtQty += _intField(e, 'quantity');
      debtAmount += _rowMoney(e);
    }
    return <String, dynamic>{
      'cartonStock': cartonStock,
      'monthlyCartonExpensesTotalAmount': cartonExpenses,
      'monthlyCartonSalesTotalAmount': monthlyCartonSales,
      'monthlyCartonSalesTotalQty': cartonSalesQtyHome + cartonSalesQtyStore,
      'monthlyCartonSalesHomeQty': cartonSalesQtyHome,
      'monthlyCartonSalesStoreQty': cartonSalesQtyStore,
      'cartonDebtUnpaidQuantity': debtQty,
      'cartonDebtUnpaidTotalAmount': debtAmount,
    };
  }

  Map<String, dynamic> _enrichLoadRow(Map<String, dynamic> load) {
    final String? productId = load['productId']?.toString();
    final Map<String, dynamic> product = productId != null
        ? productById(productId)
        : Map<String, dynamic>.from(
            load['product'] as Map<String, dynamic>? ?? <String, dynamic>{},
          );
    return <String, dynamic>{
      ...Map<String, dynamic>.from(load),
      'product': product,
      'remaining': _remainingForLoad(load),
    };
  }

  String _sessionDriverId() =>
      PrototypeSession.current?.id ?? 'proto_driver';

  /// مركبة السائق الحالي دون تشغيل [reconcileVehicleLoadStatuses].
  String? vehicleIdForSessionDriver() {
    final String driverId = _sessionDriverId();
    return _assignedVehicleForDriver(driverId)?['id']?.toString();
  }

  Map<String, dynamic>? _assignedVehicleForDriver(String driverId) {
    for (final Map<String, dynamic> v in vehicles) {
      if (v['driverId']?.toString() == driverId) {
        return Map<String, dynamic>.from(v);
      }
    }
    return null;
  }

  /// تحميلات مفتوحة للسائق؛ يُفضَّل تحميلات اليوم وإلا كل المفتوحة (نموذج عرض).
  List<Map<String, dynamic>> _openLoadsForDriver(String driverId) {
    _ensureInitialVehicleLoad();
    final DateTime today = _dateOnly(DateTime.now());
    reconcileVehicleLoadStatuses();
    final List<Map<String, dynamic>> open = _vehicleLoads
        .where((Map<String, dynamic> l) {
          if (l['driverId']?.toString() != driverId) {
            return false;
          }
          if (l['status']?.toString() == 'closed') {
            return false;
          }
          return _remainingForLoad(l) > 0;
        })
        .map(_enrichLoadRow)
        .toList(growable: false);
    final List<Map<String, dynamic>> todayLoads = open
        .where((Map<String, dynamic> l) => _loadDateOnly(l) == today)
        .toList(growable: false);
    return todayLoads.isNotEmpty ? todayLoads : open;
  }

  Map<String, dynamic> driverCurrentLoad() {
    reconcileVehicleLoadStatuses();
    final String driverId = _sessionDriverId();
    final Map<String, dynamic>? vehicle = _assignedVehicleForDriver(driverId);
    if (vehicle == null) {
      return <String, dynamic>{
        'vehicle': null,
        'loads': <Map<String, dynamic>>[],
      };
    }
    final List<Map<String, dynamic>> loadLines = _openLoadsForDriver(driverId);
    final List<Map<String, dynamic>> loads =
        aggregateDriverLoadsByProduct(loadLines);
    return <String, dynamic>{
      'vehicle': vehicle,
      'loads': loads,
      'loadLines': loadLines,
    };
  }

  Map<String, dynamic> getDashboardDriver() {
    final Map<String, dynamic> current = driverCurrentLoad();
    final Map<String, dynamic>? vehicle =
        current['vehicle'] as Map<String, dynamic>?;
    final List<Map<String, dynamic>> loads =
        (current['loads'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    final List<Map<String, dynamic>> remainingQuantities =
        <Map<String, dynamic>>[
      for (final Map<String, dynamic> l in loads)
        <String, dynamic>{
          'productId': l['productId'],
          'productName':
              (l['product'] as Map<String, dynamic>?)?['name']?.toString() ??
                  '',
          'remaining': l['remaining'],
          'quantityReturned': _intField(l, 'quantityReturned'),
          'quantitySold': _intField(l, 'quantitySold'),
        },
    ];
    var remainingOnVehicle = 0;
    var soldToday = 0;
    var returnedToday = 0;
    for (final Map<String, dynamic> l in loads) {
      remainingOnVehicle += _intField(l, 'remaining');
      soldToday += _intField(l, 'quantitySold');
      returnedToday += _intField(l, 'quantityReturned');
    }
    final Map<String, dynamic> assignedVehicle =
        vehicle ?? vehicleById('v1');
    final String driverId = assignedVehicle['driverId']?.toString() ?? '';
    final double expensesToday = _expensesTotalForDriverToday(driverId);
    final double vehicleSalesToday = _vehicleSalesAmountToday(driverId: driverId);
    return <String, dynamic>{
      'role': 'driver',
      'metrics': <String, dynamic>{
        'totalExpensesToday': expensesToday,
        'vehicleSalesToday': vehicleSalesToday,
        'remainingOnVehicle': remainingOnVehicle,
      },
      'details': <String, dynamic>{
        'assignedVehicle': assignedVehicle,
        'remainingQuantities': remainingQuantities,
        'notesSummary': const <Map<String, dynamic>>[],
        'productsLoadedToday': loads,
        'soldQuantitiesToday': soldToday,
        'returnedQuantitiesToday': returnedToday,
      },
      'assignedVehicle': assignedVehicle,
      'productsLoadedToday': loads,
      'soldQuantitiesToday': soldToday,
      'vehicleSalesAmountToday': vehicleSalesToday,
      'remainingQuantities': remainingQuantities,
      'remainingOnVehicle': remainingOnVehicle,
      'returnedQuantitiesToday': returnedToday,
      'totalExpensesToday': expensesToday,
      'notesSummary': const <Map<String, dynamic>>[],
    };
  }
}
