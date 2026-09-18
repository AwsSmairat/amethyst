part of 'prototype_sample_data.dart';

mixin _PrototypeSampleExpenses on _PrototypeSampleLoads {
  final List<Map<String, dynamic>> _expenses = <Map<String, dynamic>>[];

  void _ensureInitialExpenses() {}

  List<Map<String, dynamic>> get expenses {
    _ensureInitialExpenses();
    return List<Map<String, dynamic>>.from(_expenses);
  }

  double _stationCashAmount = 0;

  final List<Map<String, dynamic>> _stationCashEntries =
      <Map<String, dynamic>>[];

  double get stationCashAmount => _stationCashAmount;

  List<Map<String, dynamic>> get stationCashEntries =>
      List<Map<String, dynamic>>.from(_stationCashEntries);

  void setStationCashAmount({
    required double amount,
    String? note,
  }) {
    final double previous = _stationCashAmount;
    _stationCashAmount = amount;
    _stationCashEntries.insert(
      0,
      <String, dynamic>{
        'id': 'cash_${_stationCashEntries.length + 1}',
        'amount': amount,
        'previousAmount': previous,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'createdAt': DateTime.now(),
      },
    );
    _persist();
  }

  final Map<String, double> _driverCashAmountByDriverId =
      <String, double>{};

  final Map<String, List<Map<String, dynamic>>> _driverCashEntriesByDriverId =
      <String, List<Map<String, dynamic>>>{};

  double driverCashAmountFor(String driverId) =>
      _driverCashAmountByDriverId[driverId] ?? 0.0;

  List<Map<String, dynamic>> driverCashEntriesFor(String driverId) {
    final List<Map<String, dynamic>>? entries =
        _driverCashEntriesByDriverId[driverId];
    if (entries == null) {
      return const <Map<String, dynamic>>[];
    }
    return List<Map<String, dynamic>>.from(entries);
  }

  void setDriverCashAmount({
    required String driverId,
    required double amount,
    String? note,
  }) {
    final double previous = driverCashAmountFor(driverId);
    _driverCashAmountByDriverId[driverId] = amount;
    final List<Map<String, dynamic>> entries =
        _driverCashEntriesByDriverId.putIfAbsent(
      driverId,
      () => <Map<String, dynamic>>[],
    );
    entries.insert(
      0,
      <String, dynamic>{
        'id': 'driver_cash_${driverId}_${entries.length + 1}',
        'driverId': driverId,
        'amount': amount,
        'previousAmount': previous,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'createdAt': DateTime.now(),
      },
    );
    _persist();
  }

  ({
    Map<String, double> todayByDriverId,
    Map<String, double> yesterdayByDriverId,
    Map<String, Map<String, double>> recordedOnDayByDriverId,
    Map<String, Map<String, double>> recordedByMonthByDriverId,
  }) driverCashProfitContext() {
    final List<Map<String, dynamic>> entries = <Map<String, dynamic>>[];
    for (final List<Map<String, dynamic>> driverEntries
        in _driverCashEntriesByDriverId.values) {
      entries.addAll(driverEntries);
    }
    return (
      todayByDriverId: Map<String, double>.from(_driverCashAmountByDriverId),
      yesterdayByDriverId: buildDriverCashYesterdayByDriver(entries),
      recordedOnDayByDriverId: buildDriverCashRecordedOnDayByDriver(entries),
      recordedByMonthByDriverId: buildDriverCashRecordedByMonthByDriver(entries),
    );
  }

  double _expensesTotalForDriverToday(String? driverId) =>
      _expensesAmountToday(driverId: driverId);

  /// إضافة مصروف (نموذج UI).
  Map<String, dynamic> addExpense({
    String? vehicleId,
    required double amount,
    String? note,
    String? receiptFilename,
    bool hasReceipt = false,
  }) {
    _ensureInitialExpenses();
    final String? driverId = vehicleId != null && vehicleId.isNotEmpty
        ? vehicleById(vehicleId)['driverId']?.toString()
        : PrototypeSession.current?.id;
    final Map<String, dynamic> row = <String, dynamic>{
      'id': 'ex_${_expenses.length + 1}',
      'amount': amount,
      'note': note?.trim() ?? '',
      'vehicleId': vehicleId,
      'driverId': driverId,
      'hasReceipt': hasReceipt,
      if (receiptFilename != null && receiptFilename.isNotEmpty)
        'receiptFilename': receiptFilename,
      'createdAt': _now,
    };
    _expenses.add(row);
    _persist();
    return row;
  }

  bool deleteExpense(String id) {
    final int idx = _expenses.indexWhere(
      (Map<String, dynamic> e) => e['id']?.toString() == id,
    );
    if (idx < 0) {
      return false;
    }
    _expenses.removeAt(idx);
    _persist();
    return true;
  }

  void _ensureInitialReturns() {}

  List<Map<String, dynamic>> get returns {
    _ensureInitialReturns();
    return List<Map<String, dynamic>>.from(_returns);
  }

  /// تسجيل إرجاع من سطر تحميل مفتوح (سائق — يظهر في قائمة المرتجعات).
  Map<String, dynamic> addReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) {
    _ensureInitialVehicleLoad();
    _ensureInitialReturns();
    if (quantityReturned <= 0) {
      throw StateError('INVALID_QUANTITY');
    }
    Map<String, dynamic>? load;
    for (final Map<String, dynamic> l in _vehicleLoads) {
      if (l['id']?.toString() == vehicleLoadId) {
        load = l;
        break;
      }
    }
    if (load == null) {
      throw StateError('LOAD_NOT_FOUND');
    }
    if (load['status']?.toString() == 'closed') {
      throw StateError('LOAD_CLOSED');
    }
    final String driverId = _sessionDriverId();
    if (load['driverId']?.toString() != driverId) {
      throw StateError('FORBIDDEN');
    }
    final int remaining = _remainingForLoad(load);
    if (quantityReturned > remaining) {
      throw StateError('INSUFFICIENT_REMAINING');
    }
    final Map<String, dynamic> row = _recordReturnForLoad(
      load: load,
      quantityReturned: quantityReturned,
    );
    _closeLoadLineIfSettled(load);
    return row;
  }

  Map<String, dynamic> _recordReturnForLoad({
    required Map<String, dynamic> load,
    required int quantityReturned,
    bool automaticEndOfDay = false,
  }) {
    _ensureInitialReturns();
    final String driverId = load['driverId']?.toString() ?? '';
    load['quantityReturned'] =
        _intField(load, 'quantityReturned') + quantityReturned;
    load['product'] = productById(load['productId']?.toString());
    load['vehicle'] = vehicleById(load['vehicleId']?.toString());

    final Map<String, dynamic> row = <String, dynamic>{
      'id': 'ret_${_returns.length + 1}',
      'vehicleLoadId': load['id'],
      'vehicleId': load['vehicleId'],
      'vehicle': load['vehicle'],
      'driverId': driverId,
      'driver': userBrief(driverId),
      'productId': load['productId'],
      'product': load['product'],
      'quantityReturned': quantityReturned,
      'createdAt': _now.toIso8601String(),
      if (automaticEndOfDay) 'automaticEndOfDay': true,
      if (automaticEndOfDay) 'source': 'end_of_day',
    };
    _returns.add(row);
    _persist();
    return row;
  }
}
