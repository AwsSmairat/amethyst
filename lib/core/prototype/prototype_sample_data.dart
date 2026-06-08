import 'dart:async';

import 'package:amethyst/core/prototype/prototype_credentials.dart';
import 'package:amethyst/core/prototype/prototype_local_store.dart';
import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/core/firebase/station_stock_skip.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_aggregates.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_catalog.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';

/// Sample maps for UI prototype with optional local persistence.
final class PrototypeSampleData {
  PrototypeSampleData._();

  static final DateTime _now = DateTime.now();
  static DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  static bool _loaded = false;
  static Timer? _persistTimer;

  static final List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  static final List<Map<String, dynamic>> _vehicles = <Map<String, dynamic>>[];

  static Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    final Map<String, dynamic>? snapshot =
        await PrototypeLocalStore.loadSnapshot();
    if (snapshot != null) {
      _importSnapshot(snapshot);
    } else {
      _seedUsersAndVehicles();
    }
    _loaded = true;
  }

  static List<Map<String, dynamic>> get users => _users
      .map((Map<String, dynamic> u) => _publicUserMap(u))
      .toList(growable: false);

  static final List<Map<String, dynamic>> _products = <Map<String, dynamic>>[
    _product(
      id: 'p_water',
      name: 'Water Bottle',
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
      name: 'Water Gallon',
      unitType: 'gallon',
      price: 12,
      stationStock: 0,
    ),
    _product(
      id: 'p_coupon50',
      name: 'كوبون ٥٠',
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
    ensureFillingGallonProduct();
    ensureFillingBottleProduct();
    ensureWaterSmallGallonProduct();
    ensureWaterSmallBottleProduct();
    ensureEmptySaleWithFillingRow1Product();
    ensureEmptySaleWithFillingRow2Product();
    _persist();
  }

  /// بيع فارغ — زيادة «مع تعبئة» للمنتجات ١–٣.
  static void ensureEmptySaleWithFillingRow1Product() {
    if (resolveEmptySaleWithFillingRow1Product(products: _products) != null) {
      return;
    }
    _products.add(
      _product(
        id: 'p_empty_sale_with_filling_row1',
        name: kEmptySaleWithFillingRow1ProductApiName,
        unitType: 'piece',
        price: 0.5,
        stationStock: 0,
      ),
    );
  }

  /// بيع فارغ — زيادة «مع تعبئة» للمنتجين ٤–٥.
  static void ensureEmptySaleWithFillingRow2Product() {
    if (resolveEmptySaleWithFillingRow2Product(products: _products) != null) {
      return;
    }
    _products.add(
      _product(
        id: 'p_empty_sale_with_filling_row2',
        name: kEmptySaleWithFillingRow2ProductApiName,
        unitType: 'piece',
        price: 0.5,
        stationStock: 0,
      ),
    );
  }

  /// تعبئة المحطة — عمود جالون ([kFillingGallonProductApiName]).
  static void ensureFillingGallonProduct() {
    if (resolveFillingGallonProduct(products: _products) != null) {
      return;
    }
    final Map<String, dynamic>? load = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: 0,
    );
    _products.add(
      _product(
        id: 'p_filling_gallon',
        name: kFillingGallonProductApiName,
        unitType: 'gallon',
        price: parseDynamicDouble(load?['price']) ?? 12,
        stationStock: 0,
      ),
    );
  }

  /// تعبئة المحطة — عمود قارورة ([kFillingBottleProductApiName]).
  static void ensureFillingBottleProduct() {
    if (resolveFillingBottleProduct(products: _products) != null) {
      return;
    }
    final Map<String, dynamic>? load = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: 1,
    );
    _products.add(
      _product(
        id: 'p_filling_bottle',
        name: kFillingBottleProductApiName,
        unitType: 'bottle',
        price: parseDynamicDouble(load?['price']) ?? 25,
        stationStock: 0,
      ),
    );
  }

  /// جالون صغير (تعبئة/سيارة) — منفصل عن «ج صغير فارغ».
  static void ensureWaterSmallGallonProduct() {
    if (resolveWaterSmallGallonProduct(products: _products) != null) {
      return;
    }
    _products.add(
      _product(
        id: 'p_water_small_gallon',
        name: kWaterSmallGallonProductApiName,
        unitType: 'gallon',
        price: 10,
        stationStock: 0,
      ),
    );
  }

  /// قاروره صغير (تعبئة/سيارة) — منفصل عن «ق صغير فارغ».
  static void ensureWaterSmallBottleProduct() {
    if (resolveWaterSmallBottleProduct(products: _products) != null) {
      return;
    }
    _products.add(
      _product(
        id: 'p_water_small_bottle',
        name: kWaterSmallBottleProductApiName,
        unitType: 'bottle',
        price: 15,
        stationStock: 0,
      ),
    );
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
        _persist();
        return true;
      }
    }
    return false;
  }

  static void addProduct(Map<String, dynamic> product) {
    _products.add(product);
    _persist();
  }

  static bool deleteProduct(String id) {
    final int idx =
        _products.indexWhere((Map<String, dynamic> p) => p['id'] == id);
    if (idx < 0) {
      return false;
    }
    _products.removeAt(idx);
    _persist();
    return true;
  }

  static Map<String, dynamic> createVehicle({
    required String vehicleNumber,
    String? driverId,
    String? notes,
  }) {
    final Map<String, dynamic> row = <String, dynamic>{
      'id': 'v_${DateTime.now().millisecondsSinceEpoch}',
      'vehicleNumber': vehicleNumber.trim(),
      'driverId': driverId,
      'isActive': true,
      'notes': notes?.trim(),
    };
    _vehicles.add(row);
    _persist();
    return Map<String, dynamic>.from(row);
  }

  static void deleteVehicle(String id) {
    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (load['vehicleId']?.toString() != id) {
        continue;
      }
      if (load['status']?.toString() == 'closed') {
        continue;
      }
      if (_remainingForLoad(load) > 0) {
        throw StateError('VEHICLE_HAS_OPEN_LOAD');
      }
    }
    final int idx =
        _vehicles.indexWhere((Map<String, dynamic> v) => v['id'] == id);
    if (idx < 0) {
      throw StateError('NOT_FOUND');
    }
    _vehicles.removeAt(idx);
    _persist();
  }

  static UserEntity? authenticate({
    required String email,
    required String password,
  }) {
    final String wantEmail = email.trim().toLowerCase();
    for (final Map<String, dynamic> u in _users) {
      if (u['isActive'] == false) {
        continue;
      }
      final String rowEmail = u['email']?.toString().trim().toLowerCase() ?? '';
      if (rowEmail != wantEmail) {
        continue;
      }
      final String rowPassword = u['password']?.toString() ?? '';
      if (rowPassword != password) {
        return null;
      }
      return userEntityFromMap(u);
    }
    return null;
  }

  static UserEntity? userEntityById(String id) {
    for (final Map<String, dynamic> u in _users) {
      if (u['id']?.toString() == id) {
        return userEntityFromMap(u);
      }
    }
    return null;
  }

  static UserEntity previewUserForRole(String role) {
    for (final Map<String, dynamic> u in _users) {
      if (u['role']?.toString() == role && u['isActive'] != false) {
        return userEntityFromMap(u);
      }
    }
    return switch (role) {
      'super_admin' => const UserEntity(
          id: 'proto_super',
          email: 'super@preview.local',
          fullName: 'صهيب بيك',
          role: 'super_admin',
          phone: '+201000000001',
          isActive: true,
        ),
      'driver' => const UserEntity(
          id: 'proto_driver',
          email: 'driver@preview.local',
          fullName: 'سائق (عرض)',
          role: 'driver',
          phone: '+201000000003',
          isActive: true,
        ),
      _ => const UserEntity(
          id: 'proto_admin',
          email: 'admin@preview.local',
          fullName: 'مسؤول المحطة',
          role: 'admin',
          phone: '+201000000002',
          isActive: true,
        ),
    };
  }

  static UserEntity userEntityFromMap(Map<String, dynamic> u) => UserEntity(
        id: u['id']!.toString(),
        email: u['email']?.toString() ?? '',
        fullName: u['fullName']?.toString() ?? '',
        role: u['role']?.toString() ?? 'admin',
        phone: u['phone']?.toString(),
        isActive: u['isActive'] as bool? ?? true,
      );

  static String? createUser({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String role,
  }) {
    final String trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || password.isEmpty || fullName.trim().isEmpty) {
      return 'بيانات غير مكتملة';
    }
    for (final Map<String, dynamic> u in _users) {
      if (u['email']?.toString().trim().toLowerCase() == trimmedEmail) {
        return 'البريد الإلكتروني مستخدم مسبقاً';
      }
    }
    final String id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _users.add(
      _user(
        id: id,
        fullName: fullName.trim(),
        email: trimmedEmail,
        phone: phone?.trim() ?? '',
        role: role,
        password: password,
      ),
    );
    _persist();
    return null;
  }

  static String? updateUser({
    required String uid,
    required String fullName,
    String? phone,
    required String role,
  }) {
    final int idx =
        _users.indexWhere((Map<String, dynamic> u) => u['id'] == uid);
    if (idx < 0) {
      return 'المستخدم غير موجود';
    }
    _users[idx]['fullName'] = fullName.trim();
    _users[idx]['phone'] = phone?.trim() ?? '';
    _users[idx]['role'] = role;
    _users[idx]['updatedAt'] = DateTime.now();
    _syncSessionIfCurrentUser(uid);
    _persist();
    return null;
  }

  static String? setUserActive({
    required String uid,
    required bool isActive,
  }) {
    final int idx =
        _users.indexWhere((Map<String, dynamic> u) => u['id'] == uid);
    if (idx < 0) {
      return 'المستخدم غير موجود';
    }
    if (!isActive && _users[idx]['role']?.toString() == 'super_admin') {
      final int activeSuperAdmins = _users
          .where(
            (Map<String, dynamic> u) =>
                u['role']?.toString() == 'super_admin' && u['isActive'] != false,
          )
          .length;
      if (activeSuperAdmins <= 1) {
        return 'لا يمكن تعطيل آخر سوبر أدمن';
      }
    }
    _users[idx]['isActive'] = isActive;
    _users[idx]['updatedAt'] = DateTime.now();
    if (!isActive && PrototypeSession.current?.id == uid) {
      unawaited(PrototypeSession.signOut());
    } else {
      _syncSessionIfCurrentUser(uid);
    }
    _persist();
    return null;
  }

  static String? resetUserPassword({required String email}) {
    final String want = email.trim().toLowerCase();
    for (final Map<String, dynamic> u in _users) {
      if (u['email']?.toString().trim().toLowerCase() == want) {
        u['password'] = kPrototypeDefaultPassword;
        u['updatedAt'] = DateTime.now();
        _persist();
        return null;
      }
    }
    return 'البريد الإلكتروني غير موجود';
  }

  static void _syncSessionIfCurrentUser(String uid) {
    if (PrototypeSession.current?.id != uid) {
      return;
    }
    final UserEntity? refreshed = userEntityById(uid);
    if (refreshed != null && refreshed.isActive) {
      unawaited(PrototypeSession.signIn(refreshed));
    }
  }

  /// خصم مخزون المحطة بعد بيع/دين — يطابق صفوف رصيد المحطة (عدة أسماء API لنفس البند).
  static void deductStationStockForSale({
    required String productId,
    required int quantity,
  }) {
    try {
      applyStationStockDeductionForSale(
        products: _products,
        productId: productId,
        quantity: quantity,
      );
      _persist();
    } on StateError {
      throw StateError('INSUFFICIENT_STOCK');
    }
  }

  /// تحديث مخزون المحطة في الذاكرة (نموذج UI).
  static bool setStationStock(String productId, int stationStock) {
    for (final Map<String, dynamic> p in _products) {
      if (p['id']?.toString() == productId) {
        p['stationStock'] = stationStock;
        p['stock'] = stationStock;
        _persist();
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
    final List<String> rowIds = productIdsForBalanceRow(
      products: _products,
      rowIndex: rowIndex,
    );
    if (rowIds.isNotEmpty) {
      setStationStock(rowIds.first, stationStock);
      for (var i = 1; i < rowIds.length; i++) {
        setStationStock(rowIds[i], 0);
      }
      return;
    }
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
    _persist();
  }

  static List<Map<String, dynamic>> get vehicles =>
      List<Map<String, dynamic>>.from(_vehicles);

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
    if (count > 0) {
      _persist();
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

  static DateTime? _loadCreatedAt(Map<String, dynamic> load) {
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
  static bool _loadEligibleForEndOfDayClose(
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

  static DateTime _parseLoadDateYmd(String loadDate) {
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
    if (count > 0) {
      _persist();
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
    _persist();
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

  static final List<Map<String, dynamic>> _expenses = <Map<String, dynamic>>[];

  static void _ensureInitialExpenses() {}

  static List<Map<String, dynamic>> get expenses {
    _ensureInitialExpenses();
    return List<Map<String, dynamic>>.from(_expenses);
  }

  static double _stationCashAmount = 0;
  static final List<Map<String, dynamic>> _stationCashEntries =
      <Map<String, dynamic>>[];

  static double get stationCashAmount => _stationCashAmount;

  static List<Map<String, dynamic>> get stationCashEntries =>
      List<Map<String, dynamic>>.from(_stationCashEntries);

  static void setStationCashAmount({
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
    _persist();
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
    _persist();
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
      'monthlyCartonSalesTotalQty': cartonSalesQtyHome + cartonSalesQtyStore,
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

  /// مركبة السائق الحالي دون تشغيل [reconcileVehicleLoadStatuses].
  static String? vehicleIdForSessionDriver() {
    final String driverId = _sessionDriverId();
    return _assignedVehicleForDriver(driverId)?['id']?.toString();
  }

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
    final List<Map<String, dynamic>> loadLines = _openLoadsForDriver(driverId);
    final List<Map<String, dynamic>> loads =
        aggregateDriverLoadsByProduct(loadLines);
    return <String, dynamic>{
      'vehicle': vehicle,
      'loads': loads,
      'loadLines': loadLines,
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

  static Map<String, dynamic> reportsSalesMonthly({int? year, int? month}) {
    final DateTime ref = year != null && month != null
        ? DateTime(year, month, 1)
        : DateTime(_now.year, _now.month, 1);
    final List<Map<String, dynamic>> stationRows = _stationSales
        .where(
          (Map<String, dynamic> s) =>
              _isSameCalendarMonth(_rowDateOnly(s), ref),
        )
        .map((Map<String, dynamic> s) => Map<String, dynamic>.from(s))
        .toList(growable: false);
    final List<Map<String, dynamic>> vehicleRows = _vehicleSales
        .where(
          (Map<String, dynamic> vs) =>
              _isCashVehicleSale(vs) &&
              _isSameCalendarMonth(_rowDateOnly(vs), ref),
        )
        .map((Map<String, dynamic> vs) => Map<String, dynamic>.from(vs))
        .toList(growable: false);
    var stationAmount = 0.0;
    for (final Map<String, dynamic> s in stationRows) {
      stationAmount += _rowMoney(s);
    }
    var vehicleAmount = 0.0;
    for (final Map<String, dynamic> vs in vehicleRows) {
      vehicleAmount += _rowMoney(vs);
    }
    return <String, dynamic>{
      'year': ref.year,
      'month': ref.month,
      'stationSales': stationRows,
      'vehicleSales': vehicleRows,
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
    required String password,
  }) =>
      <String, dynamic>{
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'password': password,
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

  static final List<Map<String, dynamic>> _staffNotes =
      <Map<String, dynamic>>[];

  /// مسؤولو المحطة + السائقون (مستلمو الملاحظات).
  static List<Map<String, dynamic>> staffNoteRecipientOptions() {
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> u in users) {
      if (u['isActive'] == false) {
        continue;
      }
      final String role = u['role']?.toString() ?? '';
      if (role == 'admin' || role == 'driver') {
        out.add(Map<String, dynamic>.from(u));
      }
    }
    return out;
  }

  /// إنشاء ملاحظة لمسؤولي المحطة كلهم أو لسائق واحد.
  static List<Map<String, dynamic>> createStaffNotes({
    required String senderUserId,
    required String message,
    required String recipientKind,
    String? driverUserId,
  }) {
    final String text = message.trim();
    if (text.isEmpty) {
      throw StateError('EMPTY_MESSAGE');
    }
    final List<String> targetUserIds = <String>[];
    switch (recipientKind) {
      case 'all_admins':
        for (final Map<String, dynamic> u in users) {
          if (u['isActive'] == false) {
            continue;
          }
          if (u['role']?.toString() == 'admin') {
            final String? id = u['id']?.toString();
            if (id != null && id.isNotEmpty) {
              targetUserIds.add(id);
            }
          }
        }
      case 'driver':
        final String? id = driverUserId?.trim();
        if (id == null || id.isEmpty) {
          throw StateError('MISSING_DRIVER');
        }
        targetUserIds.add(id);
      default:
        throw StateError('INVALID_RECIPIENT');
    }
    if (targetUserIds.isEmpty) {
      throw StateError('NO_RECIPIENTS');
    }
    final Map<String, dynamic> fromUser = userBrief(senderUserId);
    final String createdAt = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> created = <Map<String, dynamic>>[];
    for (final String toUserId in targetUserIds) {
      if (toUserId == senderUserId) {
        continue;
      }
      final Map<String, dynamic> row = <String, dynamic>{
        'id': 'staff_note_${_staffNotes.length + 1}',
        'message': text,
        'toUserId': toUserId,
        'fromUserId': senderUserId,
        'fromUser': fromUser,
        'createdAt': createdAt,
        'readAt': null,
      };
      _staffNotes.add(row);
      created.add(Map<String, dynamic>.from(row));
    }
    if (created.isEmpty) {
      throw StateError('NO_RECIPIENTS');
    }
    _persist();
    return created;
  }

  /// أقدم ملاحظة غير مقروءة للمستخدم الحالي (تُعرض واحدة في كل مرة).
  static Map<String, dynamic>? firstUnreadStaffNoteForUser(String userId) {
    final String want = userId.trim();
    if (want.isEmpty) {
      return null;
    }
    Map<String, dynamic>? newest;
    DateTime? newestAt;
    for (final Map<String, dynamic> n in _staffNotes) {
      if (n['toUserId']?.toString() != want) {
        continue;
      }
      if (n['readAt'] != null) {
        continue;
      }
      final DateTime? at = DateTime.tryParse(n['createdAt']?.toString() ?? '');
      if (newest == null ||
          (at != null && (newestAt == null || at.isAfter(newestAt)))) {
        newest = n;
        newestAt = at;
      }
    }
    return newest == null ? null : Map<String, dynamic>.from(newest);
  }

  static void markStaffNoteRead({
    required String noteId,
    required String userId,
  }) {
    final String wantId = noteId.trim();
    final String wantUser = userId.trim();
    for (final Map<String, dynamic> n in _staffNotes) {
      if (n['id']?.toString() != wantId) {
        continue;
      }
      if (n['toUserId']?.toString() != wantUser) {
        return;
      }
      n['readAt'] = DateTime.now().toIso8601String();
      _persist();
      return;
    }
  }

  static void _seedUsersAndVehicles() {
    _users
      ..clear()
      ..addAll(<Map<String, dynamic>>[
        _user(
          id: 'proto_super',
          fullName: 'صهيب بيك',
          email: 'super@preview.local',
          phone: '+201000000001',
          role: 'super_admin',
          password: kPrototypeDefaultPassword,
        ),
        _user(
          id: 'proto_admin',
          fullName: 'مسؤول المحطة',
          email: 'admin@preview.local',
          phone: '+201000000002',
          role: 'admin',
          password: kPrototypeDefaultPassword,
        ),
        _user(
          id: 'proto_driver',
          fullName: 'سائق (عرض)',
          email: 'driver@preview.local',
          phone: '+201000000003',
          role: 'driver',
          password: kPrototypeDefaultPassword,
        ),
        _user(
          id: 'proto_driver2',
          fullName: 'أحمد السائق',
          email: 'driver2@preview.local',
          phone: '+201000000005',
          role: 'driver',
          password: kPrototypeDefaultPassword,
        ),
      ]);
    _vehicles
      ..clear()
      ..addAll(<Map<String, dynamic>>[
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
      ]);
  }

  static Map<String, dynamic> _publicUserMap(Map<String, dynamic> u) {
    final Map<String, dynamic> copy = Map<String, dynamic>.from(u);
    copy.remove('password');
    return copy;
  }

  static void _persist() {
    if (!_loaded) {
      return;
    }
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(
        PrototypeLocalStore.saveSnapshot(_exportSnapshot()),
      );
    });
  }

  static Map<String, dynamic> _exportSnapshot() => <String, dynamic>{
        'version': 1,
        'users': _encodeList(_users),
        'vehicles': _encodeList(_vehicles),
        'products': _encodeList(_products),
        'stationSales': _encodeList(_stationSales),
        'stationDebtEntries': _encodeList(_stationDebtEntries),
        'vehicleLoads': _encodeList(_vehicleLoads),
        'vehicleSales': _encodeList(_vehicleSales),
        'expenses': _encodeList(_expenses),
        'returns': _encodeList(_returns),
        'staffNotes': _encodeList(_staffNotes),
        'pricingCatalogEnsured': _pricingCatalogEnsured,
      };

  static void _importSnapshot(Map<String, dynamic> snapshot) {
    _users
      ..clear()
      ..addAll(_decodeList(snapshot['users']));
    _vehicles
      ..clear()
      ..addAll(_decodeList(snapshot['vehicles']));
    _products
      ..clear()
      ..addAll(_decodeList(snapshot['products']));
    _stationSales
      ..clear()
      ..addAll(_decodeList(snapshot['stationSales']));
    _stationDebtEntries
      ..clear()
      ..addAll(_decodeList(snapshot['stationDebtEntries']));
    _vehicleLoads
      ..clear()
      ..addAll(_decodeList(snapshot['vehicleLoads']));
    _vehicleSales
      ..clear()
      ..addAll(_decodeList(snapshot['vehicleSales']));
    _expenses
      ..clear()
      ..addAll(_decodeList(snapshot['expenses']));
    _returns
      ..clear()
      ..addAll(_decodeList(snapshot['returns']));
    _staffNotes
      ..clear()
      ..addAll(_decodeList(snapshot['staffNotes']));
    _pricingCatalogEnsured = snapshot['pricingCatalogEnsured'] == true;
    if (_users.isEmpty || _vehicles.isEmpty) {
      _seedUsersAndVehicles();
    }
    if (_products.isEmpty) {
      _products.addAll(<Map<String, dynamic>>[
        _product(
          id: 'p_water',
          name: 'Water Bottle',
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
          name: 'Water Gallon',
          unitType: 'gallon',
          price: 12,
          stationStock: 0,
        ),
        _product(
          id: 'p_coupon50',
          name: 'كوبون ٥٠',
          unitType: 'coupon',
          price: 0,
          stationStock: 0,
        ),
      ]);
    }
  }

  static List<Map<String, dynamic>> _encodeList(List<Map<String, dynamic>> rows) =>
      rows
          .map(
            (Map<String, dynamic> row) =>
                _encodeValue(row) as Map<String, dynamic>,
          )
          .toList(growable: false);

  static List<Map<String, dynamic>> _decodeList(Object? raw) {
    if (raw is! List<dynamic>) {
      return <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> row) =>
              _decodeValue(row) as Map<String, dynamic>,
        )
        .toList(growable: false);
  }

  static Object? _encodeValue(Object? value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map) {
      return value.map(
        (Object? k, Object? v) => MapEntry(k, _encodeValue(v)),
      );
    }
    if (value is List) {
      return value.map(_encodeValue).toList(growable: false);
    }
    return value;
  }

  static Object? _decodeValue(Object? value) {
    if (value is String) {
      final DateTime? dt = DateTime.tryParse(value);
      if (dt != null && value.contains('T')) {
        return dt;
      }
      return value;
    }
    if (value is Map) {
      return value.map(
        (Object? k, Object? v) => MapEntry(k, _decodeValue(v)),
      );
    }
    if (value is List) {
      return value.map(_decodeValue).toList(growable: false);
    }
    return value;
  }

}
