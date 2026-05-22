import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_catalog.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';

/// Static sample maps for UI prototype lists and dashboards.
final class PrototypeSampleData {
  PrototypeSampleData._();

  static final DateTime _now = DateTime.now();
  static DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  static List<Map<String, dynamic>> get users => <Map<String, dynamic>>[
        _user(
          id: 'proto_super',
          fullName: 'مدير عام (عرض)',
          email: 'super@preview.local',
          phone: '+201000000001',
          role: 'super_admin',
        ),
        _user(
          id: 'proto_admin',
          fullName: 'مسؤول المحطة',
          email: 'admin@preview.local',
          phone: '+201000000002',
          role: 'admin',
        ),
        _user(
          id: 'proto_admin2',
          fullName: 'مسؤول مساعد',
          email: 'admin2@preview.local',
          phone: '+201000000004',
          role: 'admin',
        ),
        _user(
          id: 'proto_driver',
          fullName: 'سائق (عرض)',
          email: 'driver@preview.local',
          phone: '+201000000003',
          role: 'driver',
        ),
        _user(
          id: 'proto_driver2',
          fullName: 'أحمد السائق',
          email: 'driver2@preview.local',
          phone: '+201000000005',
          role: 'driver',
        ),
      ];

  static final List<Map<String, dynamic>> _products = <Map<String, dynamic>>[
    _product(
      id: 'p_water',
      name: 'قاروره ٢٠ لتر',
      unitType: 'bottle',
      price: 25,
      stationStock: 0,
    ),
    _product(
      id: 'p_mahdi_carton',
      name: 'ك مهدي',
      unitType: 'carton',
      price: 180,
      stationStock: 0,
    ),
    _product(
      id: 'p_gallon',
      name: 'جالون ٢٠ لتر',
      unitType: 'bottle',
      price: 12,
      stationStock: 0,
    ),
    _product(
      id: 'p_coupon50',
      name: 'Coupon 3',
      unitType: 'coupon',
      price: 0,
      stationStock: 0,
    ),
  ];

  static List<Map<String, dynamic>> get products =>
      List<Map<String, dynamic>>.from(_products);

  static bool _pricingCatalogEnsured = false;

  /// يضمن وجود منتج في الكتالوج لكل صف تسعير سوبر أدمن (ربط بالأسماء المعيارية).
  static void ensurePricingCatalogProducts() {
    if (_pricingCatalogEnsured) {
      return;
    }
    _pricingCatalogEnsured = true;
    for (final int rowIndex in kStationPricingBalanceRowIndices) {
      final Map<String, dynamic>? existing = resolveStationBalanceProduct(
        products: _products,
        rowIndex: rowIndex,
      );
      if (existing != null) {
        continue;
      }
      upsertStationBalanceRow(rowIndex: rowIndex, stationStock: 0);
    }
    ensureStoreGallonSaleProduct();
    ensureStoreBottleSaleProduct();
    ensureStoreMahdiSaleProduct();
  }

  /// منتج بيع «جالون متجر» — سعر مستقل؛ الخصم من حمولة جالون ٢٠ لتر.
  static void ensureStoreGallonSaleProduct() {
    if (resolveStoreGallonSaleProduct(products: _products) != null) {
      return;
    }
    final Map<String, dynamic>? load = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: 0,
    );
    _products.add(
      _product(
        id: 'p_store_gallon',
        name: kStoreGallonProductApiName,
        unitType: 'gallon',
        price: parseDynamicDouble(load?['price']) ?? 12,
        stationStock: 0,
      ),
    );
  }

  /// منتج بيع «قاروره متجر» — سعر مستقل؛ الخصم من حمولة قارورة ٢٠ لتر.
  static void ensureStoreBottleSaleProduct() {
    if (resolveStoreBottleSaleProduct(products: _products) != null) {
      return;
    }
    final Map<String, dynamic>? load = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: 1,
    );
    _products.add(
      _product(
        id: 'p_store_bottle',
        name: kStoreBottleProductApiName,
        unitType: 'bottle',
        price: parseDynamicDouble(load?['price']) ?? 25,
        stationStock: 0,
      ),
    );
  }

  /// منتج «مهدي متجر» للتسعير والبيع — مخزون المحطة والسيارة من «ك مهدي».
  static void ensureStoreMahdiSaleProduct() {
    if (resolveStoreMahdiSaleProduct(products: _products) != null) {
      return;
    }
    _products.add(
      _product(
        id: 'p_store_mahdi',
        name: kStoreMahdiProductApiName,
        unitType: 'carton',
        price: 200,
        stationStock: 0,
      ),
    );
  }

  static bool setProductPrice(String productId, double price) {
    for (final Map<String, dynamic> p in _products) {
      if (p['id']?.toString() == productId) {
        p['price'] = price;
        return true;
      }
    }
    return false;
  }

  static void addProduct(Map<String, dynamic> product) {
    _products.add(product);
  }

  /// تحديث مخزون المحطة في الذاكرة (نموذج UI).
  static bool setStationStock(String productId, int stationStock) {
    for (final Map<String, dynamic> p in _products) {
      if (p['id']?.toString() == productId) {
        p['stationStock'] = stationStock;
        p['stock'] = stationStock;
        return true;
      }
    }
    return false;
  }

  /// إنشاء أو تحديث منتج لصف رصيد المحطة (عرض فقط).
  static void upsertStationBalanceRow({
    required int rowIndex,
    required int stationStock,
  }) {
    final Map<String, dynamic>? existing = resolveStationBalanceProduct(
      products: _products,
      rowIndex: rowIndex,
    );
    if (existing != null) {
      setStationStock(existing['id']!.toString(), stationStock);
      return;
    }
    final ({String name, String unitType}) spec =
        stationBalanceSeedSpecForRow(rowIndex);
    _products.add(
      _product(
        id: 'p_row_$rowIndex',
        name: spec.name,
        unitType: spec.unitType,
        price: 1,
        stationStock: stationStock,
      ),
    );
  }

  static List<Map<String, dynamic>> get vehicles => <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'v1',
          'vehicleNumber': 'أ ب ج 1234',
          'driverId': 'proto_driver',
          'isActive': true,
          'notes': 'مركبة العرض',
        },
        <String, dynamic>{
          'id': 'v2',
          'vehicleNumber': 'د هـ و 5678',
          'driverId': 'proto_driver2',
          'isActive': true,
          'notes': null,
        },
      ];

  static Map<String, dynamic> vehicleById(String? id) {
    for (final Map<String, dynamic> v in vehicles) {
      if (v['id'] == id) {
        return Map<String, dynamic>.from(v);
      }
    }
    return vehicles.first;
  }

  static Map<String, dynamic> productById(String? id) {
    for (final Map<String, dynamic> p in _products) {
      if (p['id'] == id) {
        return Map<String, dynamic>.from(p);
      }
    }
    return Map<String, dynamic>.from(_products.first);
  }

  static Map<String, dynamic> userBrief(String? id) {
    for (final Map<String, dynamic> u in users) {
      if (u['id'] == id) {
        return <String, dynamic>{
          'id': u['id'],
          'fullName': u['fullName'],
          'email': u['email'],
        };
      }
    }
    return <String, dynamic>{
      'id': id ?? 'unknown',
      'fullName': 'مستخدم',
      'email': '',
    };
  }

  static final List<Map<String, dynamic>> _stationSales =
      <Map<String, dynamic>>[];

  static void _ensureInitialStationSales() {}

  static List<Map<String, dynamic>> get stationSales {
    _ensureInitialStationSales();
    return List<Map<String, dynamic>>.from(_stationSales);
  }

  static Map<String, dynamic> addStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    String? note,
    String? settledFromDebtId,
    bool skipStockDeduction = false,
  }) {
    _ensureInitialStationSales();
    final Map<String, dynamic> product = productById(productId);
    final bool skipStock = skipStockDeduction ||
        (settledFromDebtId != null && settledFromDebtId.isNotEmpty);
    if (!skipStock && quantity > 0) {
      final int current = _intField(product, 'stationStock');
      if (quantity > current) {
        throw StateError('INSUFFICIENT_STOCK');
      }
      setStationStock(productId, current - quantity);
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
      if (settledFromDebtId != null && settledFromDebtId.isNotEmpty)
        'settledFromDebtId': settledFromDebtId,
      'createdAt': _now,
    };
    _stationSales.add(row);
    return row;
  }

  /// سداد دين المحطة: إغلاق السجل + مبيع محطة اليوم (بدون خصم مخزون مرة أخرى).
  static int repayStationDebtForDebtor({required String debtorName}) {
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
    for (final Map<String, dynamic> debt in toSettle) {
      debt['repaidAt'] = now;
      addStationSale(
        productId: debt['productId']?.toString() ?? '',
        quantity: (debt['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: ((debt['unitPrice'] as num?) ?? 0).toDouble(),
        note: 'سداد دين — $want',
        settledFromDebtId: debt['id']?.toString(),
      );
      count++;
    }
    return count;
  }

  static final List<Map<String, dynamic>> _stationDebtEntries =
      <Map<String, dynamic>>[];

  static void _ensureInitialStationDebt() {}

  static List<Map<String, dynamic>> get stationDebtEntries {
    _ensureInitialStationDebt();
    return List<Map<String, dynamic>>.from(_stationDebtEntries);
  }

  /// ديون مفتوحة: سجلات محطة + مبيعات سيارة مسجّلة كدين.
  static List<Map<String, dynamic>> get openStationDebtEntries {
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

  static Map<String, dynamic> _vehicleSaleAsDebtEntry(
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
  static void addStationDebtEntries({
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
      final Map<String, dynamic> product = productById(productId);
      _stationDebtEntries.add(
        <String, dynamic>{
          'id': 'debt_${_stationDebtEntries.length + 1}_${created.millisecondsSinceEpoch}',
          'debtorName': debtorName.trim(),
          'productId': product['id'],
          'product': product,
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
  }

  static final List<Map<String, dynamic>> _vehicleLoads =
      <Map<String, dynamic>>[];

  static List<Map<String, dynamic>> get vehicleLoads {
    _ensureInitialVehicleLoad();
    reconcileVehicleLoadStatuses();
    return List<Map<String, dynamic>>.from(_vehicleLoads);
  }

  /// ساعة إغلاق يوم العمل (محلي) — بعدها يُسجَّل إرجاع تلقائي لتحميلات **اليوم الحالي**.
  static const int kVehicleLoadEndOfDayCloseHour = 23;

  /// يطابق `status` مع الكميات ويُغلق تحميلات الأيام المنتهية.
  static void reconcileVehicleLoadStatuses({DateTime? asOf}) {
    closeEndedDayVehicleLoads(asOf: asOf);
    for (final Map<String, dynamic> load in _vehicleLoads) {
      _closeLoadLineIfSettled(load);
    }
  }

  /// نهاية اليوم: إرجاع تلقائي للمتبقي على السيارة ثم إغلاق السطر.
  static void closeEndedDayVehicleLoads({DateTime? asOf}) {
    _ensureInitialVehicleLoad();
    final DateTime now = asOf ?? DateTime.now();
    final DateTime today = _dateOnly(now);
    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (load['status']?.toString() == 'closed') {
        continue;
      }
      final DateTime loadDay = _loadDateOnly(load);
      if (loadDay.isAfter(today)) {
        continue;
      }
      if (!_loadBusinessDayEnded(loadDay: loadDay, now: now)) {
        continue;
      }
      _applyEndOfDayAutomaticReturn(load);
    }
  }

  static bool _loadBusinessDayEnded({
    required DateTime loadDay,
    required DateTime now,
  }) {
    final DateTime today = _dateOnly(now);
    if (loadDay.isBefore(today)) {
      return true;
    }
    if (loadDay == today && now.hour >= kVehicleLoadEndOfDayCloseHour) {
      return true;
    }
    return false;
  }

  /// نهاية اليوم: سجل إرجاعاً في قائمة المرتجعات (ليس تصفيراً صامتاً).
  static void _applyEndOfDayAutomaticReturn(Map<String, dynamic> load) {
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

  static bool _hasEndOfDayReturnForLoad(String vehicleLoadId) {
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

  static void _ensureInitialVehicleLoad() {}

  /// إنشاء سطر تحميل في الذاكرة (نموذج UI).
  static Map<String, dynamic> addVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
  }) {
    _ensureInitialVehicleLoad();
    final Map<String, dynamic> vehicle = vehicleById(vehicleId);
    final Map<String, dynamic> product = productById(productId);
    final DateTime parsedDate = DateTime.tryParse(loadDate) ?? _today;
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
      'loadDate': parsedDate,
      'createdAt': _now,
      'createdBy': userBrief(PrototypeSession.current?.id ?? 'proto_admin'),
    };
    _vehicleLoads.add(row);
    return row;
  }

  /// يضمن وجود منتج لصف التحميل ويعيد معرّفه.
  static String ensureVehicleLoadRowProductId(int rowIndex) {
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
      _product(
        id: id,
        name: spec.name,
        unitType: spec.unitType,
        price: 1,
        stationStock: 0,
      ),
    );
    return id;
  }

  static final List<Map<String, dynamic>> _vehicleSales =
      <Map<String, dynamic>>[];

  static List<Map<String, dynamic>> get vehicleSales {
    _ensureInitialVehicleSales();
    return List<Map<String, dynamic>>.from(_vehicleSales);
  }

  static void _ensureInitialVehicleSales() {}

  /// سداد ديون المركبة: إغلاق سجل الدين + تسجيل مبيع اليوم **بدون** خصم مخزون.
  static int repayVehicleDebtForDebtor({required String debtorName}) {
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
      );
      count++;
    }
    return count;
  }

  /// خصم الكمية من حمولة السيارة المفتوحة (يزيد `quantitySold`).
  static void deductVehicleLoadForSale({
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
  }

  static Map<String, dynamic> addVehicleSale({
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
      if (debtorName != null && debtorName.trim().isNotEmpty)
        'debtorName': debtorName.trim(),
      if (settledFromDebtSaleId != null && settledFromDebtSaleId.isNotEmpty)
        'settledFromDebtSaleId': settledFromDebtSaleId,
      'repaidAt': null,
      'createdAt': _now.toIso8601String(),
    };
    _vehicleSales.add(row);
    return row;
  }

  static final List<Map<String, dynamic>> _expenses = <Map<String, dynamic>>[];

  static void _ensureInitialExpenses() {}

  static List<Map<String, dynamic>> get expenses {
    _ensureInitialExpenses();
    return List<Map<String, dynamic>>.from(_expenses);
  }

  static double _expensesTotalForDriverToday(String? driverId) =>
      _expensesAmountToday(driverId: driverId);

  /// إضافة مصروف (نموذج UI).
  static Map<String, dynamic> addExpense({
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
    return row;
  }

  static final List<Map<String, dynamic>> _returns = <Map<String, dynamic>>[];

  static void _ensureInitialReturns() {}

  static List<Map<String, dynamic>> get returns {
    _ensureInitialReturns();
    return List<Map<String, dynamic>>.from(_returns);
  }

  /// تسجيل إرجاع من سطر تحميل مفتوح (سائق — يظهر في قائمة المرتجعات).
  static Map<String, dynamic> addReturn({
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

  static Map<String, dynamic> _recordReturnForLoad({
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
    return row;
  }

  static Map<String, dynamic> getDashboardSuperAdmin() {
    final double stationToday = _stationSalesAmountToday();
    final double vehicleToday = _vehicleSalesAmountToday();
    final double salesToday = stationToday + vehicleToday;
    final double expensesToday = _expensesAmountToday();
    final double expensesMonth = _expensesAmountThisMonth();
    final double salesMonth =
        _stationSalesAmountThisMonth() + _vehicleSalesAmountThisMonth();
    final double profitToday = salesToday - expensesToday;
    final double monthlyCarton = _stationSalesAmountThisMonthCarton() +
        _vehicleSalesAmountThisMonth(cartonOnly: true);
    final List<Map<String, dynamic>> debtPreview = _openDebtPreview();
    final List<Map<String, dynamic>> lowStock = _lowStockProducts();
    final int remainingStock = _totalStationStock();
    final int remainingOnVehicles = _totalRemainingOnVehicles();
    return <String, dynamic>{
      'role': 'super_admin',
      'metrics': <String, dynamic>{
        'totalSalesToday': salesToday,
        'stationSalesToday': stationToday,
        'vehicleSalesToday': vehicleToday,
        'totalExpensesToday': expensesToday,
        'totalMonthlyExpenses': expensesMonth,
        'totalProfitToday': profitToday,
        'totalMonthlySales': salesMonth,
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
      'totalMonthlySales': salesMonth,
      'totalMonthlyCartonSales': monthlyCarton,
      'remainingStationStock': remainingStock,
      'remainingOnVehicles': remainingOnVehicles,
      'lowStockProducts': lowStock,
      'stationDebtOpenPreview': debtPreview,
    };
  }

  static Map<String, dynamic> getSuperAdminCartonSummary({
    int? year,
    int? month,
  }) {
    final DateTime now = DateTime.now();
    final int y = year ?? now.year;
    final int m = month ?? now.month;
    return _cartonMonthlySummary(DateTime(y, m));
  }

  static Map<String, dynamic> getDashboardAdmin() => <String, dynamic>{
        'role': 'admin',
        'stationSalesToday': _stationSalesAmountToday(),
        'vehicleLoadsToday': _vehicleLoadsCountToday(),
        'openDebtCount': openStationDebtEntries.length,
        'productsCount': products.length,
      };

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _loadDateOnly(Map<String, dynamic> load) {
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

  static int _intField(Map<String, dynamic> map, String key) {
    final Object? v = map[key];
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int _remainingForLoad(Map<String, dynamic> load) {
    final int loaded = _intField(load, 'quantityLoaded');
    final int sold = _intField(load, 'quantitySold');
    final int returned = _intField(load, 'quantityReturned');
    final int remaining = loaded - sold - returned;
    return remaining < 0 ? 0 : remaining;
  }

  /// يغلق سطر التحميل عندما لا يبقى شيء على السيارة (مبيع + مرتجع = المحمّل).
  static void _closeLoadLineIfSettled(Map<String, dynamic> load) {
    if (_remainingForLoad(load) <= 0) {
      load['status'] = 'closed';
    }
  }

  static DateTime? _rowDateOnly(Map<String, dynamic> row) {
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

  static bool _isSameCalendarDay(DateTime? dt, DateTime day) =>
      dt != null &&
      dt.year == day.year &&
      dt.month == day.month &&
      dt.day == day.day;

  static bool _isSameCalendarMonth(DateTime? dt, DateTime ref) =>
      dt != null && dt.year == ref.year && dt.month == ref.month;

  static double _rowMoney(Map<String, dynamic> row) =>
      (row['totalAmount'] as num?)?.toDouble() ??
      (row['amount'] as num?)?.toDouble() ??
      0;

  static bool _isCashVehicleSale(Map<String, dynamic> vs) =>
      vs['isDebt'] != true;

  static bool _isCartonRow(Map<String, dynamic> row) {
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

  static bool _vehicleCartonSaleIsStore(Map<String, dynamic> vs) {
    if (vs['saleDestination']?.toString() == 'store') {
      return true;
    }
    final Map<String, dynamic>? product = vs['product'] is Map<String, dynamic>
        ? vs['product'] as Map<String, dynamic>
        : null;
    return isStoreMahdiProductName(product?['name']?.toString());
  }

  static double _stationSalesAmountToday() {
    var sum = 0.0;
    for (final Map<String, dynamic> s in _stationSales) {
      if (_isSameCalendarDay(_rowDateOnly(s), _today)) {
        sum += _rowMoney(s);
      }
    }
    return sum;
  }

  static double _stationSalesAmountThisMonth() {
    var sum = 0.0;
    for (final Map<String, dynamic> s in _stationSales) {
      if (_isSameCalendarMonth(_rowDateOnly(s), _now)) {
        sum += _rowMoney(s);
      }
    }
    return sum;
  }

  static double _stationSalesAmountThisMonthCarton() {
    var sum = 0.0;
    for (final Map<String, dynamic> s in _stationSales) {
      if (!_isCartonRow(s) || !_isSameCalendarMonth(_rowDateOnly(s), _now)) {
        continue;
      }
      sum += _rowMoney(s);
    }
    return sum;
  }

  static double _vehicleSalesAmountToday({String? driverId}) {
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

  static double _vehicleSalesAmountThisMonth({bool cartonOnly = false}) {
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

  static double _expensesAmountToday({String? driverId}) {
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

  static double _expensesAmountThisMonth({String? driverId}) {
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

  static int _totalStationStock() {
    var sum = 0;
    for (final Map<String, dynamic> p in _products) {
      sum += _intField(p, 'stationStock');
    }
    return sum;
  }

  static int _totalRemainingOnVehicles() {
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

  static List<Map<String, dynamic>> _openDebtPreview() {
    final Map<String, double> totals = <String, double>{};
    final Map<String, int> counts = <String, int>{};
    for (final Map<String, dynamic> e in openStationDebtEntries) {
      final String name = e['debtorName']?.toString().trim() ?? '';
      if (name.isEmpty) {
        continue;
      }
      totals[name] = (totals[name] ?? 0) + _rowMoney(e);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return totals.entries
        .map(
          (MapEntry<String, double> e) => <String, dynamic>{
            'debtorName': e.key,
            'totalAmount': e.value,
            'entryCount': counts[e.key] ?? 0,
          },
        )
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _lowStockProducts({int threshold = 20}) =>
      _products
          .where(
            (Map<String, dynamic> p) => _intField(p, 'stationStock') < threshold,
          )
          .map((Map<String, dynamic> p) => Map<String, dynamic>.from(p))
          .toList(growable: false);

  static int _vehicleLoadsCountToday() {
    var count = 0;
    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (_isSameCalendarDay(_loadDateOnly(load), _today)) {
        count++;
      }
    }
    return count;
  }

  static Map<String, dynamic> _cartonMonthlySummary(DateTime monthRef) {
    final Map<String, dynamic> carton = productById('p_mahdi_carton');
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
      'cartonStock': _intField(carton, 'stationStock'),
      'monthlyCartonExpensesTotalAmount': cartonExpenses,
      'monthlyCartonSalesTotalAmount': monthlyCartonSales,
      'monthlyCartonSalesHomeQty': cartonSalesQtyHome,
      'monthlyCartonSalesStoreQty': cartonSalesQtyStore,
      'cartonDebtUnpaidQuantity': debtQty,
      'cartonDebtUnpaidTotalAmount': debtAmount,
    };
  }

  static Map<String, dynamic> _enrichLoadRow(Map<String, dynamic> load) {
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

  static String _sessionDriverId() =>
      PrototypeSession.current?.id ?? 'proto_driver';

  static Map<String, dynamic>? _assignedVehicleForDriver(String driverId) {
    for (final Map<String, dynamic> v in vehicles) {
      if (v['driverId']?.toString() == driverId) {
        return Map<String, dynamic>.from(v);
      }
    }
    return null;
  }

  /// تحميلات مفتوحة للسائق؛ يُفضَّل تحميلات اليوم وإلا كل المفتوحة (نموذج عرض).
  static List<Map<String, dynamic>> _openLoadsForDriver(String driverId) {
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

  static Map<String, dynamic> driverCurrentLoad() {
    reconcileVehicleLoadStatuses();
    final String driverId = _sessionDriverId();
    final Map<String, dynamic>? vehicle = _assignedVehicleForDriver(driverId);
    if (vehicle == null) {
      return <String, dynamic>{
        'vehicle': null,
        'loads': <Map<String, dynamic>>[],
      };
    }
    final List<Map<String, dynamic>> loads = _openLoadsForDriver(driverId);
    return <String, dynamic>{
      'vehicle': vehicle,
      'loads': loads,
    };
  }

  static Map<String, dynamic> getDashboardDriver() {
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

  static Map<String, dynamic> reportsInventory() {
    var openLoadLines = 0;
    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (load['status']?.toString() != 'closed') {
        openLoadLines++;
      }
    }
    return <String, dynamic>{
      'stationProducts': products,
      'openLoadLines': openLoadLines,
      'estimatedUnitsOnVehicles': _totalRemainingOnVehicles(),
    };
  }

  static Map<String, dynamic> reportsSalesWorkingDays() {
    final Map<String, double> byDate = <String, double>{};
    void addSale(Map<String, dynamic> row) {
      final DateTime? dt = _rowDateOnly(row);
      if (dt == null) {
        return;
      }
      final String key =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      byDate[key] = (byDate[key] ?? 0) + _rowMoney(row);
    }

    for (final Map<String, dynamic> s in _stationSales) {
      addSale(s);
    }
    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (_isCashVehicleSale(vs)) {
        addSale(vs);
      }
    }

    final List<Map<String, dynamic>> days = byDate.entries
        .map(
          (MapEntry<String, double> e) => <String, dynamic>{
            'date': e.key,
            'combined': e.value,
          },
        )
        .toList(growable: false)
      ..sort(
        (Map<String, dynamic> a, Map<String, dynamic> b) =>
            (b['date'] as String).compareTo(a['date'] as String),
      );
    return <String, dynamic>{'days': days};
  }

  static Map<String, dynamic> reportsProfitLoss() {
    final double revenue = _stationSalesAmountToday() + _vehicleSalesAmountToday();
    final double expenses = _expensesAmountToday();
    return <String, dynamic>{
      'from': _today.toIso8601String(),
      'to': _today.toIso8601String(),
      'revenue': revenue,
      'expenses': expenses,
      'net': revenue - expenses,
    };
  }

  static Map<String, dynamic> reportsSalesMonthly() {
    final double stationAmount = _stationSalesAmountThisMonth();
    final double vehicleAmount = _vehicleSalesAmountThisMonth();
    return <String, dynamic>{
      'year': _now.year,
      'month': _now.month,
      'stationSales': stationSales,
      'vehicleSales': vehicleSales,
      'totals': <String, dynamic>{
        'stationAmount': stationAmount,
        'vehicleAmount': vehicleAmount,
      },
    };
  }

  static Map<String, dynamic> meFromSession() {
    final UserEntity? u = PrototypeSession.current;
    if (u == null) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{
      'id': u.id,
      'email': u.email,
      'fullName': u.fullName,
      'role': u.role,
      'phone': u.phone,
      'isActive': u.isActive,
    };
  }

  static Map<String, dynamic> _user({
    required String id,
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) =>
      <String, dynamic>{
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'isActive': true,
        'createdBy': 'proto_super',
        'createdAt': _today,
        'updatedAt': _today,
      };

  static Map<String, dynamic> _product({
    required String id,
    required String name,
    required String unitType,
    required double price,
    required int stationStock,
  }) =>
      <String, dynamic>{
        'id': id,
        'name': name,
        'unitType': unitType,
        'type': unitType,
        'price': price,
        'stationStock': stationStock,
        'stock': stationStock,
        'isActive': true,
      };

}
