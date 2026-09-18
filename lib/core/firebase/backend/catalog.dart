part of '../amethyst_firebase_backend.dart';

mixin _FirebaseCatalogOps on _FirebaseBackendHelpers {
  Future<Map<String, dynamic>> listProducts({int page = 1, int limit = 100}) async {
    await _requireStaffOrDriver();
    final List<Map<String, dynamic>> all = await _loadActiveProductsList();
    return _paginate(all, page: page, limit: limit);
  }

  Future<List<Map<String, dynamic>>> _loadActiveProductsList() async {
    if (_activeProductsCache != null && _catalogCacheFresh(_activeProductsCachedAt)) {
      return _activeProductsCache!;
    }
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.products)
        .where('isActive', isEqualTo: true)
        .get();
    final List<Map<String, dynamic>> all =
        snap.docs.map(mapProductDoc).toList(growable: false)
          ..sort(
            (Map<String, dynamic> a, Map<String, dynamic> b) =>
                (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
          );
    _activeProductsCache = all;
    _activeProductsCachedAt = DateTime.now();
    return all;
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String unitType,
    required double price,
    int stationStock = 0,
  }) async {
    await _requireSuperAdmin();
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestorePaths.products).doc();
    final Map<String, dynamic> data = <String, dynamic>{
      'name': name,
      'unitType': unitType,
      'price': price,
      'stationStock': stationStock,
      'isActive': true,
      'createdAt': serverTimestamp(),
      'updatedAt': serverTimestamp(),
    };
    await ref.set(data);
    clearCatalogCache();
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    return mapProductDoc(doc);
  }

  Future<void> patchProductStationStock({
    required String id,
    required int stationStock,
  }) async {
    await _requireStaff();
    await _db.collection(FirestorePaths.products).doc(id).update(<String, dynamic>{
      'stationStock': stationStock,
      'updatedAt': serverTimestamp(),
    });
    clearCatalogCache();
    final Map<String, dynamic> actor = await _auth.currentActor();
    await _logStockMovement(
      productId: id,
      type: 'adjustment',
      quantity: stationStock,
      reason: 'station_balance',
      referenceId: null,
      actorId: actor['id'] as String,
    );
  }

  Future<void> deductStationStockForSale({
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return;
    }
    try {
      await _requireStaffOrDriver();
      final Map<String, dynamic> actor = await _auth.currentActor();
      final DocumentSnapshot<Map<String, dynamic>> productSnap = await _db
          .collection(FirestorePaths.products)
          .doc(productId)
          .get();
      if (!productSnap.exists) {
        throw ApiException('Product not found', code: 'NOT_FOUND');
      }
      final Map<String, dynamic> product = mapProductDoc(productSnap);
      final int stock = (product['stationStock'] as num?)?.toInt() ?? 0;
      if (stock < quantity) {
        throw ApiException('Insufficient station stock', code: 'INSUFFICIENT_STOCK');
      }
      final WriteBatch batch = _db.batch();
      batch.update(productSnap.reference, <String, dynamic>{
        'stationStock': FieldValue.increment(-quantity),
        'updatedAt': serverTimestamp(),
      });
      final DocumentReference<Map<String, dynamic>> movRef =
          _db.collection(FirestorePaths.stockMovements).doc();
      batch.set(movRef, <String, dynamic>{
        'productId': productId,
        'type': 'out',
        'quantity': quantity,
        'reason': 'station_sale',
        'referenceId': null,
        'createdById': actor['id'],
        'createdAt': serverTimestamp(),
      });
      await batch.commit();
      clearCatalogCache();
    } on ApiException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _apiExceptionFromFirebase(e);
    }
  }

  Future<void> upsertStationBalanceRowStock({
    required int rowIndex,
    required int stationStock,
  }) async {
    await saveStationBalanceRows(
      rows: <Map<String, dynamic>>[
        <String, dynamic>{'rowIndex': rowIndex, 'stationStock': stationStock},
      ],
    );
  }

  /// حفظ عدة صفوف رصيد دفعة واحدة — جلب المنتجات مرة واحدة + WriteBatch.
  Future<void> saveStationBalanceRows({
    required List<Map<String, dynamic>> rows,
  }) async {
    if (rows.isEmpty) {
      return;
    }
    await _requireStaff();
    final Map<String, dynamic> actor = await _auth.currentActor();
    final String actorId = actor['id'] as String;
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.products)
        .where('isActive', isEqualTo: true)
        .get();
    final List<Map<String, dynamic>> products = snap.docs
        .map(mapProductDoc)
        .toList(growable: false);

    final WriteBatch batch = _db.batch();
    var wrote = false;
    for (final Map<String, dynamic> row in rows) {
      final int rowIndex = (row['rowIndex'] as num).toInt();
      final int stationStock = (row['stationStock'] as num).toInt();
      final Map<String, dynamic>? existing = resolveStationBalanceProduct(
        products: products,
        rowIndex: rowIndex,
      );
      if (existing != null) {
        final String id = existing['id']!.toString();
        batch.update(
          _db.collection(FirestorePaths.products).doc(id),
          <String, dynamic>{
            'stationStock': stationStock,
            'updatedAt': serverTimestamp(),
          },
        );
        batch.set(
          _db.collection(FirestorePaths.stockMovements).doc(),
          <String, dynamic>{
            'productId': id,
            'type': 'adjustment',
            'quantity': stationStock,
            'reason': 'station_balance',
            'referenceId': null,
            'createdById': actorId,
            'createdAt': serverTimestamp(),
          },
        );
        wrote = true;
        continue;
      }
      final ({String name, String unitType}) spec =
          stationBalanceSeedSpecForRow(rowIndex);
      final DocumentReference<Map<String, dynamic>> productRef =
          _db.collection(FirestorePaths.products).doc();
      batch.set(productRef, <String, dynamic>{
        'name': spec.name,
        'unitType': spec.unitType,
        'price': 1,
        'stationStock': stationStock,
        'isActive': true,
        'createdAt': serverTimestamp(),
        'updatedAt': serverTimestamp(),
      });
      products.add(<String, dynamic>{
        'id': productRef.id,
        'name': spec.name,
        'unitType': spec.unitType,
        'price': 1,
        'stationStock': stationStock,
        'isActive': true,
      });
      wrote = true;
    }
    if (wrote) {
      await batch.commit();
      clearCatalogCache();
    }
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    double? price,
  }) async {
    await _requireStaff();
    if (price != null) {
      await _db.collection(FirestorePaths.products).doc(id).update(<String, dynamic>{
        'price': price,
        'updatedAt': serverTimestamp(),
      });
    }
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestorePaths.products).doc(id).get();
    return mapProductDoc(doc);
  }

  Future<void> deleteProduct(String id) async {
    await _requireSuperAdmin();
    await _db.collection(FirestorePaths.products).doc(id).update(<String, dynamic>{
      'isActive': false,
      'updatedAt': serverTimestamp(),
    });
    clearCatalogCache();
  }

  Future<Map<String, dynamic>> listVehicles({int page = 1, int limit = 100}) async {
    await _requireStaffOrDriver();
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestorePaths.vehicles).orderBy('vehicleNumber').get();
    final List<Map<String, dynamic>> all =
        snap.docs.map(mapVehicleDoc).toList(growable: false);
    await _attachDriversToVehicles(all);
    return _paginate(all, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createVehicle({
    required String vehicleNumber,
    String? driverId,
    String? notes,
  }) async {
    await _requireSuperAdmin();
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestorePaths.vehicles).doc();
    await ref.set(<String, dynamic>{
      'vehicleNumber': vehicleNumber,
      'driverId': driverId,
      'isActive': true,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'createdAt': serverTimestamp(),
      'updatedAt': serverTimestamp(),
    });
    clearCatalogCache();
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    return mapVehicleDoc(doc);
  }

  Future<void> deleteVehicle(String id) async {
    await _requireSuperAdmin();
    await _db.collection(FirestorePaths.vehicles).doc(id).update(<String, dynamic>{
      'isActive': false,
      'updatedAt': serverTimestamp(),
    });
    clearCatalogCache();
  }

  Future<Map<String, dynamic>> listUsers({int page = 1, int limit = 100}) async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    final String role = actor['role']?.toString() ?? '';
    if (role != 'super_admin' && role != 'admin') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    final List<String> roles = role == 'super_admin'
        ? <String>['super_admin', 'admin', 'driver']
        : <String>['admin', 'driver'];
    final List<QuerySnapshot<Map<String, dynamic>>> snaps =
        await Future.wait(<Future<QuerySnapshot<Map<String, dynamic>>>>[
      for (final String r in roles)
        _db.collection(FirestorePaths.users).where('role', isEqualTo: r).get(),
    ]);
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    for (final QuerySnapshot<Map<String, dynamic>> snap in snaps) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        all.add(mapUserDoc(doc));
      }
    }
    all.sort(
      (Map<String, dynamic> a, Map<String, dynamic> b) =>
          (a['fullName'] as String? ?? '').compareTo(b['fullName'] as String? ?? ''),
    );
    return _paginate(all, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    await _requireSuperAdmin();
    final UserEntity user = await _auth.createUserAccount(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      phone: _syntheticPhone(),
    );
    return <String, dynamic>{
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'role': user.role,
      'phone': user.phone,
      'isActive': user.isActive,
    };
  }

  Future<void> deleteUser(String id) async {
    await _requireSuperAdmin();
    await _db.collection(FirestorePaths.users).doc(id).update(<String, dynamic>{
      'isActive': false,
      'updatedAt': serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> _loadHydratedVehicleLoadsList(
    Map<String, dynamic> actor,
  ) async {
    final String scopeKey =
        actor['role'] == 'driver' ? 'driver:${actor['id']}' : 'staff';
    if (_hydratedVehicleLoadsCache != null &&
        _hydratedVehicleLoadsScopeKey == scopeKey &&
        _catalogCacheFresh(_hydratedVehicleLoadsCachedAt)) {
      return _hydratedVehicleLoadsCache!;
    }
    Query<Map<String, dynamic>> q = _db.collection(FirestorePaths.vehicleLoads);
    if (actor['role'] == 'driver') {
      q = q.where('driverId', isEqualTo: actor['id']);
    }
    final QuerySnapshot<Map<String, dynamic>> snap =
        await q.orderBy('createdAt', descending: true).get();
    final List<Map<String, dynamic>> items =
        await _mapVehicleLoadsBatch(snap.docs);
    _hydratedVehicleLoadsCache = items;
    _hydratedVehicleLoadsCachedAt = DateTime.now();
    _hydratedVehicleLoadsScopeKey = scopeKey;
    return items;
  }

  Future<Map<String, dynamic>> listVehicleLoads({
    int page = 1,
    int limit = 100,
    String? status,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    final List<Map<String, dynamic>> all =
        await _loadHydratedVehicleLoadsList(actor);
    final DateTime? from = parseYmd(dateFrom);
    final DateTime? to = parseYmd(dateTo);
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> row in all) {
      if (actor['role'] != 'driver' &&
          driverId != null &&
          driverId.isNotEmpty &&
          row['driverId']?.toString() != driverId) {
        continue;
      }
      if (vehicleId != null &&
          vehicleId.isNotEmpty &&
          row['vehicleId']?.toString() != vehicleId) {
        continue;
      }
      if (status != null &&
          status.isNotEmpty &&
          row['status']?.toString() != status) {
        continue;
      }
      if (from != null || to != null) {
        final DateTime? loadDate = timestampToDate(row['loadDate']);
        if (loadDate == null) {
          continue;
        }
        final DateTime day = startOfDay(loadDate);
        if (from != null && day.isBefore(startOfDay(from))) {
          continue;
        }
        if (to != null && day.isAfter(endOfDay(to))) {
          continue;
        }
      }
      items.add(row);
    }
    return _paginate(items, page: page, limit: limit.clamp(1, 100));
  }

  Future<String?> driverAssignedVehicleId() async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    if (actor['role'] != 'driver') {
      return null;
    }
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.vehicles)
        .where('driverId', isEqualTo: actor['id'])
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      return null;
    }
    return snap.docs.first.id;
  }

  Future<Map<String, dynamic>> driverCurrentLoad() async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    if (actor['role'] != 'driver') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    final String driverId = actor['id']!.toString();
    final QuerySnapshot<Map<String, dynamic>> vehicles = await _db
        .collection(FirestorePaths.vehicles)
        .where('driverId', isEqualTo: driverId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (vehicles.docs.isEmpty) {
      throw ApiException('No vehicle assigned', code: 'NOT_FOUND');
    }
    final Map<String, dynamic> vehicle = mapVehicleDoc(vehicles.docs.first);
    await _attachDriversToVehicles(<Map<String, dynamic>>[vehicle]);

    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.vehicleLoads)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .get();
    if (snap.docs.isEmpty) {
      throw ApiException('No open load', code: 'NOT_FOUND');
    }
    final List<Map<String, dynamic>> hydrated =
        await _mapVehicleLoadsBatch(snap.docs);
    final List<Map<String, dynamic>> loadLines = hydrated
        .where(
          (Map<String, dynamic> line) => vehicleLoadRemainingQty(line) > 0,
        )
        .toList(growable: false);
    if (loadLines.isEmpty) {
      throw ApiException('No open load', code: 'NOT_FOUND');
    }
    final List<Map<String, dynamic>> loads =
        aggregateDriverLoadsByProduct(loadLines);
    return <String, dynamic>{
      'vehicle': vehicle,
      'loadLines': loadLines,
      'loads': loads,
    };
  }

  Future<void> createVehicleLoadsBatch({
    required String vehicleId,
    required String driverId,
    required String loadDate,
    required List<Map<String, dynamic>> lines,
    String? loadBatchId,
  }) async {
    if (lines.isEmpty) {
      throw ApiException('No load lines', code: 'EMPTY_LINES');
    }
    try {
      final Map<String, dynamic> actor = await _auth.currentActor();
      final Timestamp loadDateTs =
          Timestamp.fromDate(parseYmd(loadDate) ?? DateTime.now());
      final WriteBatch batch = _db.batch();
      var wrote = false;
      for (final Map<String, dynamic> line in lines) {
        final Object? rawProductId = line['productId'];
        final Object? rawQty = line['quantityLoaded'];
        if (rawProductId is! String || rawProductId.isEmpty) {
          throw ApiException('Invalid product', code: 'NOT_FOUND');
        }
        if (rawQty is! num) {
          throw ApiException('Invalid load line', code: 'VALIDATION');
        }
        final int qty = rawQty.toInt();
        if (qty <= 0) {
          continue;
        }
        final DocumentReference<Map<String, dynamic>> ref =
            _db.collection(FirestorePaths.vehicleLoads).doc();
        batch.set(ref, <String, dynamic>{
          'vehicleId': vehicleId,
          'driverId': driverId,
          'productId': rawProductId,
          'quantityLoaded': qty,
          'quantityReturned': 0,
          'quantitySold': 0,
          'loadDate': loadDateTs,
          'status': 'open',
          'createdById': actor['id'],
          if (loadBatchId != null && loadBatchId.isNotEmpty)
            'loadBatchId': loadBatchId,
          'createdAt': serverTimestamp(),
          'updatedAt': serverTimestamp(),
        });
        wrote = true;
      }
      if (!wrote) {
        throw ApiException('No load lines', code: 'EMPTY_LINES');
      }
      await batch.commit();
      clearCatalogCache();
    } on ApiException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _apiExceptionFromFirebase(e);
    }
  }

  Future<Map<String, dynamic>> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
    String? loadBatchId,
  }) async {
    await createVehicleLoadsBatch(
      vehicleId: vehicleId,
      driverId: driverId,
      loadDate: loadDate,
      loadBatchId: loadBatchId,
      lines: <Map<String, dynamic>>[
        <String, dynamic>{
          'productId': productId,
          'quantityLoaded': quantityLoaded,
        },
      ],
    );
    return <String, dynamic>{'ok': true};
  }
}
