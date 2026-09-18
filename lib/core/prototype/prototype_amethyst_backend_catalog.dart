part of 'prototype_amethyst_backend.dart';

mixin _PrototypeBackendCatalogOps on _PrototypeAmethystBackendBase {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await PrototypeSampleData.instance.ensureLoaded();
    final UserEntity? user = PrototypeSampleData.instance.authenticate(
      email: email,
      password: password,
    );
    if (user == null) {
      throw ApiException(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        code: 'INVALID_CREDENTIALS',
      );
    }
    await PrototypeSession.signIn(user);
    return PrototypeSampleData.instance.meFromSession();
  }

  Future<Map<String, dynamic>> me() async {
    if (!PrototypeSession.isSignedIn) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    return PrototypeSampleData.instance.meFromSession();
  }

  Future<Map<String, dynamic>> listProducts({int page = 1, int limit = 100}) async {
    PrototypeSampleData.instance.ensurePricingCatalogProducts();
    return _paginate(PrototypeSampleData.instance.products, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String unitType,
    required double price,
    int stationStock = 0,
  }) async {
    final String id = 'p_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> p = <String, dynamic>{
      'id': id,
      'name': name,
      'unitType': unitType,
      'type': unitType,
      'price': price,
      'stationStock': stationStock,
      'stock': stationStock,
      'isActive': true,
    };
    PrototypeSampleData.instance.addProduct(p);
    return Map<String, dynamic>.from(p);
  }

  Future<void> patchProductStationStock({
    required String id,
    required int stationStock,
  }) async {
    if (!PrototypeSampleData.instance.setStationStock(id, stationStock)) {
      throw ApiException('Product not found', code: 'NOT_FOUND');
    }
  }

  Future<void> deductStationStockForSale({
    required String productId,
    required int quantity,
  }) async {
    try {
      PrototypeSampleData.instance.deductStationStockForSale(
        productId: productId,
        quantity: quantity,
      );
    } on StateError catch (e) {
      if (e.message == 'INSUFFICIENT_STOCK') {
        throw ApiException('Insufficient stock', code: 'INSUFFICIENT_STOCK');
      }
      rethrow;
    }
  }

  Future<void> upsertStationBalanceRowStock({
    required int rowIndex,
    required int stationStock,
  }) async {
    PrototypeSampleData.instance.upsertStationBalanceRow(
      rowIndex: rowIndex,
      stationStock: stationStock,
    );
  }

  Future<void> saveStationBalanceRows({
    required List<Map<String, dynamic>> rows,
  }) async {
    for (final Map<String, dynamic> row in rows) {
      PrototypeSampleData.instance.upsertStationBalanceRow(
        rowIndex: (row['rowIndex'] as num).toInt(),
        stationStock: (row['stationStock'] as num).toInt(),
      );
    }
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    double? price,
  }) async {
    if (price != null && !PrototypeSampleData.instance.setProductPrice(id, price)) {
      throw ApiException('Product not found', code: 'NOT_FOUND');
    }
    return PrototypeSampleData.instance.productById(id);
  }

  Future<void> deleteProduct(String id) async {
    await PrototypeSampleData.instance.ensureLoaded();
    if (!PrototypeSampleData.instance.deleteProduct(id)) {
      throw ApiException('Product not found', code: 'NOT_FOUND');
    }
  }

  Future<Map<String, dynamic>> listVehicles({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.instance.vehicles, page: page, limit: limit);

  Future<Map<String, dynamic>> createVehicle({
    required String vehicleNumber,
    String? driverId,
    String? notes,
  }) async {
    await PrototypeSampleData.instance.ensureLoaded();
    final Map<String, dynamic> row = PrototypeSampleData.instance.createVehicle(
      vehicleNumber: vehicleNumber,
      driverId: driverId,
      notes: notes,
    );
    return row;
  }

  Future<void> deleteVehicle(String id) async {
    await PrototypeSampleData.instance.ensureLoaded();
    try {
      PrototypeSampleData.instance.deleteVehicle(id);
    } on StateError catch (e) {
      switch (e.message) {
        case 'VEHICLE_HAS_OPEN_LOAD':
          throw ApiException(
            'Cannot delete vehicle with open load',
            code: 'VEHICLE_HAS_OPEN_LOAD',
          );
        case 'NOT_FOUND':
          throw ApiException('Vehicle not found', code: 'NOT_FOUND');
        default:
          rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> listUsers({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.instance.users, page: page, limit: limit);

  Future<Map<String, dynamic>> listVehicleLoads({
    int page = 1,
    int limit = 100,
    String? status,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) async {
    List<Map<String, dynamic>> items = PrototypeSampleData.instance.vehicleLoads;
    if (vehicleId != null && vehicleId.isNotEmpty) {
      items = items
          .where((Map<String, dynamic> l) => l['vehicleId'] == vehicleId)
          .toList(growable: false);
    }
    if (driverId != null && driverId.isNotEmpty) {
      items = items
          .where((Map<String, dynamic> l) => l['driverId'] == driverId)
          .toList(growable: false);
    }
    if (dateFrom != null || dateTo != null) {
      items = items
          .where(
            (Map<String, dynamic> l) => apiDateMatchesRange(
              createdAt: l['loadDate'] ?? l['createdAt'],
              dateFrom: dateFrom,
              dateTo: dateTo,
            ),
          )
          .toList(growable: false);
    }
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> driverCurrentLoad() async =>
      PrototypeSampleData.instance.driverCurrentLoad();

  Future<String?> driverAssignedVehicleId() async =>
      PrototypeSampleData.instance.vehicleIdForSessionDriver();

  Future<Map<String, dynamic>> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
    String? loadBatchId,
  }) async {
    final Map<String, dynamic> row = PrototypeSampleData.instance.addVehicleLoad(
      vehicleId: vehicleId,
      driverId: driverId,
      productId: productId,
      quantityLoaded: quantityLoaded,
      loadDate: loadDate,
      loadBatchId: loadBatchId,
    );
    return <String, dynamic>{'item': row};
  }

  Future<void> createVehicleLoadsBatch({
    required String vehicleId,
    required String driverId,
    required String loadDate,
    required List<Map<String, dynamic>> lines,
    String? loadBatchId,
  }) async {
    for (final Map<String, dynamic> line in lines) {
      PrototypeSampleData.instance.addVehicleLoad(
        vehicleId: vehicleId,
        driverId: driverId,
        productId: line['productId'] as String,
        quantityLoaded: (line['quantityLoaded'] as num).toInt(),
        loadDate: loadDate,
        loadBatchId: loadBatchId,
      );
    }
  }

  Future<Map<String, dynamic>> listStationSales({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    final DateTime? from = dateFrom == null || dateFrom.isEmpty
        ? null
        : DateTime.tryParse(dateFrom);
    final DateTime? to = dateTo == null || dateTo.isEmpty
        ? null
        : DateTime.tryParse(dateTo);
    final List<Map<String, dynamic>> items = PrototypeSampleData.instance.stationSales
        .where((Map<String, dynamic> row) {
          if (from == null && to == null) {
            return true;
          }
          final Object? raw = row['createdAt'];
          final DateTime? created = raw is DateTime
              ? raw
              : DateTime.tryParse(raw?.toString() ?? '');
          if (created == null) {
            return false;
          }
          if (from != null && created.isBefore(from)) {
            return false;
          }
          if (to != null && created.isAfter(DateTime(to.year, to.month, to.day, 23, 59, 59))) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    return _paginate(items, page: page, limit: limit);
  }

  Future<void> createStationSalesBatch({
    required List<Map<String, dynamic>> lines,
    bool fillingSale = false,
    String? paymentMethod,
  }) async {
    for (final Map<String, dynamic> line in lines) {
      await createStationSale(
        productId: line['productId'] as String,
        quantity: (line['quantity'] as num).toInt(),
        unitPrice: (line['unitPrice'] as num).toDouble(),
        fillingSale: fillingSale,
        fillingLineSlot: (line['fillingLineSlot'] as num?)?.toInt(),
        note: line['note'] as String?,
        paymentMethod: paymentMethod,
      );
    }
  }

  Future<Map<String, dynamic>> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
    String? paymentMethod,
  }) async {
    final bool skipStock = fillingSale &&
        fillingLineSlot != null &&
        kStationFillingSkipStockColumnIndices.contains(fillingLineSlot);
    try {
      final Map<String, dynamic> row = PrototypeSampleData.instance.addStationSale(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        note: note,
        paymentMethod: paymentMethod,
        skipStockDeduction: skipStock,
      );
      return <String, dynamic>{'item': row};
    } on StateError catch (e) {
      if (e.message == 'INSUFFICIENT_STOCK') {
        throw ApiException(
          'Insufficient station stock',
          code: 'INSUFFICIENT_STOCK',
        );
      }
      rethrow;
    }
  }

  Future<void> createStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) async {
    PrototypeSampleData.instance.addStationDebtEntries(
      debtorName: debtorName,
      lines: lines,
    );
  }

  Future<Map<String, dynamic>> listStationDebtEntriesForSummary({
    int page = 1,
    int limit = 100,
  }) async {
    final List<Map<String, dynamic>> items = PrototypeSampleData.instance.stationDebtEntries
        .where(isStationDebtSummaryEntry)
        .toList(growable: false);
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> listStationDebtEntries({
    int page = 1,
    int limit = 100,
  }) async {
    final List<Map<String, dynamic>> items =
        PrototypeSampleData.instance.openStationDebtEntries;
    final UserEntity? user = PrototypeSession.current;
    if (user?.role == 'driver') {
      final String driverId = user!.id;
      return _paginate(
        items
            .where(
              (Map<String, dynamic> e) =>
                  isDriverVehicleDebtEntry(e, driverId: driverId),
            )
            .toList(growable: false),
        page: page,
        limit: limit,
      );
    }
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> repayStationDebt({
    required String debtorName,
    String? paymentMethod,
  }) async {
    final int n = PrototypeSampleData.instance.repayStationDebtForDebtor(
      debtorName: debtorName,
      paymentMethod: paymentMethod,
    );
    if (n <= 0) {
      throw ApiException('No unpaid station debt', code: 'NOT_FOUND');
    }
    return <String, dynamic>{'repaidCount': n};
  }

  Future<Map<String, dynamic>> repayStationDebtFromVehicle({
    required String debtorName,
    String? paymentMethod,
  }) async {
    final int n = PrototypeSampleData.instance.repayVehicleDebtForDebtor(
      debtorName: debtorName,
      paymentMethod: paymentMethod,
    );
    if (n <= 0) {
      throw ApiException('No unpaid vehicle debt', code: 'NOT_FOUND');
    }
    return <String, dynamic>{'repaidCount': n};
  }

  Future<Map<String, dynamic>> listVehicleSales({
    int page = 1,
    int limit = 100,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) async {
    List<Map<String, dynamic>> items = PrototypeSampleData.instance.vehicleSales;
    if (vehicleId != null && vehicleId.isNotEmpty) {
      items = items
          .where((Map<String, dynamic> s) => s['vehicleId'] == vehicleId)
          .toList(growable: false);
    }
    if (dateFrom != null || dateTo != null) {
      items = items
          .where(
            (Map<String, dynamic> s) => apiDateMatchesRange(
              createdAt: s['createdAt'],
              dateFrom: dateFrom,
              dateTo: dateTo,
            ),
          )
          .toList(growable: false);
    }
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createVehicleSale({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String saleDestination = 'home',
    String? stockProductId,
    String? debtorName,
    bool isDebt = false,
    bool skipLoadDeduction = false,
  }) async {
    final Map<String, dynamic> row = PrototypeSampleData.instance.addVehicleSale(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      unitPrice: unitPrice,
      saleDestination: saleDestination,
      stockProductId: stockProductId,
      debtorName: debtorName,
      isDebt: isDebt,
      skipLoadDeduction: skipLoadDeduction,
    );
    return <String, dynamic>{'item': row};
  }

  Future<void> createVehicleSalesBatch({
    required String vehicleId,
    required List<Map<String, dynamic>> lines,
    String saleDestination = 'home',
    String? paymentMethod,
  }) async {
    for (final Map<String, dynamic> line in lines) {
      PrototypeSampleData.instance.addVehicleSale(
        vehicleId: vehicleId,
        productId: line['productId'] as String,
        quantity: (line['quantity'] as num).toInt(),
        unitPrice: (line['unitPrice'] as num).toDouble(),
        saleDestination: saleDestination,
        stockProductId: line['stockProductId'] as String?,
        skipLoadDeduction: line['skipLoadDeduction'] == true,
        debtorName: line['debtorName'] as String?,
        isDebt: line['isDebt'] == true,
        paymentMethod: paymentMethod,
      );
      if (line['deductStationStock'] == true) {
        PrototypeSampleData.instance.deductStationStockForSale(
          productId: (line['stockProductId'] as String?) ??
              line['productId'] as String,
          quantity: (line['quantity'] as num).toInt(),
        );
      }
    }
  }
}
