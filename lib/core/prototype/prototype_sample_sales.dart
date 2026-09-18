part of 'prototype_sample_data.dart';

mixin _PrototypeSampleSales on _PrototypeSampleCatalog {
  final List<Map<String, dynamic>> _stationSales =
      <Map<String, dynamic>>[];

  void _ensureInitialStationSales() {}

  List<Map<String, dynamic>> get stationSales {
    _ensureInitialStationSales();
    return List<Map<String, dynamic>>.from(_stationSales);
  }

  Map<String, dynamic> addStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    String? note,
    String? paymentMethod,
    String? settledFromDebtId,
    bool skipStockDeduction = false,
  }) {
    _ensureInitialStationSales();
    final bool skipStock = skipStockDeduction ||
        (settledFromDebtId != null && settledFromDebtId.isNotEmpty);
    if (!skipStock && quantity > 0) {
      deductStationStockForSale(productId: productId, quantity: quantity);
    }
    final Map<String, dynamic> productAfter = productById(productId);
    final String soldById =
        PrototypeSession.current?.id ?? 'proto_admin';
    final Map<String, dynamic> row = <String, dynamic>{
      'id': 'ss_${_stationSales.length + 1}',
      'productId': productAfter['id'],
      'product': productAfter,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': unitPrice * quantity,
      'soldById': soldById,
      'soldBy': userBrief(soldById),
      'note': note,
      if (paymentMethod != null && paymentMethod.trim().isNotEmpty)
        'paymentMethod': paymentMethod.trim(),
      if (settledFromDebtId != null && settledFromDebtId.isNotEmpty)
        'settledFromDebtId': settledFromDebtId,
      'createdAt': _now,
    };
    _stationSales.add(row);
    _persist();
    return row;
  }

  /// سداد دين المحطة: إغلاق السجل + مبيع محطة اليوم (بدون خصم مخزون مرة أخرى).
  int repayStationDebtForDebtor({
    required String debtorName,
    String? paymentMethod,
  }) {
    _ensureInitialStationDebt();
    final String want = debtorName.trim();
    if (want.isEmpty) {
      return 0;
    }
    var count = 0;
    final DateTime now = _now;
    final List<Map<String, dynamic>> toSettle = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> e in _stationDebtEntries) {
      if (e['repaidAt'] != null) {
        continue;
      }
      if (e['recordingSource']?.toString() != 'station') {
        continue;
      }
      if (e['debtorName']?.toString().trim() != want) {
        continue;
      }
      toSettle.add(e);
    }
    final String method =
        (paymentMethod?.trim().isNotEmpty == true)
            ? paymentMethod!.trim().toLowerCase()
            : 'cash';
    for (final Map<String, dynamic> debt in toSettle) {
      debt['repaidAt'] = now;
      addStationSale(
        productId: debt['productId']?.toString() ?? '',
        quantity: (debt['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: ((debt['unitPrice'] as num?) ?? 0).toDouble(),
        note: 'سداد دين — $want',
        settledFromDebtId: debt['id']?.toString(),
        paymentMethod: method,
      );
      count++;
    }
    if (count > 0) {
      _persist();
    }
    return count;
  }

  final List<Map<String, dynamic>> _stationDebtEntries =
      <Map<String, dynamic>>[];

  void _ensureInitialStationDebt() {}

  List<Map<String, dynamic>> get stationDebtEntries {
    _ensureInitialStationDebt();
    return List<Map<String, dynamic>>.from(_stationDebtEntries);
  }

  /// ديون مفتوحة: سجلات محطة + مبيعات سيارة مسجّلة كدين.
  List<Map<String, dynamic>> get openStationDebtEntries {
    _ensureInitialStationDebt();
    _ensureInitialVehicleSales();
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> e in _stationDebtEntries) {
      if (e['repaidAt'] == null) {
        out.add(e);
      }
    }
    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (vs['isDebt'] == true && vs['repaidAt'] == null) {
        out.add(_vehicleSaleAsDebtEntry(vs));
      }
    }
    return out;
  }

  Map<String, dynamic> _vehicleSaleAsDebtEntry(
    Map<String, dynamic> vs,
  ) =>
      <String, dynamic>{
        'id': vs['id'],
        'debtorName': vs['debtorName'],
        'productId': vs['productId'],
        'product': vs['product'],
        'quantity': vs['quantity'],
        'unitPrice': vs['unitPrice'],
        'totalAmount': vs['totalAmount'],
        'saleDestination': vs['saleDestination']?.toString() ?? 'home',
        'recordedById': vs['driverId'],
        'recordedBy': vs['driver'],
        'recordingSource': 'vehicle',
        'vehicleSaleId': vs['id'],
        'repaidAt': vs['repaidAt'],
        'createdAt': vs['createdAt'],
      };

  /// إضافة سجلات دين (نموذج UI) — تظهر في قائمة الدين.
  void addStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) {
    _ensureInitialStationDebt();
    final String recordedById =
        PrototypeSession.current?.id ?? 'proto_driver';
    const String recordingSource = 'station';
    final DateTime created = _now;
    for (final Map<String, dynamic> line in lines) {
      final String productId = line['productId']?.toString() ?? '';
      final int quantity = (line['quantity'] as num?)?.toInt() ?? 0;
      final double unitPrice =
          ((line['unitPrice'] as num?) ?? 0).toDouble();
      if (productId.isEmpty || quantity <= 0) {
        continue;
      }
      final String stockProductId =
          line['stockProductId']?.toString().trim().isNotEmpty == true
              ? line['stockProductId']!.toString().trim()
              : productId;
      final int? fillingLineSlot =
          (line['fillingLineSlot'] as num?)?.toInt();
      final Map<String, dynamic> product = productById(productId);
      final bool fillingDebt = fillingLineSlot != null;
      if (!shouldSkipStationStockForDebtLine(
        product: product,
        fillingLineSlot: fillingLineSlot,
        fillingDebt: fillingDebt,
      )) {
        applyStationStockDeductionForSale(
          products: _products,
          productId: stockProductId,
          quantity: quantity,
        );
      }
      final Map<String, dynamic> productAfter = productById(productId);
      _stationDebtEntries.add(
        <String, dynamic>{
          'id': 'debt_${_stationDebtEntries.length + 1}_${created.millisecondsSinceEpoch}',
          'debtorName': debtorName.trim(),
          'productId': productAfter['id'],
          'product': productAfter,
          'quantity': quantity,
          'unitPrice': unitPrice,
          'totalAmount': unitPrice * quantity,
          'recordedById': recordedById,
          'recordedBy': userBrief(recordedById),
          'recordingSource': recordingSource,
          'repaidAt': null,
          'createdAt': created,
        },
      );
    }
    _persist();
  }
}
