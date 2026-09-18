part of 'prototype_sample_data.dart';

mixin _PrototypeSampleLoads on _PrototypeSampleSales {
  List<Map<String, dynamic>> get vehicleLoads {
    _ensureInitialVehicleLoad();
    reconcileVehicleLoadStatuses();
    return List<Map<String, dynamic>>.from(_vehicleLoads);
  }

  /// ساعة إغلاق يوم العمل (محلي) — بعدها يُسجَّل إرجاع تلقائي لتحميلات **اليوم الحالي**.
  final int kVehicleLoadEndOfDayCloseHour = 23;

  /// يطابق `status` مع الكميات ويُغلق تحميلات الأيام المنتهية.
  void reconcileVehicleLoadStatuses({DateTime? asOf}) {
    closeEndedDayVehicleLoads(asOf: asOf);
    for (final Map<String, dynamic> load in _vehicleLoads) {
      _closeLoadLineIfSettled(load);
    }
  }

  /// نهاية اليوم: إرجاع تلقائي للمتبقي على السيارة ثم إغلاق السطر.
  void closeEndedDayVehicleLoads({DateTime? asOf}) {
    _ensureInitialVehicleLoad();
    final DateTime now = asOf ?? DateTime.now();
    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (load['status']?.toString() == 'closed') {
        continue;
      }
      if (!_loadEligibleForEndOfDayClose(load, now: now)) {
        continue;
      }
      _applyEndOfDayAutomaticReturn(load);
    }
  }

  DateTime? _loadCreatedAt(Map<String, dynamic> load) {
    final Object? raw = load['createdAt'];
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  /// إغلاق تلقائي: أيام سابقة، أو نفس اليوم بعد [kVehicleLoadEndOfDayCloseHour]
  /// لسطور أُنشئت **قبل** ساعة الإغلاق (حمولة جديدة بعد ٢٣:٠٠ تبقى مفتوحة حتى اليوم التالي).
  bool _loadEligibleForEndOfDayClose(
    Map<String, dynamic> load, {
    required DateTime now,
  }) {
    final DateTime loadDay = _loadDateOnly(load);
    final DateTime today = _dateOnly(now);
    if (loadDay.isAfter(today)) {
      return false;
    }
    if (loadDay.isBefore(today)) {
      return true;
    }
    if (now.hour < kVehicleLoadEndOfDayCloseHour) {
      return false;
    }
    final DateTime? created = _loadCreatedAt(load);
    if (created == null) {
      return false;
    }
    final DateTime cutoff = DateTime(
      loadDay.year,
      loadDay.month,
      loadDay.day,
      kVehicleLoadEndOfDayCloseHour,
    );
    return created.isBefore(cutoff);
  }

  /// نهاية اليوم: سجل إرجاعاً في قائمة المرتجعات (ليس تصفيراً صامتاً).
  void _applyEndOfDayAutomaticReturn(Map<String, dynamic> load) {
    if (load['status']?.toString() == 'closed') {
      return;
    }
    final String loadId = load['id']?.toString() ?? '';
    if (loadId.isNotEmpty && _hasEndOfDayReturnForLoad(loadId)) {
      _closeLoadLineIfSettled(load);
      if (load['status']?.toString() != 'closed') {
        load['status'] = 'closed';
      }
      return;
    }
    final int rem = _remainingForLoad(load);
    if (rem > 0) {
      _recordReturnForLoad(
        load: load,
        quantityReturned: rem,
        automaticEndOfDay: true,
      );
      _closeLoadLineIfSettled(load);
      return;
    }
    load['status'] = 'closed';
  }

  bool _hasEndOfDayReturnForLoad(String vehicleLoadId) {
    for (final Map<String, dynamic> r in _returns) {
      if (r['vehicleLoadId']?.toString() != vehicleLoadId) {
        continue;
      }
      if (r['automaticEndOfDay'] == true || r['source']?.toString() == 'end_of_day') {
        return true;
      }
    }
    return false;
  }

  void _ensureInitialVehicleLoad() {}

  /// إنشاء سطر تحميل في الذاكرة (نموذج UI).
  Map<String, dynamic> addVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
    String? loadBatchId,
  }) {
    _ensureInitialVehicleLoad();
    reconcileVehicleLoadStatuses();
    final Map<String, dynamic> vehicle = vehicleById(vehicleId);
    final Map<String, dynamic> product = productById(productId);
    final DateTime dayOnly = _parseLoadDateYmd(loadDate);
    final Map<String, dynamic> row = <String, dynamic>{
      'id': 'load_${_vehicleLoads.length + 1}',
      'vehicleId': vehicle['id'],
      'vehicle': vehicle,
      'driverId': driverId,
      'driver': userBrief(driverId),
      'productId': product['id'],
      'product': product,
      'quantityLoaded': quantityLoaded,
      'quantitySold': 0,
      'quantityReturned': 0,
      'status': 'open',
      'loadDate': dayOnly,
      'createdAt': DateTime.now(),
      'createdBy': userBrief(PrototypeSession.current?.id ?? 'proto_admin'),
      if (loadBatchId != null && loadBatchId.isNotEmpty)
        'loadBatchId': loadBatchId,
    };
    _vehicleLoads.add(row);
    _persist();
    return row;
  }

  DateTime _parseLoadDateYmd(String loadDate) {
    final String t = loadDate.trim();
    final RegExpMatch? m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
    if (m != null) {
      return DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
    }
    final DateTime? parsed = DateTime.tryParse(t);
    if (parsed != null) {
      return _dateOnly(parsed.toLocal());
    }
    return _today;
  }

  /// يضمن وجود منتج لصف التحميل ويعيد معرّفه.
  String ensureVehicleLoadRowProductId(int rowIndex) {
    final Map<String, dynamic>? existing = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: rowIndex,
    );
    if (existing != null) {
      return existing['id']!.toString();
    }
    final ({String name, String unitType}) spec =
        vehicleLoadSeedSpecForRow(rowIndex);
    final String id = 'p_vload_$rowIndex';
    addProduct(
      _prototypeProduct(
        id: id,
        name: spec.name,
        unitType: spec.unitType,
        price: 1,
        stationStock: 0,
      ),
    );
    return id;
  }

  List<Map<String, dynamic>> get vehicleSales {
    _ensureInitialVehicleSales();
    return List<Map<String, dynamic>>.from(_vehicleSales);
  }

  void _ensureInitialVehicleSales() {}

  /// سداد ديون المركبة: إغلاق سجل الدين + تسجيل مبيع اليوم **بدون** خصم مخزون.
  int repayVehicleDebtForDebtor({
    required String debtorName,
    String? paymentMethod,
  }) {
    _ensureInitialVehicleSales();
    final String want = debtorName.trim();
    if (want.isEmpty) {
      return 0;
    }
    var count = 0;
    final DateTime now = _now;
    final List<Map<String, dynamic>> toSettle = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (vs['isDebt'] != true || vs['repaidAt'] != null) {
        continue;
      }
      if (vs['debtorName']?.toString().trim() != want) {
        continue;
      }
      toSettle.add(vs);
    }
    final String method =
        (paymentMethod?.trim().isNotEmpty == true)
            ? paymentMethod!.trim().toLowerCase()
            : 'cash';
    for (final Map<String, dynamic> debt in toSettle) {
      debt['repaidAt'] = now.toIso8601String();
      addVehicleSale(
        vehicleId: debt['vehicleId']?.toString() ?? 'v1',
        productId: debt['productId']?.toString() ?? '',
        quantity: (debt['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: ((debt['unitPrice'] as num?) ?? 0).toDouble(),
        saleDestination: debt['saleDestination']?.toString() ?? 'home',
        debtorName: debt['debtorName']?.toString(),
        isDebt: false,
        skipLoadDeduction: true,
        settledFromDebtSaleId: debt['id']?.toString(),
        paymentMethod: method,
      );
      count++;
    }
    if (count > 0) {
      _persist();
    }
    return count;
  }

  /// خصم الكمية من حمولة السيارة المفتوحة (يزيد `quantitySold`).
  void deductVehicleLoadForSale({
    required String productId,
    required int quantity,
    String? driverId,
    String? vehicleId,
  }) {
    _ensureInitialVehicleLoad();
    if (quantity <= 0) {
      return;
    }
    final Map<String, dynamic> soldProduct = productById(productId);
    final String soldName = soldProduct['name']?.toString() ?? '';
    var remaining = quantity;

    bool lineMatches(Map<String, dynamic> load) {
      if (load['status']?.toString() == 'closed') {
        return false;
      }
      if (driverId != null &&
          driverId.isNotEmpty &&
          load['driverId']?.toString() != driverId) {
        return false;
      }
      if (vehicleId != null &&
          vehicleId.isNotEmpty &&
          load['vehicleId']?.toString() != vehicleId) {
        return false;
      }
      if (load['productId']?.toString() == productId) {
        return true;
      }
      final String loadName =
          (load['product'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
      if (loadName.isEmpty || soldName.isEmpty) {
        return false;
      }
      return stationBalanceProductNamesMatch(loadName, soldName);
    }

    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (remaining <= 0) {
        break;
      }
      if (!lineMatches(load)) {
        continue;
      }
      final int onLoad = _remainingForLoad(load);
      if (onLoad <= 0) {
        _closeLoadLineIfSettled(load);
        continue;
      }
      final int take = remaining < onLoad ? remaining : onLoad;
      load['quantitySold'] = _intField(load, 'quantitySold') + take;
      load['product'] = productById(load['productId']?.toString());
      _closeLoadLineIfSettled(load);
      remaining -= take;
    }
    _persist();
  }

  Map<String, dynamic> addVehicleSale({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String saleDestination = 'home',
    String? stockProductId,
    String? debtorName,
    bool isDebt = false,
    bool skipLoadDeduction = false,
    String? settledFromDebtSaleId,
    String? paymentMethod,
  }) {
    _ensureInitialVehicleSales();
    final Map<String, dynamic> vehicle = vehicleById(vehicleId);
    final String? driverId = vehicle['driverId']?.toString();
    final Map<String, dynamic> product = productById(productId);
    if (!skipLoadDeduction) {
      final String deductFrom = stockProductId ?? productId;
      deductVehicleLoadForSale(
        productId: deductFrom,
        quantity: quantity,
        driverId: driverId,
        vehicleId: vehicleId,
      );
    }
    final Map<String, dynamic> row = <String, dynamic>{
      'id': 'vs_${_vehicleSales.length + 1}',
      'vehicleId': vehicle['id'],
      'vehicle': vehicle,
      'driverId': driverId,
      'driver': userBrief(driverId),
      'productId': product['id'],
      'product': product,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': unitPrice * quantity,
      'saleDestination': saleDestination,
      'isDebt': isDebt,
      if (!isDebt &&
          paymentMethod != null &&
          paymentMethod.trim().isNotEmpty)
        'paymentMethod': paymentMethod.trim(),
      if (debtorName != null && debtorName.trim().isNotEmpty)
        'debtorName': debtorName.trim(),
      if (settledFromDebtSaleId != null && settledFromDebtSaleId.isNotEmpty)
        'settledFromDebtSaleId': settledFromDebtSaleId,
      'repaidAt': null,
      'createdAt': DateTime.now().toIso8601String(),
      if (settledFromDebtSaleId != null && settledFromDebtSaleId.isNotEmpty)
        'saleKind': 'debt_repayment',
    };
    _vehicleSales.add(row);
    _persist();
    return row;
  }
}
