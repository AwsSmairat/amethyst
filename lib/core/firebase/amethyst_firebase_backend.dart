import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:amethyst/core/firebase/date_range_utils.dart';
import 'package:amethyst/core/firebase/firebase_auth_service.dart';
import 'package:amethyst/core/firebase/firebase_storage_service.dart';
import 'package:amethyst/core/firebase/firestore_mappers.dart';
import 'package:amethyst/core/firebase/firestore_paths.dart';
import 'package:amethyst/core/firebase/station_stock_skip.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final class _FirestoreTxFailure implements Exception {
  const _FirestoreTxFailure(this.code, {this.message});

  final String code;
  final String? message;
}

ApiException _apiExceptionFromFirestoreTxFailure(_FirestoreTxFailure e) {
  return ApiException(
    e.message ??
        switch (e.code) {
          'INSUFFICIENT_STOCK' => 'Insufficient station stock',
          'NOT_FOUND' => 'Product not found or inactive',
          _ => 'Transaction failed',
        },
    code: e.code,
  );
}

ApiException _apiExceptionFromFirebase(FirebaseException e) {
  return ApiException(
    e.message ?? 'Firestore error',
    code: e.code.toUpperCase(),
  );
}

final class AmethystFirebaseBackend {
  AmethystFirebaseBackend({
    FirebaseAuthService? authService,
    FirebaseStorageService? storageService,
    FirebaseFirestore? firestore,
  })  : _auth = authService ?? FirebaseAuthService(),
        _storage = storageService ?? FirebaseStorageService(),
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuthService _auth;
  final FirebaseStorageService _storage;
  final FirebaseFirestore _db;
  Map<String, dynamic>? _dashboardCache;
  DateTime? _dashboardCachedAt;
  static const Duration _dashboardCacheTtl = Duration(seconds: 90);

  FirebaseAuthService get authService => _auth;

  void clearDashboardCache() {
    _dashboardCache = null;
    _dashboardCachedAt = null;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final UserEntity user = await _auth.login(email: email, password: password);
    return <String, dynamic>{
      'user': <String, dynamic>{
        'id': user.id,
        'email': user.email,
        'fullName': user.fullName,
        'role': user.role,
        'phone': user.phone,
        'isActive': user.isActive,
      },
    };
  }

  Future<Map<String, dynamic>> me() async {
    final UserEntity user = await _auth.loadCurrentUser();
    return <String, dynamic>{
      'id': user.id,
      'email': user.email,
      'fullName': user.fullName,
      'role': user.role,
      'phone': user.phone,
      'isActive': user.isActive,
    };
  }

  Future<Map<String, dynamic>> listProducts({int page = 1, int limit = 100}) async {
    await _requireStaffOrDriver();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.products)
        .where('isActive', isEqualTo: true)
        .get();
    final List<Map<String, dynamic>> all =
        snap.docs.map(mapProductDoc).toList(growable: false)
          ..sort(
            (Map<String, dynamic> a, Map<String, dynamic> b) => (a['name'] as String? ?? '')
                .compareTo(b['name'] as String? ?? ''),
          );
    return _paginate(all, page: page, limit: limit);
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
    await _requireStaffOrDriver();
    final Map<String, dynamic> actor = await _auth.currentActor();
    await _db.runTransaction((Transaction tx) async {
      final DocumentSnapshot<Map<String, dynamic>> productSnap =
          await tx.get(_db.collection(FirestorePaths.products).doc(productId));
      if (!productSnap.exists) {
        throw ApiException('Product not found', code: 'NOT_FOUND');
      }
      final Map<String, dynamic> product = mapProductDoc(productSnap);
      final int stock = (product['stationStock'] as num?)?.toInt() ?? 0;
      if (stock < quantity) {
        throw ApiException('Insufficient station stock', code: 'INSUFFICIENT_STOCK');
      }
      tx.update(productSnap.reference, <String, dynamic>{
        'stationStock': stock - quantity,
        'updatedAt': serverTimestamp(),
      });
      final DocumentReference<Map<String, dynamic>> movRef =
          _db.collection(FirestorePaths.stockMovements).doc();
      tx.set(movRef, <String, dynamic>{
        'productId': productId,
        'type': 'out',
        'quantity': quantity,
        'reason': 'station_sale',
        'referenceId': null,
        'createdById': actor['id'],
        'createdAt': serverTimestamp(),
      });
    });
  }

  Future<void> upsertStationBalanceRowStock({
    required int rowIndex,
    required int stationStock,
  }) async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.products)
        .where('isActive', isEqualTo: true)
        .get();
    final List<Map<String, dynamic>> products = snap.docs
        .map(mapProductDoc)
        .toList(growable: false);
    Map<String, dynamic>? existing = resolveStationBalanceProduct(
      products: products,
      rowIndex: rowIndex,
    );
    if (existing != null) {
      await patchProductStationStock(
        id: existing['id']!.toString(),
        stationStock: stationStock,
      );
      return;
    }
    final ({String name, String unitType}) spec =
        stationBalanceSeedSpecForRow(rowIndex);
    await createProduct(
      name: spec.name,
      unitType: spec.unitType,
      price: 1,
      stationStock: stationStock,
    );
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    double? price,
  }) async {
    await _requireSuperAdmin();
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
  }

  Future<Map<String, dynamic>> listVehicles({int page = 1, int limit = 100}) async {
    await _requireStaffOrDriver();
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestorePaths.vehicles).orderBy('vehicleNumber').get();
    final List<Map<String, dynamic>> all =
        snap.docs.map(mapVehicleDoc).toList(growable: false);
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
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    return mapVehicleDoc(doc);
  }

  Future<void> deleteVehicle(String id) async {
    await _requireSuperAdmin();
    await _db.collection(FirestorePaths.vehicles).doc(id).update(<String, dynamic>{
      'isActive': false,
      'updatedAt': serverTimestamp(),
    });
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
    Query<Map<String, dynamic>> q = _db.collection(FirestorePaths.vehicleLoads);
    if (actor['role'] == 'driver') {
      q = q.where('driverId', isEqualTo: actor['id']);
    } else if (driverId != null && driverId.isNotEmpty) {
      q = q.where('driverId', isEqualTo: driverId);
    }
    if (vehicleId != null && vehicleId.isNotEmpty) {
      q = q.where('vehicleId', isEqualTo: vehicleId);
    }
    if (status != null && status.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }
    final QuerySnapshot<Map<String, dynamic>> snap =
        await q.orderBy('createdAt', descending: true).get();
    final DateTime? from = parseYmd(dateFrom);
    final DateTime? to = parseYmd(dateTo);
    List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Map<String, dynamic> load = await _hydrateVehicleLoad(doc);
      if (from != null || to != null) {
        final DateTime? loadDate = timestampToDate(load['loadDate']);
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
      items.add(load);
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
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.vehicleLoads)
        .where('driverId', isEqualTo: actor['id'])
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      throw ApiException('No open load', code: 'NOT_FOUND');
    }
    return _hydrateVehicleLoad(snap.docs.first);
  }

  Future<Map<String, dynamic>> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
    String? loadBatchId,
  }) async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestorePaths.vehicleLoads).doc();
    await ref.set(<String, dynamic>{
      'vehicleId': vehicleId,
      'driverId': driverId,
      'productId': productId,
      'quantityLoaded': quantityLoaded,
      'quantityReturned': 0,
      'quantitySold': 0,
      'loadDate': Timestamp.fromDate(parseYmd(loadDate) ?? DateTime.now()),
      'status': 'open',
      'createdById': actor['id'],
      if (loadBatchId != null && loadBatchId.isNotEmpty) 'loadBatchId': loadBatchId,
      'createdAt': serverTimestamp(),
      'updatedAt': serverTimestamp(),
    });
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    return mapVehicleLoadDoc(doc);
  }

  Future<Map<String, dynamic>> listStationSales({int page = 1, int limit = 100}) async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.stationSales)
        .orderBy('createdAt', descending: true)
        .get();
    final List<Object> lookups = await Future.wait(<Future<Object>>[
      _loadProductsLookup(),
      _loadUserBriefsLookup(
        snap.docs.map(
          (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              d.data()['soldById']?.toString() ?? '',
        ),
      ),
    ]);
    final Map<String, Map<String, dynamic>> productsById =
        lookups[0] as Map<String, Map<String, dynamic>>;
    final Map<String, Map<String, dynamic>> usersById =
        lookups[1] as Map<String, Map<String, dynamic>>;
    final List<Map<String, dynamic>> items = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data();
          return mapStationSaleDoc(
            doc,
            product: productsById[data['productId']?.toString() ?? ''],
            soldBy: usersById[data['soldById']?.toString() ?? ''],
          );
        })
        .toList(growable: false);
    return _paginate(items, page: page, limit: limit);
  }

  void _applyStationSaleInTransaction({
    required Transaction tx,
    required Map<String, dynamic> actor,
    required DocumentReference<Map<String, dynamic>> saleRef,
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
    required DocumentSnapshot<Map<String, dynamic>> productSnap,
  }) async {
    if (!productSnap.exists) {
      throw ApiException('Product not found or inactive', code: 'NOT_FOUND');
    }
    final Map<String, dynamic> product = mapProductDoc(productSnap);
    if (product['isActive'] == false) {
      throw ApiException('Product not found or inactive', code: 'NOT_FOUND');
    }
    final bool skipStock = shouldSkipStationStockForSale(
      product: product,
      fillingSale: fillingSale,
      fillingLineSlot: fillingLineSlot,
    );
    if (!skipStock) {
      final int stock = (product['stationStock'] as num?)?.toInt() ?? 0;
      if (stock < quantity) {
        throw ApiException('Insufficient station stock', code: 'INSUFFICIENT_STOCK');
      }
      tx.update(productSnap.reference, <String, dynamic>{
        'stationStock': stock - quantity,
        'updatedAt': serverTimestamp(),
      });
      final DocumentReference<Map<String, dynamic>> movRef =
          _db.collection(FirestorePaths.stockMovements).doc();
      tx.set(movRef, <String, dynamic>{
        'productId': productId,
        'type': 'out',
        'quantity': quantity,
        'reason': 'station_sale',
        'referenceId': saleRef.id,
        'createdById': actor['id'],
        'createdAt': serverTimestamp(),
      });
    }
    final double totalAmount = quantity * unitPrice;
    String? noteToSave = note?.trim();
    if ((noteToSave == null || noteToSave.isEmpty) &&
        fillingSale &&
        fillingLineSlot != null &&
        fillingLineSlot <= 1 &&
        unitPrice == 0) {
      noteToSave = 'كوبون';
    }
    tx.set(saleRef, <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'soldById': actor['id'],
      if (noteToSave != null && noteToSave.isNotEmpty) 'note': noteToSave,
      'createdAt': serverTimestamp(),
      'updatedAt': serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
  }) async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    final DocumentReference<Map<String, dynamic>> saleRef =
        _db.collection(FirestorePaths.stationSales).doc();
    await _db.runTransaction((Transaction tx) async {
      final DocumentSnapshot<Map<String, dynamic>> productSnap =
          await tx.get(_db.collection(FirestorePaths.products).doc(productId));
      _applyStationSaleInTransaction(
        tx: tx,
        actor: actor,
        saleRef: saleRef,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        fillingSale: fillingSale,
        fillingLineSlot: fillingLineSlot,
        note: note,
        productSnap: productSnap,
      );
    });
    return <String, dynamic>{
      'id': saleRef.id,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': quantity * unitPrice,
    };
  }

  Future<void> createStationSalesBatch({
    required List<Map<String, dynamic>> lines,
    bool fillingSale = false,
  }) async {
    if (lines.isEmpty) {
      throw ApiException('No sale lines', code: 'EMPTY_LINES');
    }
    final Map<String, dynamic> actor = await _auth.currentActor();
    await _db.runTransaction((Transaction tx) async {
      for (final Map<String, dynamic> line in lines) {
        final String productId = line['productId'] as String;
        final int quantity = (line['quantity'] as num).toInt();
        final double unitPrice = (line['unitPrice'] as num).toDouble();
        final int? fillingLineSlot = (line['fillingLineSlot'] as num?)?.toInt();
        final String? note = line['note'] as String?;
        final DocumentReference<Map<String, dynamic>> saleRef =
            _db.collection(FirestorePaths.stationSales).doc();
        final DocumentSnapshot<Map<String, dynamic>> productSnap =
            await tx.get(_db.collection(FirestorePaths.products).doc(productId));
        _applyStationSaleInTransaction(
          tx: tx,
          actor: actor,
          saleRef: saleRef,
          productId: productId,
          quantity: quantity,
          unitPrice: unitPrice,
          fillingSale: fillingSale,
          fillingLineSlot: fillingLineSlot,
          note: note,
          productSnap: productSnap,
        );
      }
    });
  }

  Future<void> createStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) async {
    if (lines.isEmpty) {
      throw ApiException('No debt lines', code: 'EMPTY_LINES');
    }
    try {
      await _requireStaffOrDriver();
      final Map<String, dynamic> actor = await _auth.currentActor();
      final String recordingSource =
          actor['role'] == 'driver' ? 'vehicle' : 'station';
      if (actor['role'] == 'driver') {
        final QuerySnapshot<Map<String, dynamic>> v = await _db
            .collection(FirestorePaths.vehicles)
            .where('driverId', isEqualTo: actor['id'])
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
        if (v.docs.isEmpty) {
          throw ApiException('No vehicle assigned to you', code: 'FORBIDDEN');
        }
      }
      await _db.runTransaction((Transaction tx) async {
        for (final Map<String, dynamic> line in lines) {
          final Object? rawProductId = line['productId'];
          if (rawProductId is! String || rawProductId.isEmpty) {
            throw const _FirestoreTxFailure('NOT_FOUND', message: 'Invalid product');
          }
          final String productId = rawProductId;
          final Object? rawQty = line['quantity'];
          final Object? rawUnitPrice = line['unitPrice'];
          if (rawQty is! num || rawUnitPrice is! num) {
            throw const _FirestoreTxFailure('VALIDATION', message: 'Invalid debt line');
          }
          final int qty = rawQty.toInt();
          final double unitPriceNum = rawUnitPrice.toDouble();
          if (qty <= 0) {
            continue;
          }
          final DocumentSnapshot<Map<String, dynamic>> productSnap =
              await tx.get(_db.collection(FirestorePaths.products).doc(productId));
          if (!productSnap.exists) {
            throw const _FirestoreTxFailure(
              'NOT_FOUND',
              message: 'Product not found or inactive',
            );
          }
          final Map<String, dynamic> product = mapProductDoc(productSnap);
          if (product['isActive'] == false) {
            throw const _FirestoreTxFailure(
              'NOT_FOUND',
              message: 'Product not found or inactive',
            );
          }
          if (!shouldSkipStationStockForDebtProduct(product)) {
            final int stock = (product['stationStock'] as num?)?.toInt() ?? 0;
            if (stock < qty) {
              throw const _FirestoreTxFailure('INSUFFICIENT_STOCK');
            }
            tx.update(productSnap.reference, <String, dynamic>{
              'stationStock': stock - qty,
              'updatedAt': serverTimestamp(),
            });
          }
          final DocumentReference<Map<String, dynamic>> debtRef =
              _db.collection(FirestorePaths.stationDebtEntries).doc();
          tx.set(debtRef, <String, dynamic>{
            'debtorName': debtorName.trim(),
            'productId': productId,
            'quantity': qty,
            'unitPrice': unitPriceNum,
            'totalAmount': qty * unitPriceNum,
            'recordedById': actor['id'],
            'recordingSource': recordingSource,
            'repaidAt': null,
            'createdAt': serverTimestamp(),
            'updatedAt': serverTimestamp(),
          });
        }
      });
    } on _FirestoreTxFailure catch (e) {
      throw _apiExceptionFromFirestoreTxFailure(e);
    } on FirebaseException catch (e) {
      throw _apiExceptionFromFirebase(e);
    }
  }

  Future<Map<String, dynamic>> listStationDebtEntries({
    int page = 1,
    int limit = 100,
  }) async {
    await _requireStaffOrDriver();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.stationDebtEntries)
        .orderBy('createdAt', descending: true)
        .get();
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      items.add(await _hydrateStationDebt(doc));
    }
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> repayStationDebt({required String debtorName}) async {
    return _repayDebt(debtorName: debtorName, fromVehicle: false);
  }

  Future<Map<String, dynamic>> repayStationDebtFromVehicle({
    required String debtorName,
  }) async {
    return _repayDebt(debtorName: debtorName, fromVehicle: true);
  }

  Future<Map<String, dynamic>> _repayDebt({
    required String debtorName,
    required bool fromVehicle,
  }) async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    final String name = debtorName.trim();
    Query<Map<String, dynamic>> q = _db
        .collection(FirestorePaths.stationDebtEntries)
        .where('debtorName', isEqualTo: name)
        .where('repaidAt', isNull: true);
    if (fromVehicle) {
      q = q
          .where('recordedById', isEqualTo: actor['id'])
          .where('recordingSource', isEqualTo: 'vehicle');
    }
    final QuerySnapshot<Map<String, dynamic>> entries = await q.get();
    if (entries.docs.isEmpty) {
      throw ApiException('No unpaid debt for this person', code: 'NOT_FOUND');
    }
    final WriteBatch batch = _db.batch();
    final DateTime now = DateTime.now();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> entry in entries.docs) {
      final Map<String, dynamic> e = entry.data();
      final DocumentReference<Map<String, dynamic>> saleRef =
          _db.collection(FirestorePaths.stationSales).doc();
      batch.set(saleRef, <String, dynamic>{
        'productId': e['productId'],
        'quantity': e['quantity'],
        'unitPrice': e['unitPrice'],
        'totalAmount': e['totalAmount'],
        'soldById': actor['id'],
        'note': 'سداد دين — $name',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      batch.update(entry.reference, <String, dynamic>{
        'repaidAt': Timestamp.fromDate(now),
        'updatedAt': serverTimestamp(),
      });
    }
    await batch.commit();
    return <String, dynamic>{'salesCreated': entries.docs.length};
  }

  Future<Map<String, dynamic>> listVehicleSales({
    int page = 1,
    int limit = 100,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    Query<Map<String, dynamic>> q = _db.collection(FirestorePaths.vehicleSales);
    if (actor['role'] == 'driver') {
      q = q.where('driverId', isEqualTo: actor['id']);
    } else if (driverId != null && driverId.isNotEmpty) {
      q = q.where('driverId', isEqualTo: driverId);
    }
    if (vehicleId != null && vehicleId.isNotEmpty) {
      q = q.where('vehicleId', isEqualTo: vehicleId);
    }
    final QuerySnapshot<Map<String, dynamic>> snap =
        await q.orderBy('createdAt', descending: true).get();
    final DateTime? from = parseYmd(dateFrom);
    final DateTime? to = parseYmd(dateTo);
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (from != null && created != null && created.isBefore(startOfDay(from))) {
        continue;
      }
      if (to != null && created != null && created.isAfter(endOfDay(to))) {
        continue;
      }
      items.add(await _hydrateVehicleSale(doc));
    }
    return _paginate(items, page: page, limit: limit.clamp(1, 100));
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
    final Map<String, dynamic> actor = await _auth.currentActor();
    final String role = actor['role']?.toString() ?? '';
    final DocumentSnapshot<Map<String, dynamic>> vehicleSnap =
        await _db.collection(FirestorePaths.vehicles).doc(vehicleId).get();
    if (!vehicleSnap.exists) {
      throw ApiException('Vehicle not found', code: 'NOT_FOUND');
    }
    final String? vehicleDriverId = vehicleSnap.data()?['driverId']?.toString();
    if (role == 'driver') {
      if (vehicleDriverId != actor['id']) {
        throw ApiException('Vehicle not assigned to you', code: 'FORBIDDEN');
      }
    } else if (role == 'super_admin' || role == 'admin') {
      if (!isDebt) {
        throw ApiException('Forbidden', code: 'FORBIDDEN');
      }
    } else {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    final String driverId = vehicleDriverId ?? actor['id']!.toString();
    final String deductProductId = stockProductId ?? productId;
    final DocumentReference<Map<String, dynamic>> saleRef =
        _db.collection(FirestorePaths.vehicleSales).doc();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> openLoadDocs =
        skipLoadDeduction
            ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
            : (await _db
                    .collection(FirestorePaths.vehicleLoads)
                    .where('vehicleId', isEqualTo: vehicleId)
                    .where('productId', isEqualTo: deductProductId)
                    .where('status', isEqualTo: 'open')
                    .orderBy('createdAt')
                    .get())
                .docs;
    await _db.runTransaction((Transaction tx) async {
      if (!skipLoadDeduction) {
        final DocumentSnapshot<Map<String, dynamic>> productSnap = await tx.get(
          _db.collection(FirestorePaths.products).doc(deductProductId),
        );
        if (!productSnap.exists) {
          throw ApiException('Product not found or inactive', code: 'NOT_FOUND');
        }
        final Map<String, dynamic> product = mapProductDoc(productSnap);
        await _allocateVehicleSale(
          tx: tx,
          openLoads: openLoadDocs,
          quantity: quantity,
          product: product,
          productId: deductProductId,
        );
      }
      final String dest = saleDestination == 'store' ? 'store' : 'home';
      tx.set(saleRef, <String, dynamic>{
        'vehicleId': vehicleId,
        'driverId': driverId,
        'productId': productId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': quantity * unitPrice,
        'saleDestination': dest,
        'isDebt': isDebt,
        if (debtorName != null && debtorName.trim().isNotEmpty)
          'debtorName': debtorName.trim(),
        'repaidAt': null,
        'createdAt': serverTimestamp(),
        'updatedAt': serverTimestamp(),
      });
    });
    final DocumentSnapshot<Map<String, dynamic>> doc = await saleRef.get();
    return _hydrateVehicleSale(doc);
  }

  Future<void> _allocateVehicleSale({
    required Transaction tx,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> openLoads,
    required int quantity,
    required Map<String, dynamic> product,
    required String productId,
  }) async {
    int remaining = quantity;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> loadDoc in openLoads) {
      final DocumentSnapshot<Map<String, dynamic>> fresh =
          await tx.get(loadDoc.reference);
      final Map<String, dynamic> load = fresh.data() ?? <String, dynamic>{};
      final int loaded = (load['quantityLoaded'] as num?)?.toInt() ?? 0;
      final int sold = (load['quantitySold'] as num?)?.toInt() ?? 0;
      final int returned = (load['quantityReturned'] as num?)?.toInt() ?? 0;
      final int avail = loaded - sold - returned;
      if (avail <= 0) {
        continue;
      }
      final int take = min(avail, remaining);
      tx.update(loadDoc.reference, <String, dynamic>{
        'quantitySold': sold + take,
        'updatedAt': serverTimestamp(),
      });
      remaining -= take;
      if (remaining == 0) {
        break;
      }
    }
    if (remaining > 0) {
      throw ApiException(
        'Insufficient loaded stock on vehicle for this product',
        code: 'INSUFFICIENT_STOCK',
      );
    }
    final String? unitType = product['unitType'] as String?;
    if (unitType == 'carton' || unitType == 'coupon') {
      final int stock = (product['stationStock'] as num?)?.toInt() ?? 0;
      if (stock < quantity) {
        throw ApiException(
          'Cannot sell more than available station stock',
          code: 'INSUFFICIENT_STOCK',
        );
      }
      tx.update(
        _db.collection(FirestorePaths.products).doc(productId),
        <String, dynamic>{
          'stationStock': stock - quantity,
          'updatedAt': serverTimestamp(),
        },
      );
    }
  }

  Future<Map<String, dynamic>> listExpenses({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    await _requireStaffOrDriver();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.expenses)
        .orderBy('createdAt', descending: true)
        .get();
    final DateTime? from = parseYmd(dateFrom);
    final DateTime? to = parseYmd(dateTo);
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (from != null && created != null && created.isBefore(startOfDay(from))) {
        continue;
      }
      if (to != null && created != null && created.isAfter(endOfDay(to))) {
        continue;
      }
      items.add(mapExpenseDoc(doc));
    }
    return _paginate(items, page: page, limit: limit.clamp(1, 100));
  }

  Future<Map<String, dynamic>> createExpense({
    String? vehicleId,
    required double amount,
    String? note,
    Uint8List? receiptBytes,
    String? receiptFilename,
  }) async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestorePaths.expenses).doc();
    String? receiptUrl;
    if (receiptBytes != null) {
      receiptUrl = await _storage.uploadExpenseReceipt(
        expenseId: ref.id,
        bytes: receiptBytes,
        filename: receiptFilename ?? 'receipt.jpg',
      );
    }
    await ref.set(<String, dynamic>{
      if (actor['role'] == 'driver') 'driverId': actor['id'],
      if (vehicleId != null) 'vehicleId': vehicleId,
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      'createdAt': serverTimestamp(),
      'updatedAt': serverTimestamp(),
    });
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    return mapExpenseDoc(doc);
  }

  Future<Map<String, dynamic>> listReturns({int page = 1, int limit = 100}) async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestorePaths.vehicleLoads).orderBy('updatedAt', descending: true).get();
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      if (((doc.data()['quantityReturned'] as num?)?.toInt() ?? 0) <= 0) {
        continue;
      }
      items.add(await _hydrateVehicleLoad(doc));
    }
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    await _db.runTransaction((Transaction tx) async {
      final DocumentSnapshot<Map<String, dynamic>> loadSnap =
          await tx.get(_db.collection(FirestorePaths.vehicleLoads).doc(vehicleLoadId));
      if (!loadSnap.exists) {
        throw ApiException('Vehicle load not found', code: 'NOT_FOUND');
      }
      final Map<String, dynamic> load = loadSnap.data()!;
      if (actor['role'] == 'driver' && load['driverId'] != actor['id']) {
        throw ApiException('Forbidden', code: 'FORBIDDEN');
      }
      final int loaded = (load['quantityLoaded'] as num?)?.toInt() ?? 0;
      final int sold = (load['quantitySold'] as num?)?.toInt() ?? 0;
      final int prevReturned = (load['quantityReturned'] as num?)?.toInt() ?? 0;
      final int physical = loaded - sold - prevReturned;
      if (quantityReturned > physical) {
        throw ApiException('Return quantity exceeds remaining on load', code: 'VALIDATION');
      }
      tx.update(loadSnap.reference, <String, dynamic>{
        'quantityReturned': prevReturned + quantityReturned,
        'updatedAt': serverTimestamp(),
      });
      final String productId = load['productId'] as String;
      final DocumentSnapshot<Map<String, dynamic>> productSnap =
          await tx.get(_db.collection(FirestorePaths.products).doc(productId));
      if (productSnap.exists) {
        final int stock = (productSnap.data()?['stationStock'] as num?)?.toInt() ?? 0;
        tx.update(productSnap.reference, <String, dynamic>{
          'stationStock': stock + quantityReturned,
          'updatedAt': serverTimestamp(),
        });
        final DocumentReference<Map<String, dynamic>> movRef =
            _db.collection(FirestorePaths.stockMovements).doc();
        tx.set(movRef, <String, dynamic>{
          'productId': productId,
          'type': 'in',
          'quantity': quantityReturned,
          'reason': 'vehicle_return',
          'referenceId': vehicleLoadId,
          'createdById': actor['id'],
          'createdAt': serverTimestamp(),
        });
      }
    });
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestorePaths.vehicleLoads).doc(vehicleLoadId).get();
    return _hydrateVehicleLoad(doc);
  }

  Future<Map<String, dynamic>> reportsInventory() async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> products =
        await _db.collection(FirestorePaths.products).orderBy('name').get();
    final QuerySnapshot<Map<String, dynamic>> loads = await _db
        .collection(FirestorePaths.vehicleLoads)
        .where('status', isEqualTo: 'open')
        .get();
    int onVehicles = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> l in loads.docs) {
      final Map<String, dynamic> d = l.data();
      final int rem = ((d['quantityLoaded'] as num?)?.toInt() ?? 0) -
          ((d['quantitySold'] as num?)?.toInt() ?? 0) -
          ((d['quantityReturned'] as num?)?.toInt() ?? 0);
      if (rem > 0) {
        onVehicles += rem;
      }
    }
    return <String, dynamic>{
      'stationProducts': products.docs.map(mapProductDoc).toList(growable: false),
      'openLoadLines': loads.docs.length,
      'estimatedUnitsOnVehicles': onVehicles,
    };
  }

  Future<Map<String, dynamic>> reportsSalesWorkingDays() async {
    await _requireStaff();
    final Map<String, double> byDay = <String, double>{};
    for (final String col in <String>[
      FirestorePaths.stationSales,
      FirestorePaths.vehicleSales,
    ]) {
      final QuerySnapshot<Map<String, dynamic>> snap =
          await _db.collection(col).get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        final DateTime? created = timestampToDate(doc.data()['createdAt']);
        if (created == null) {
          continue;
        }
        final String key = ymd(created);
        byDay[key] = (byDay[key] ?? 0) + _num(doc.data()['totalAmount']);
      }
    }
    final List<MapEntry<String, double>> sorted = byDay.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.key.compareTo(a.key));
    return <String, dynamic>{
      'days': sorted
          .map((MapEntry<String, double> e) => <String, dynamic>{
                'date': e.key,
                'combined': e.value,
              })
          .toList(growable: false),
    };
  }

  Future<Map<String, dynamic>> reportsProfitLoss({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    await _requireStaff();
    final DateTime now = DateTime.now();
    final DateTime start = parseYmd(dateFrom) != null
        ? startOfDay(parseYmd(dateFrom)!)
        : startOfDay(now);
    final DateTime end =
        parseYmd(dateTo) != null ? endOfDay(parseYmd(dateTo)!) : endOfDay(now);
    double revenue = 0;
    double expenseTotal = 0;
    for (final String col in <String>[
      FirestorePaths.stationSales,
      FirestorePaths.vehicleSales,
    ]) {
      final QuerySnapshot<Map<String, dynamic>> snap = await _db.collection(col).get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        final DateTime? created = timestampToDate(doc.data()['createdAt']);
        if (isInRange(created, start, end)) {
          revenue += _num(doc.data()['totalAmount']);
        }
      }
    }
    final QuerySnapshot<Map<String, dynamic>> expenses =
        await _db.collection(FirestorePaths.expenses).get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in expenses.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (isInRange(created, start, end)) {
        expenseTotal += _num(doc.data()['amount']);
      }
    }
    return <String, dynamic>{
      'from': start.toIso8601String(),
      'to': end.toIso8601String(),
      'revenue': revenue,
      'expenses': expenseTotal,
      'net': revenue - expenseTotal,
    };
  }

  Future<Map<String, dynamic>> reportsSalesMonthly({
    int? year,
    int? month,
  }) async {
    await _requireStaff();
    final DateTime n = DateTime.now();
    final int y = year ?? n.year;
    final int m = month ?? n.month;
    final ({DateTime start, DateTime end}) range = businessMonthRangeFor(y, m);
    final List<Map<String, dynamic>> stationSales = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> vehicleSales = <Map<String, dynamic>>[];
    final QuerySnapshot<Map<String, dynamic>> stationSnap =
        await _db.collection(FirestorePaths.stationSales).get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in stationSnap.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (isInRange(created, range.start, range.end)) {
        stationSales.add(await _hydrateStationSale(doc));
      }
    }
    final QuerySnapshot<Map<String, dynamic>> vehicleSnap =
        await _db.collection(FirestorePaths.vehicleSales).get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in vehicleSnap.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (isInRange(created, range.start, range.end)) {
        vehicleSales.add(await _hydrateVehicleSale(doc));
      }
    }
    double stationAmount = 0;
    double vehicleAmount = 0;
    for (final Map<String, dynamic> s in stationSales) {
      stationAmount += _num(s['totalAmount']);
    }
    for (final Map<String, dynamic> s in vehicleSales) {
      vehicleAmount += _num(s['totalAmount']);
    }
    return <String, dynamic>{
      'year': y,
      'month': m,
      'stationSales': stationSales,
      'vehicleSales': vehicleSales,
      'totals': <String, dynamic>{
        'stationAmount': stationAmount,
        'vehicleAmount': vehicleAmount,
      },
    };
  }

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
        'totalProfitToday': stationToday + vehicleToday - expensesToday,
        'totalMonthlySales': monthlyStation + monthlyVehicle,
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
      'totalProfitToday': stationToday + vehicleToday - expensesToday,
      'totalMonthlySales': monthlyStation + monthlyVehicle,
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
    final List<QuerySnapshot<Map<String, dynamic>>> coreSnaps =
        await Future.wait(<Future<QuerySnapshot<Map<String, dynamic>>>>[
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
    ]);
    final QuerySnapshot<Map<String, dynamic>> users = coreSnaps[0];
    final QuerySnapshot<Map<String, dynamic>> vehicles = coreSnaps[1];
    final QuerySnapshot<Map<String, dynamic>> products = coreSnaps[2];
    final QuerySnapshot<Map<String, dynamic>> openLoads = coreSnaps[3];
    final QuerySnapshot<Map<String, dynamic>> debtSnap = coreSnaps[4];
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
    final List<Map<String, dynamic>> debtPreview = _debtOpenPreviewFromSnap(
      snap: debtSnap,
      productById: productById,
    );
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
      ),
    );
    final List<double> salesTotals = await Future.wait(<Future<double>>[
      _sumSales(FirestorePaths.stationSales, day.start, day.end),
      _sumSales(FirestorePaths.vehicleSales, day.start, day.end),
      _sumExpenses(day.start, day.end),
      _sumSales(FirestorePaths.stationSales, month.start, month.end),
      _sumSales(FirestorePaths.vehicleSales, month.start, month.end),
      _sumExpenses(month.start, month.end),
    ]);
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
      stationToday: salesTotals[0],
      vehicleToday: salesTotals[1],
      expensesToday: salesTotals[2],
      monthlyStation: salesTotals[3],
      monthlyVehicle: salesTotals[4],
      monthlyExpenses: salesTotals[5],
    );
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
    int cartonStock = 0;
    final QuerySnapshot<Map<String, dynamic>> products =
        await _db.collection(FirestorePaths.products).where('isActive', isEqualTo: true).get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> p in products.docs) {
      if (p.data()['unitType'] == 'carton') {
        cartonStock += (p.data()['stationStock'] as num?)?.toInt() ?? 0;
      }
    }
    double monthlyAmount = 0;
    int homeQty = 0;
    int storeQty = 0;
    double debtQty = 0;
    double debtAmount = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (await _db.collection(FirestorePaths.stationSales).get()).docs) {
      final Map<String, dynamic> sale = doc.data();
      final DateTime? created = timestampToDate(sale['createdAt']);
      if (!isInRange(created, range.start, range.end)) {
        continue;
      }
      final Map<String, dynamic>? product =
          await _productById(sale['productId'] as String?);
      if (product?['unitType'] != 'carton') {
        continue;
      }
      monthlyAmount += _num(sale['totalAmount']);
      homeQty += (sale['quantity'] as num?)?.toInt() ?? 0;
    }
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (await _db.collection(FirestorePaths.vehicleSales).get()).docs) {
      final Map<String, dynamic> sale = doc.data();
      final DateTime? created = timestampToDate(sale['createdAt']);
      if (!isInRange(created, range.start, range.end)) {
        continue;
      }
      final Map<String, dynamic>? product =
          await _productById(sale['productId'] as String?);
      if (product?['unitType'] != 'carton') {
        continue;
      }
      monthlyAmount += _num(sale['totalAmount']);
      final int qty = (sale['quantity'] as num?)?.toInt() ?? 0;
      homeQty += qty;
      if (sale['saleDestination'] == 'store') {
        storeQty += qty;
      }
    }
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (await _db
                .collection(FirestorePaths.stationDebtEntries)
                .where('repaidAt', isNull: true)
                .get())
            .docs) {
      final Map<String, dynamic> e = doc.data();
      final Map<String, dynamic>? product = await _productById(e['productId'] as String?);
      if (product?['unitType'] != 'carton') {
        continue;
      }
      debtQty += (e['quantity'] as num?)?.toInt() ?? 0;
      debtAmount += _num(e['totalAmount']);
    }
    double cartonExpenses = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (await _db.collection(FirestorePaths.expenses).get()).docs) {
      final Map<String, dynamic> e = doc.data();
      if (e['driverId'] != null || e['vehicleId'] != null) {
        continue;
      }
      final DateTime? created = timestampToDate(e['createdAt']);
      if (!isInRange(created, range.start, range.end)) {
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
      'monthlyCartonSalesHomeQty': homeQty,
      'monthlyCartonSalesStoreQty': storeQty,
      'cartonDebtUnpaidQuantity': debtQty,
      'cartonDebtUnpaidTotalAmount': debtAmount,
    };
  }

  Future<Map<String, dynamic>> getDashboardAdmin() async {
    await _requireStaff();
    final DateTime now = DateTime.now();
    final ({DateTime start, DateTime end}) day = businessDayRange(now);
    final ({DateTime start, DateTime end}) month = businessMonthRange(now);
    final QuerySnapshot<Map<String, dynamic>> products =
        await _db.collection(FirestorePaths.products).where('isActive', isEqualTo: true).get();
    final QuerySnapshot<Map<String, dynamic>> loadsToday = await _db
        .collection(FirestorePaths.vehicleLoads)
        .get();
    final List<Map<String, dynamic>> loadsForDay = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in loadsToday.docs) {
      final DateTime? loadDate = timestampToDate(doc.data()['loadDate']);
      if (isInRange(loadDate, day.start, day.end)) {
        loadsForDay.add(await _hydrateVehicleLoad(doc));
      }
    }
    final double stationToday = await _sumSales(FirestorePaths.stationSales, day.start, day.end);
    final double vehicleToday = await _sumSales(FirestorePaths.vehicleSales, day.start, day.end);
    final double monthlyStation = await _sumSales(FirestorePaths.stationSales, month.start, month.end);
    final double monthlyVehicle = await _sumSales(FirestorePaths.vehicleSales, month.start, month.end);
    final Map<String, dynamic> stock = await _stockSnapshot();
    final int activeDrivers = (await _db
            .collection(FirestorePaths.users)
            .where('role', isEqualTo: 'driver')
            .where('isActive', isEqualTo: true)
            .get())
        .docs
        .length;
    int returnedToday = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in loadsToday.docs) {
      final DateTime? updated = timestampToDate(doc.data()['updatedAt']);
      if (isInRange(updated, day.start, day.end)) {
        returnedToday += (doc.data()['quantityReturned'] as num?)?.toInt() ?? 0;
      }
    }
    final List<Map<String, dynamic>> lowStock = products.docs
        .map(mapProductDoc)
        .where((Map<String, dynamic> p) => ((p['stationStock'] as num?)?.toInt() ?? 0) < 50)
        .take(10)
        .toList(growable: false);
    return <String, dynamic>{
      'stationStockSummary': products.docs.map(mapProductDoc).toList(growable: false),
      'vehiclesLoadedToday': loadsForDay.length,
      'loadsToday': loadsForDay.take(20).toList(growable: false),
      'totalSalesToday': stationToday + vehicleToday,
      'stationSalesToday': stationToday,
      'vehicleSalesToday': vehicleToday,
      'totalMonthlySales': monthlyStation + monthlyVehicle,
      'returnedQuantitiesToday': returnedToday,
      'activeDrivers': activeDrivers,
      'remainingStationStock': stock['remainingStationStock'],
      'remainingOnVehicles': stock['remainingOnVehicles'],
      'lowStockProducts': lowStock,
    };
  }

  Future<Map<String, dynamic>> getDashboardDriver() async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    if (actor['role'] != 'driver') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    final DateTime now = DateTime.now();
    final ({DateTime start, DateTime end}) day = businessDayRange(now);
    final QuerySnapshot<Map<String, dynamic>> vehicles = await _db
        .collection(FirestorePaths.vehicles)
        .where('driverId', isEqualTo: actor['id'])
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (vehicles.docs.isEmpty) {
      return <String, dynamic>{
        'assignedVehicle': null,
        'productsLoadedToday': <dynamic>[],
        'soldQuantitiesToday': 0,
        'vehicleSalesAmountToday': 0,
        'remainingQuantities': <dynamic>[],
        'remainingOnVehicle': 0,
        'returnedQuantitiesToday': 0,
        'totalExpensesToday': 0,
        'notesSummary': <dynamic>[],
      };
    }
    final Map<String, dynamic> vehicle = mapVehicleDoc(vehicles.docs.first);
    final QuerySnapshot<Map<String, dynamic>> loads = await _db
        .collection(FirestorePaths.vehicleLoads)
        .where('vehicleId', isEqualTo: vehicle['id'])
        .where('driverId', isEqualTo: actor['id'])
        .get();
    final List<Map<String, dynamic>> loadsToday = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> remainingQuantities = <Map<String, dynamic>>[];
    int returnedToday = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in loads.docs) {
      final Map<String, dynamic> load = await _hydrateVehicleLoad(doc);
      final DateTime? loadDate = timestampToDate(load['loadDate']);
      if (isInRange(loadDate, day.start, day.end)) {
        loadsToday.add(load);
      }
      final int loaded = (load['quantityLoaded'] as num?)?.toInt() ?? 0;
      final int sold = (load['quantitySold'] as num?)?.toInt() ?? 0;
      final int returned = (load['quantityReturned'] as num?)?.toInt() ?? 0;
      returnedToday += returned;
      final Map<String, dynamic>? product = load['product'] as Map<String, dynamic>?;
      remainingQuantities.add(<String, dynamic>{
        'productId': load['productId'],
        'productName': product?['name'] ?? '',
        'remaining': loaded - sold - returned,
        'quantityReturned': returned,
        'quantitySold': sold,
      });
    }
    final QuerySnapshot<Map<String, dynamic>> sales = await _db
        .collection(FirestorePaths.vehicleSales)
        .where('driverId', isEqualTo: actor['id'])
        .get();
    int soldQty = 0;
    double salesAmount = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in sales.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (!isInRange(created, day.start, day.end)) {
        continue;
      }
      soldQty += (doc.data()['quantity'] as num?)?.toInt() ?? 0;
      salesAmount += _num(doc.data()['totalAmount']);
    }
    final QuerySnapshot<Map<String, dynamic>> expenses = await _db
        .collection(FirestorePaths.expenses)
        .where('driverId', isEqualTo: actor['id'])
        .get();
    double totalExpensesToday = 0;
    final List<Map<String, dynamic>> notesSummary = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in expenses.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (!isInRange(created, day.start, day.end)) {
        continue;
      }
      totalExpensesToday += _num(doc.data()['amount']);
      final String? note = doc.data()['note'] as String?;
      if (note != null && note.isNotEmpty) {
        notesSummary.add(<String, dynamic>{'note': note, 'at': created});
      }
    }
    final int remainingOnVehicle = remainingQuantities.fold<int>(
      0,
      (int a, Map<String, dynamic> r) =>
          a + (((r['remaining'] as num?)?.toInt() ?? 0) > 0 ? (r['remaining'] as num).toInt() : 0),
    );
    return <String, dynamic>{
      'role': 'driver',
      'metrics': <String, dynamic>{
        'totalExpensesToday': totalExpensesToday,
        'vehicleSalesToday': salesAmount,
        'remainingOnVehicle': remainingOnVehicle,
      },
      'details': <String, dynamic>{
        'assignedVehicle': vehicle,
        'remainingQuantities': remainingQuantities,
        'notesSummary': notesSummary,
        'productsLoadedToday': loadsToday,
        'soldQuantitiesToday': soldQty,
        'returnedQuantitiesToday': returnedToday,
      },
      'assignedVehicle': vehicle,
      'productsLoadedToday': loadsToday,
      'soldQuantitiesToday': soldQty,
      'vehicleSalesAmountToday': salesAmount,
      'remainingQuantities': remainingQuantities,
      'remainingOnVehicle': remainingOnVehicle,
      'returnedQuantitiesToday': returnedToday,
      'totalExpensesToday': totalExpensesToday,
      'notesSummary': notesSummary,
    };
  }

  Future<Map<String, dynamic>> _hydrateStationSale(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Map<String, dynamic>? product = await _productById(data['productId'] as String?);
    final Map<String, dynamic>? soldBy = await _userBrief(data['soldById'] as String?);
    return mapStationSaleDoc(doc, product: product, soldBy: soldBy);
  }

  Future<Map<String, dynamic>> _hydrateStationDebt(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Map<String, dynamic>? product = await _productById(data['productId'] as String?);
    final Map<String, dynamic>? recordedBy =
        await _userBrief(data['recordedById'] as String?);
    return mapStationDebtDoc(doc, product: product, recordedBy: recordedBy);
  }

  Future<Map<String, dynamic>> _hydrateVehicleSale(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Map<String, dynamic>? product = await _productById(data['productId'] as String?);
    final Map<String, dynamic>? vehicle = await _vehicleById(data['vehicleId'] as String?);
    final Map<String, dynamic>? driver = await _userBrief(data['driverId'] as String?);
    return mapVehicleSaleDoc(doc, product: product, vehicle: vehicle, driver: driver);
  }

  Future<Map<String, dynamic>> _hydrateVehicleLoad(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Map<String, dynamic>? vehicle = await _vehicleById(data['vehicleId'] as String?);
    final Map<String, dynamic>? driver = await _userBrief(data['driverId'] as String?);
    final Map<String, dynamic>? product = await _productById(data['productId'] as String?);
    final Map<String, dynamic>? createdBy = await _userBrief(data['createdById'] as String?);
    return mapVehicleLoadDoc(
      doc,
      vehicle: vehicle,
      driver: driver,
      product: product,
      createdBy: createdBy,
    );
  }

  Future<Map<String, Map<String, dynamic>>> _loadProductsLookup() async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestorePaths.products).get();
    return <String, Map<String, dynamic>>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs)
        doc.id: mapProductDoc(doc),
    };
  }

  Future<Map<String, Map<String, dynamic>>> _loadUserBriefsLookup(
    Iterable<String> ids,
  ) async {
    final Set<String> unique =
        ids.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toSet();
    if (unique.isEmpty) {
      return <String, Map<String, dynamic>>{};
    }
    final List<MapEntry<String, Map<String, dynamic>>?> entries =
        await Future.wait<MapEntry<String, Map<String, dynamic>>?>(
      unique.map((String id) async {
        final Map<String, dynamic>? brief = await _userBrief(id);
        if (brief == null) {
          return null;
        }
        return MapEntry<String, Map<String, dynamic>>(id, brief);
      }),
    );
    return Map<String, Map<String, dynamic>>.fromEntries(
      entries.whereType<MapEntry<String, Map<String, dynamic>>>(),
    );
  }

  Future<Map<String, dynamic>?> _productById(String? id) async {
    if (id == null) {
      return null;
    }
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestorePaths.products).doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return mapProductDoc(doc);
  }

  Future<Map<String, dynamic>?> _vehicleById(String? id) async {
    if (id == null) {
      return null;
    }
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestorePaths.vehicles).doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return mapVehicleDoc(doc);
  }

  Future<Map<String, dynamic>?> _userBrief(String? id) async {
    if (id == null) {
      return null;
    }
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestorePaths.users).doc(id).get();
    if (!doc.exists) {
      return null;
    }
    final Map<String, dynamic> u = mapUserDoc(doc);
    return <String, dynamic>{
      'id': u['id'],
      'fullName': u['fullName'],
      if (u['phone'] != null) 'phone': u['phone'],
    };
  }

  Future<double> _sumSales(String collection, DateTime start, DateTime end) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(collection)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    double total = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      total += _num(doc.data()['totalAmount']);
    }
    return total;
  }

  Future<double> _sumExpenses(DateTime start, DateTime end) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.expenses)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    double total = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      total += _num(doc.data()['amount']);
    }
    return total;
  }

  Map<String, dynamic> _stockSnapshotFromProductsAndLoads({
    required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> products,
    required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> openLoads,
  }) {
    int stationStock = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> p in products) {
      stationStock += (p.data()['stationStock'] as num?)?.toInt() ?? 0;
    }
    int onVehicles = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> l in openLoads) {
      final Map<String, dynamic> d = l.data();
      final int rem = ((d['quantityLoaded'] as num?)?.toInt() ?? 0) -
          ((d['quantitySold'] as num?)?.toInt() ?? 0) -
          ((d['quantityReturned'] as num?)?.toInt() ?? 0);
      if (rem > 0) {
        onVehicles += rem;
      }
    }
    return <String, dynamic>{
      'remainingStationStock': stationStock,
      'remainingOnVehicles': onVehicles,
    };
  }

  Future<Map<String, dynamic>> _stockSnapshot() async {
    final List<QuerySnapshot<Map<String, dynamic>>> snaps =
        await Future.wait(<Future<QuerySnapshot<Map<String, dynamic>>>>[
      _db.collection(FirestorePaths.products).get(),
      _db.collection(FirestorePaths.vehicleLoads).where('status', isEqualTo: 'open').get(),
    ]);
    return _stockSnapshotFromProductsAndLoads(
      products: snaps[0].docs,
      openLoads: snaps[1].docs,
    );
  }

  List<Map<String, dynamic>> _debtOpenPreviewFromSnap({
    required QuerySnapshot<Map<String, dynamic>> snap,
    required Map<String, Map<String, dynamic>> productById,
  }) {
    final Map<String, Map<String, Map<String, dynamic>>> byDebtor =
        <String, Map<String, Map<String, dynamic>>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Map<String, dynamic> e = doc.data();
      final String dname = e['debtorName'] as String;
      byDebtor.putIfAbsent(dname, () => <String, Map<String, dynamic>>{});
      final String pid = e['productId'] as String;
      final Map<String, dynamic>? product = productById[pid];
      final Map<String, Map<String, dynamic>> prodMap = byDebtor[dname]!;
      final Map<String, dynamic>? prev = prodMap[pid];
      final int qty = (e['quantity'] as num?)?.toInt() ?? 0;
      prodMap[pid] = <String, dynamic>{
        'productName': product?['name'] ?? '',
        'quantity': ((prev?['quantity'] as num?)?.toInt() ?? 0) + qty,
      };
    }
    return byDebtor.entries
        .map((MapEntry<String, Map<String, Map<String, dynamic>>> e) => <String, dynamic>{
              'debtorName': e.key,
              'lines': e.value.values.toList(growable: false),
            })
        .toList(growable: false);
  }

  Future<void> _logStockMovement({
    required String productId,
    required String type,
    required int quantity,
    required String reason,
    required String? referenceId,
    required String actorId,
  }) async {
    await _db.collection(FirestorePaths.stockMovements).add(<String, dynamic>{
      'productId': productId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'referenceId': referenceId,
      'createdById': actorId,
      'createdAt': serverTimestamp(),
    });
  }

  Map<String, dynamic> _paginate(
    List<Map<String, dynamic>> all, {
    required int page,
    required int limit,
  }) {
    final int safeLimit = limit.clamp(1, 100);
    final int safePage = page < 1 ? 1 : page;
    final int start = (safePage - 1) * safeLimit;
    final List<Map<String, dynamic>> slice = start >= all.length
        ? <Map<String, dynamic>>[]
        : all.sublist(start, min(start + safeLimit, all.length));
    return <String, dynamic>{
      'items': slice,
      'total': all.length,
      'page': safePage,
      'limit': safeLimit,
    };
  }

  double _num(Object? v) {
    if (v == null) {
      return 0;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString()) ?? 0;
  }

  String _syntheticPhone() {
    final int n = Random().nextInt(90000000) + 10000000;
    return '+1000$n';
  }

  Future<List<Map<String, dynamic>>> listStaffNoteRecipients() async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.users)
        .where('isActive', isEqualTo: true)
        .get();
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Map<String, dynamic> u = mapUserDoc(doc);
      final String role = u['role']?.toString() ?? '';
      if (role == 'admin' || role == 'driver') {
        out.add(u);
      }
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> createStaffNotes({
    required String message,
    required String recipientKind,
    String? driverUserId,
  }) async {
    final Map<String, dynamic> actor = await _requireStaff();
    final String text = message.trim();
    if (text.isEmpty) {
      throw ApiException('Empty message', code: 'EMPTY_MESSAGE');
    }
    final List<String> targetUserIds = <String>[];
    switch (recipientKind) {
      case 'all_admins':
        final QuerySnapshot<Map<String, dynamic>> snap = await _db
            .collection(FirestorePaths.users)
            .where('role', isEqualTo: 'admin')
            .get();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
          if (doc.data()['isActive'] == true) {
            targetUserIds.add(doc.id);
          }
        }
      case 'driver':
        final String? id = driverUserId?.trim();
        if (id == null || id.isEmpty) {
          throw ApiException('Missing driver', code: 'MISSING_DRIVER');
        }
        targetUserIds.add(id);
      default:
        throw ApiException('Invalid recipient', code: 'INVALID_RECIPIENT');
    }
    if (targetUserIds.isEmpty) {
      throw ApiException('No recipients', code: 'NO_RECIPIENTS');
    }
    final List<Map<String, dynamic>> created = <Map<String, dynamic>>[];
    for (final String toUserId in targetUserIds) {
      if (toUserId == actor['id']) {
        continue;
      }
      final DocumentReference<Map<String, dynamic>> ref =
          _db.collection(FirestorePaths.staffNotes).doc();
      await ref.set(<String, dynamic>{
        'message': text,
        'toUserId': toUserId,
        'fromUserId': actor['id'],
        'fromUserName': actor['fullName']?.toString() ?? '',
        'createdAt': serverTimestamp(),
        'readAt': null,
      });
      final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
      created.add(<String, dynamic>{
        'id': doc.id,
        ...?doc.data(),
      });
    }
    if (created.isEmpty) {
      throw ApiException('No recipients', code: 'NO_RECIPIENTS');
    }
    return created;
  }

  Future<Map<String, dynamic>?> _selectPendingStaffNote(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    Map<String, dynamic>? pick;
    DateTime? pickAt;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs) {
      final Map<String, dynamic> data = doc.data();
      if (data['readAt'] != null) {
        continue;
      }
      final DateTime? created = timestampToDate(data['createdAt']);
      if (pick == null ||
          (created != null &&
              (pickAt == null || created.isBefore(pickAt)))) {
        pick = <String, dynamic>{'id': doc.id, ...data};
        pickAt = created;
      }
    }
    if (pick == null) {
      return null;
    }
    return _hydrateStaffNote(pick);
  }

  Future<Map<String, dynamic>> _hydrateStaffNote(
    Map<String, dynamic> note,
  ) async {
    final String? fromUserId = note['fromUserId']?.toString();
    if (fromUserId != null && fromUserId.isNotEmpty) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> fromDoc = await _db
            .collection(FirestorePaths.users)
            .doc(fromUserId)
            .get();
        if (fromDoc.exists) {
          final Map<String, dynamic> fromUser = mapUserDoc(fromDoc);
          note['fromUser'] = fromUser;
          final String profileName =
              fromUser['fullName']?.toString().trim() ?? '';
          if (profileName.isNotEmpty &&
              (note['fromUserName']?.toString().trim().isEmpty ?? true)) {
            note['fromUserName'] = profileName;
          }
        }
      } on FirebaseException {
        // fallback: fromUserName المخزّن مع الملاحظة
      }
    }
    final String cachedName = note['fromUserName']?.toString().trim() ?? '';
    if (cachedName.isNotEmpty && note['fromUser'] is! Map<String, dynamic>) {
      note['fromUser'] = <String, dynamic>{'fullName': cachedName};
    }
    final DateTime? created = timestampToDate(note['createdAt']);
    if (created != null) {
      note['createdAt'] = created;
    }
    return note;
  }

  Future<Map<String, dynamic>?> getPendingStaffNoteForMe() async {
    final UserEntity user = await _auth.loadCurrentUser();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.staffNotes)
        .where('toUserId', isEqualTo: user.id)
        .get();
    return _selectPendingStaffNote(snap.docs);
  }

  Stream<Map<String, dynamic>?> watchPendingStaffNoteForMe() {
    return Stream.fromFuture(_auth.loadCurrentUser()).asyncExpand(
      (UserEntity user) => _db
          .collection(FirestorePaths.staffNotes)
          .where('toUserId', isEqualTo: user.id)
          .snapshots()
          .asyncMap(
            (QuerySnapshot<Map<String, dynamic>> snap) =>
                _selectPendingStaffNote(snap.docs),
          ),
    );
  }

  Future<void> markStaffNoteRead(String noteId) async {
    final UserEntity user = await _auth.loadCurrentUser();
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestorePaths.staffNotes).doc(noteId);
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    if (!doc.exists || doc.data()?['toUserId'] != user.id) {
      return;
    }
    await ref.update(<String, dynamic>{
      'readAt': serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> _requireStaff() async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    if (actor['role'] == 'driver') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    return actor;
  }

  Future<Map<String, dynamic>> _requireStaffOrDriver() async => _auth.currentActor();

  Future<void> _requireSuperAdmin() async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    if (actor['role'] != 'super_admin') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
  }
}
