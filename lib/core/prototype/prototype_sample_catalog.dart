part of 'prototype_sample_data.dart';

mixin _PrototypeSampleCatalog on _PrototypeSampleCore {
  /// يضمن وجود منتج في الكتالوج لكل صف تسعير سوبر أدمن (ربط بالأسماء المعيارية).
  void ensurePricingCatalogProducts() {
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
  void ensureEmptySaleWithFillingRow1Product() {
    if (resolveEmptySaleWithFillingRow1Product(products: _products) != null) {
      return;
    }
    _products.add(
      _prototypeProduct(
        id: 'p_empty_sale_with_filling_row1',
        name: kEmptySaleWithFillingRow1ProductApiName,
        unitType: 'piece',
        price: 0.5,
        stationStock: 0,
      ),
    );
  }

  /// بيع فارغ — زيادة «مع تعبئة» للمنتجين ٤–٥.
  void ensureEmptySaleWithFillingRow2Product() {
    if (resolveEmptySaleWithFillingRow2Product(products: _products) != null) {
      return;
    }
    _products.add(
      _prototypeProduct(
        id: 'p_empty_sale_with_filling_row2',
        name: kEmptySaleWithFillingRow2ProductApiName,
        unitType: 'piece',
        price: 0.5,
        stationStock: 0,
      ),
    );
  }

  /// تعبئة المحطة — عمود جالون ([kFillingGallonProductApiName]).
  void ensureFillingGallonProduct() {
    if (resolveFillingGallonProduct(products: _products) != null) {
      return;
    }
    final Map<String, dynamic>? load = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: 0,
    );
    _products.add(
      _prototypeProduct(
        id: 'p_filling_gallon',
        name: kFillingGallonProductApiName,
        unitType: 'gallon',
        price: parseDynamicDouble(load?['price']) ?? 12,
        stationStock: 0,
      ),
    );
  }

  /// تعبئة المحطة — عمود قارورة ([kFillingBottleProductApiName]).
  void ensureFillingBottleProduct() {
    if (resolveFillingBottleProduct(products: _products) != null) {
      return;
    }
    final Map<String, dynamic>? load = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: 1,
    );
    _products.add(
      _prototypeProduct(
        id: 'p_filling_bottle',
        name: kFillingBottleProductApiName,
        unitType: 'bottle',
        price: parseDynamicDouble(load?['price']) ?? 25,
        stationStock: 0,
      ),
    );
  }

  /// جالون صغير (تعبئة/سيارة) — منفصل عن «ج صغير فارغ».
  void ensureWaterSmallGallonProduct() {
    if (resolveWaterSmallGallonProduct(products: _products) != null) {
      return;
    }
    _products.add(
      _prototypeProduct(
        id: 'p_water_small_gallon',
        name: kWaterSmallGallonProductApiName,
        unitType: 'gallon',
        price: 10,
        stationStock: 0,
      ),
    );
  }

  /// قاروره صغير (تعبئة/سيارة) — منفصل عن «ق صغير فارغ».
  void ensureWaterSmallBottleProduct() {
    if (resolveWaterSmallBottleProduct(products: _products) != null) {
      return;
    }
    _products.add(
      _prototypeProduct(
        id: 'p_water_small_bottle',
        name: kWaterSmallBottleProductApiName,
        unitType: 'bottle',
        price: 15,
        stationStock: 0,
      ),
    );
  }

  /// منتج بيع «جالون متجر» — سعر مستقل؛ الخصم من حمولة جالون ٢٠ لتر.
  void ensureStoreGallonSaleProduct() {
    if (resolveStoreGallonSaleProduct(products: _products) != null) {
      return;
    }
    final Map<String, dynamic>? load = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: 0,
    );
    _products.add(
      _prototypeProduct(
        id: 'p_store_gallon',
        name: kStoreGallonProductApiName,
        unitType: 'gallon',
        price: parseDynamicDouble(load?['price']) ?? 12,
        stationStock: 0,
      ),
    );
  }

  /// منتج بيع «قاروره متجر» — سعر مستقل؛ الخصم من حمولة قارورة ٢٠ لتر.
  void ensureStoreBottleSaleProduct() {
    if (resolveStoreBottleSaleProduct(products: _products) != null) {
      return;
    }
    final Map<String, dynamic>? load = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: 1,
    );
    _products.add(
      _prototypeProduct(
        id: 'p_store_bottle',
        name: kStoreBottleProductApiName,
        unitType: 'bottle',
        price: parseDynamicDouble(load?['price']) ?? 25,
        stationStock: 0,
      ),
    );
  }

  /// منتج «مهدي متجر» للتسعير والبيع — مخزون المحطة والسيارة من «ك مهدي».
  void ensureStoreMahdiSaleProduct() {
    if (resolveStoreMahdiSaleProduct(products: _products) != null) {
      return;
    }
    _products.add(
      _prototypeProduct(
        id: 'p_store_mahdi',
        name: kStoreMahdiProductApiName,
        unitType: 'carton',
        price: 200,
        stationStock: 0,
      ),
    );
  }

  bool setProductPrice(String productId, double price) {
    for (final Map<String, dynamic> p in _products) {
      if (p['id']?.toString() == productId) {
        p['price'] = price;
        _persist();
        return true;
      }
    }
    return false;
  }

  void addProduct(Map<String, dynamic> product) {
    _products.add(product);
    _persist();
  }

  bool deleteProduct(String id) {
    final int idx =
        _products.indexWhere((Map<String, dynamic> p) => p['id'] == id);
    if (idx < 0) {
      return false;
    }
    _products.removeAt(idx);
    _persist();
    return true;
  }

  Map<String, dynamic> createVehicle({
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

  void deleteVehicle(String id) {
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

  UserEntity? authenticate({
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

  UserEntity? userEntityById(String id) {
    for (final Map<String, dynamic> u in _users) {
      if (u['id']?.toString() == id) {
        return userEntityFromMap(u);
      }
    }
    return null;
  }

  UserEntity previewUserForRole(String role) {
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

  UserEntity userEntityFromMap(Map<String, dynamic> u) => UserEntity(
        id: u['id']!.toString(),
        email: u['email']?.toString() ?? '',
        fullName: u['fullName']?.toString() ?? '',
        role: u['role']?.toString() ?? 'admin',
        phone: u['phone']?.toString(),
        isActive: u['isActive'] as bool? ?? true,
      );

  String? createUser({
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

  String? updateUser({
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

  String? setUserActive({
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

  String? resetUserPassword({required String email}) {
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

  void _syncSessionIfCurrentUser(String uid) {
    if (PrototypeSession.current?.id != uid) {
      return;
    }
    final UserEntity? refreshed = userEntityById(uid);
    if (refreshed != null && refreshed.isActive) {
      unawaited(PrototypeSession.signIn(refreshed));
    }
  }

  /// خصم مخزون المحطة بعد بيع/دين — يطابق صفوف رصيد المحطة (عدة أسماء API لنفس البند).
  void deductStationStockForSale({
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
  bool setStationStock(String productId, int stationStock) {
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
  void upsertStationBalanceRow({
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
      _prototypeProduct(
        id: 'p_row_$rowIndex',
        name: spec.name,
        unitType: spec.unitType,
        price: 1,
        stationStock: stationStock,
      ),
    );
    _persist();
  }

  List<Map<String, dynamic>> get vehicles =>
      List<Map<String, dynamic>>.from(_vehicles);

  Map<String, dynamic> vehicleById(String? id) {
    for (final Map<String, dynamic> v in vehicles) {
      if (v['id'] == id) {
        return Map<String, dynamic>.from(v);
      }
    }
    return vehicles.first;
  }

  Map<String, dynamic> productById(String? id) {
    for (final Map<String, dynamic> p in _products) {
      if (p['id'] == id) {
        return Map<String, dynamic>.from(p);
      }
    }
    return Map<String, dynamic>.from(_products.first);
  }

  Map<String, dynamic> userBrief(String? id) {
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
}
