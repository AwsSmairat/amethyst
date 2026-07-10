import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:amethyst/core/catalog/carton_product_match.dart';
import 'package:amethyst/core/firebase/date_range_utils.dart';
import 'package:amethyst/core/firebase/firebase_auth_service.dart';
import 'package:amethyst/core/firebase/firebase_storage_service.dart';
import 'package:amethyst/core/firebase/firestore_mappers.dart';
import 'package:amethyst/core/firebase/firestore_paths.dart';
import 'package:amethyst/core/firebase/station_stock_skip.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/expenses/profit_vehicle_expense_deduction.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sales_aggregates.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_aggregates.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_product_columns.dart';
import 'package:amethyst/core/station_debt/station_debt_entry_utils.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Map<String, dynamic>? _adminDashboardCache;
  DateTime? _adminDashboardCachedAt;
  Map<String, dynamic>? _driverDashboardCache;
  DateTime? _driverDashboardCachedAt;
  String? _driverDashboardCacheUserId;
  List<Map<String, dynamic>>? _activeProductsCache;
  DateTime? _activeProductsCachedAt;
  Map<String, Map<String, dynamic>>? _allProductsLookupCache;
  DateTime? _allProductsLookupCachedAt;
  Map<String, Map<String, dynamic>>? _vehiclesLookupCache;
  DateTime? _vehiclesLookupCachedAt;
  final Map<String, Map<String, dynamic>> _userBriefMemCache =
      <String, Map<String, dynamic>>{};
  static const Duration _dashboardCacheTtl = Duration(minutes: 3);
  static const Duration _catalogCacheTtl = Duration(seconds: 90);

  FirebaseAuthService get authService => _auth;

  void clearDashboardCache() {
    _dashboardCache = null;
    _dashboardCachedAt = null;
    _adminDashboardCache = null;
    _adminDashboardCachedAt = null;
    _driverDashboardCache = null;
    _driverDashboardCachedAt = null;
    _driverDashboardCacheUserId = null;
  }

  void clearCatalogCache() {
    _activeProductsCache = null;
    _activeProductsCachedAt = null;
    _allProductsLookupCache = null;
    _allProductsLookupCachedAt = null;
    _vehiclesLookupCache = null;
    _vehiclesLookupCachedAt = null;
    _userBriefMemCache.clear();
    clearDashboardCache();
  }

  bool _catalogCacheFresh(DateTime? cachedAt) =>
      cachedAt != null &&
      DateTime.now().difference(cachedAt) < _catalogCacheTtl;

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
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered =
        snap.docs.toList(growable: false);
    if (from != null || to != null) {
      filtered = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        final DateTime? loadDate = timestampToDate(doc.data()['loadDate']);
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
        filtered.add(doc);
      }
    }
    final List<Map<String, dynamic>> items = await _mapVehicleLoadsBatch(filtered);
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

  Future<Map<String, dynamic>> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
  }) async {
    await createStationSalesBatch(
      fillingSale: fillingSale,
      lines: <Map<String, dynamic>>[
        <String, dynamic>{
          'productId': productId,
          'quantity': quantity,
          'unitPrice': unitPrice,
          if (fillingLineSlot != null) 'fillingLineSlot': fillingLineSlot,
          if (note != null) 'note': note,
        },
      ],
    );
    return <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': quantity * unitPrice,
    };
  }

  Future<void> createStationSalesBatch({
    required List<Map<String, dynamic>> lines,
    bool fillingSale = false,
    String? paymentMethod,
  }) async {
    if (lines.isEmpty) {
      throw ApiException('No sale lines', code: 'EMPTY_LINES');
    }
    try {
      final Map<String, dynamic> actor = await _auth.currentActor();
      final String actorId = actor['id']!.toString();
      final List<_StationSaleBatchLine> parsed = <_StationSaleBatchLine>[];
      for (final Map<String, dynamic> line in lines) {
        final Object? rawProductId = line['productId'];
        final Object? rawQty = line['quantity'];
        final Object? rawUnitPrice = line['unitPrice'];
        if (rawProductId is! String || rawProductId.isEmpty) {
          throw ApiException('Invalid product', code: 'NOT_FOUND');
        }
        if (rawQty is! num || rawUnitPrice is! num) {
          throw ApiException('Invalid sale line', code: 'VALIDATION');
        }
        final int qty = rawQty.toInt();
        if (qty <= 0) {
          continue;
        }
        parsed.add(
          _StationSaleBatchLine(
            productId: rawProductId,
            quantity: qty,
            unitPrice: rawUnitPrice.toDouble(),
            fillingLineSlot: (line['fillingLineSlot'] as num?)?.toInt(),
            note: line['note'] as String?,
          ),
        );
      }
      if (parsed.isEmpty) {
        throw ApiException('No sale lines', code: 'EMPTY_LINES');
      }

      final String? paymentMethodToSave =
          paymentMethod?.trim().isNotEmpty == true ? paymentMethod!.trim() : null;

      final Set<String> productIds =
          parsed.map((_StationSaleBatchLine l) => l.productId).toSet();
      clearCatalogCache();
      final List<Map<String, dynamic>> catalogProducts =
          await _loadActiveProductsList();
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> productSnaps =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      await Future.wait(
        productIds.map((String productId) async {
          productSnaps[productId] = await _db
              .collection(FirestorePaths.products)
              .doc(productId)
              .get();
        }),
      );

      final Map<String, int> stockToDeduct = <String, int>{};
      final Map<int, Map<String, int>> lineStockPlans = <int, Map<String, int>>{};
      for (var i = 0; i < parsed.length; i++) {
        final _StationSaleBatchLine line = parsed[i];
        final DocumentSnapshot<Map<String, dynamic>> productSnap =
            productSnaps[line.productId]!;
        if (!productSnap.exists) {
          throw ApiException('Product not found or inactive', code: 'NOT_FOUND');
        }
        final Map<String, dynamic> product = mapProductDoc(productSnap);
        if (product['isActive'] == false) {
          throw ApiException('Product not found or inactive', code: 'NOT_FOUND');
        }
        if (shouldSkipStationStockForSale(
          product: product,
          fillingSale: fillingSale,
          fillingLineSlot: line.fillingLineSlot,
        )) {
          continue;
        }
        final Map<String, int> plan;
        try {
          plan = planStationStockDeduction(
            products: catalogProducts,
            productId: line.productId,
            quantity: line.quantity,
          );
        } on StateError catch (e) {
          if (e.message == 'INSUFFICIENT_STOCK') {
            throw ApiException(
              'Insufficient station stock',
              code: 'INSUFFICIENT_STOCK',
            );
          }
          rethrow;
        }
        lineStockPlans[i] = plan;
        for (final MapEntry<String, int> entry in plan.entries) {
          stockToDeduct[entry.key] =
              (stockToDeduct[entry.key] ?? 0) + entry.value;
        }
      }
      final Set<String> stockProductIds = stockToDeduct.keys.toSet();
      await Future.wait(
        stockProductIds.map((String productId) async {
          if (productSnaps.containsKey(productId)) {
            return;
          }
          productSnaps[productId] = await _db
              .collection(FirestorePaths.products)
              .doc(productId)
              .get();
        }),
      );
      for (final MapEntry<String, int> entry in stockToDeduct.entries) {
        final DocumentSnapshot<Map<String, dynamic>>? snap =
            productSnaps[entry.key];
        if (snap == null || !snap.exists) {
          throw ApiException('Product not found', code: 'NOT_FOUND');
        }
        final int stock =
            (mapProductDoc(snap)['stationStock'] as num?)?.toInt() ?? 0;
        if (stock < entry.value) {
          throw ApiException('Insufficient station stock', code: 'INSUFFICIENT_STOCK');
        }
      }

      final WriteBatch batch = _db.batch();
      for (final MapEntry<String, int> entry in stockToDeduct.entries) {
        final DocumentSnapshot<Map<String, dynamic>> productSnap =
            productSnaps[entry.key]!;
        batch.update(productSnap.reference, <String, dynamic>{
          'stationStock': FieldValue.increment(-entry.value),
          'updatedAt': serverTimestamp(),
        });
      }
      for (var i = 0; i < parsed.length; i++) {
        final _StationSaleBatchLine line = parsed[i];
        final DocumentReference<Map<String, dynamic>> saleRef =
            _db.collection(FirestorePaths.stationSales).doc();
        final Map<String, int>? plan = lineStockPlans[i];
        if (plan != null) {
          for (final MapEntry<String, int> entry in plan.entries) {
            final DocumentReference<Map<String, dynamic>> movRef =
                _db.collection(FirestorePaths.stockMovements).doc();
            batch.set(movRef, <String, dynamic>{
              'productId': entry.key,
              'type': 'out',
              'quantity': entry.value,
              'reason': 'station_sale',
              'referenceId': saleRef.id,
              'createdById': actorId,
              'createdAt': serverTimestamp(),
            });
          }
        }
        String? noteToSave = line.note?.trim();
        if ((noteToSave == null || noteToSave.isEmpty) &&
            fillingSale &&
            line.fillingLineSlot != null &&
            line.fillingLineSlot! <= 1 &&
            line.unitPrice == 0) {
          noteToSave = 'كوبون';
        }
        batch.set(saleRef, <String, dynamic>{
          'productId': line.productId,
          'quantity': line.quantity,
          'unitPrice': line.unitPrice,
          'totalAmount': line.quantity * line.unitPrice,
          'soldById': actorId,
          if (noteToSave != null && noteToSave.isNotEmpty) 'note': noteToSave,
          if (paymentMethodToSave != null) 'paymentMethod': paymentMethodToSave,
          'createdAt': serverTimestamp(),
          'updatedAt': serverTimestamp(),
        });
      }
      await batch.commit();
      clearCatalogCache();
    } on ApiException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _apiExceptionFromFirebase(e);
    }
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

      final List<
          ({
            String productId,
            String stockProductId,
            int qty,
            double unitPrice,
            int? fillingLineSlot,
          })> parsed = <({
        String productId,
        String stockProductId,
        int qty,
        double unitPrice,
        int? fillingLineSlot,
      })>[];
      for (final Map<String, dynamic> line in lines) {
        final Object? rawProductId = line['productId'];
        if (rawProductId is! String || rawProductId.isEmpty) {
          throw ApiException('Invalid product', code: 'NOT_FOUND');
        }
        final Object? rawQty = line['quantity'];
        final Object? rawUnitPrice = line['unitPrice'];
        if (rawQty is! num || rawUnitPrice is! num) {
          throw ApiException('Invalid debt line', code: 'VALIDATION');
        }
        final int qty = rawQty.toInt();
        if (qty <= 0) {
          continue;
        }
        final String? rawStockId = line['stockProductId'] as String?;
        final int? fillingLineSlot = (line['fillingLineSlot'] as num?)?.toInt();
        parsed.add(
          (
            productId: rawProductId,
            stockProductId: (rawStockId != null && rawStockId.isNotEmpty)
                ? rawStockId
                : rawProductId,
            qty: qty,
            unitPrice: rawUnitPrice.toDouble(),
            fillingLineSlot: fillingLineSlot,
          ),
        );
      }
      if (parsed.isEmpty) {
        throw ApiException('No debt lines', code: 'EMPTY_LINES');
      }

      final Set<String> uniqueProductIds = <String>{
        for (final ({
              String productId,
              String stockProductId,
              int qty,
              double unitPrice,
              int? fillingLineSlot,
            }) line in parsed)
          line.productId,
      };
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> productSnaps =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      await Future.wait(
        uniqueProductIds.map((String productId) async {
          productSnaps[productId] = await _db
              .collection(FirestorePaths.products)
              .doc(productId)
              .get();
        }),
      );

      final List<Map<String, dynamic>> catalogProducts =
          await _loadActiveProductsList();
      final Map<String, int> stockToDeduct = <String, int>{};
      for (final ({
            String productId,
            String stockProductId,
            int qty,
            double unitPrice,
            int? fillingLineSlot,
          }) line in parsed) {
        final DocumentSnapshot<Map<String, dynamic>> productSnap =
            productSnaps[line.productId]!;
        if (!productSnap.exists) {
          throw ApiException(
            'Product not found or inactive',
            code: 'NOT_FOUND',
          );
        }
        final Map<String, dynamic> product = mapProductDoc(productSnap);
        if (product['isActive'] == false) {
          throw ApiException(
            'Product not found or inactive',
            code: 'NOT_FOUND',
          );
        }
        final bool fillingDebt = line.fillingLineSlot != null;
        if (shouldSkipStationStockForDebtLine(
          product: product,
          fillingLineSlot: line.fillingLineSlot,
          fillingDebt: fillingDebt,
        )) {
          continue;
        }
        final Map<String, int> plan = planStationStockDeduction(
          products: catalogProducts,
          productId: line.stockProductId,
          quantity: line.qty,
        );
        for (final MapEntry<String, int> entry in plan.entries) {
          stockToDeduct[entry.key] =
              (stockToDeduct[entry.key] ?? 0) + entry.value;
        }
      }

      final Set<String> stockProductIds = stockToDeduct.keys.toSet();
      await Future.wait(
        stockProductIds.map((String productId) async {
          if (productSnaps.containsKey(productId)) {
            return;
          }
          productSnaps[productId] = await _db
              .collection(FirestorePaths.products)
              .doc(productId)
              .get();
        }),
      );

      for (final MapEntry<String, int> entry in stockToDeduct.entries) {
        final DocumentSnapshot<Map<String, dynamic>>? productSnap =
            productSnaps[entry.key];
        if (productSnap == null || !productSnap.exists) {
          throw ApiException('Product not found', code: 'NOT_FOUND');
        }
        final Map<String, dynamic> product = mapProductDoc(productSnap);
        final int stock = (product['stationStock'] as num?)?.toInt() ?? 0;
        if (stock < entry.value) {
          throw ApiException('Insufficient station stock', code: 'INSUFFICIENT_STOCK');
        }
      }

      // WriteBatch بدل runTransaction — على Flutter Web لا تُلفَّ أخطاء المعاملة بشكل صحيح.
      final WriteBatch batch = _db.batch();
      for (final MapEntry<String, int> entry in stockToDeduct.entries) {
        final DocumentSnapshot<Map<String, dynamic>> productSnap =
            productSnaps[entry.key]!;
        batch.update(productSnap.reference, <String, dynamic>{
          'stationStock': FieldValue.increment(-entry.value),
          'updatedAt': serverTimestamp(),
        });
        final DocumentReference<Map<String, dynamic>> movRef =
            _db.collection(FirestorePaths.stockMovements).doc();
        batch.set(movRef, <String, dynamic>{
          'productId': entry.key,
          'type': 'out',
          'quantity': entry.value,
          'reason': 'station_debt',
          'referenceId': null,
          'createdById': actor['id'],
          'createdAt': serverTimestamp(),
        });
      }
      for (final ({
            String productId,
            String stockProductId,
            int qty,
            double unitPrice,
            int? fillingLineSlot,
          }) line in parsed) {
        final DocumentReference<Map<String, dynamic>> debtRef =
            _db.collection(FirestorePaths.stationDebtEntries).doc();
        batch.set(debtRef, <String, dynamic>{
          'debtorName': debtorName.trim(),
          'productId': line.productId,
          'quantity': line.qty,
          'unitPrice': line.unitPrice,
          'totalAmount': line.qty * line.unitPrice,
          'recordedById': actor['id'],
          'recordingSource': recordingSource,
          'repaidAt': null,
          'createdAt': serverTimestamp(),
          'updatedAt': serverTimestamp(),
        });
      }
      await batch.commit();
      clearCatalogCache();
    } on ApiException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _apiExceptionFromFirebase(e);
    } on StateError catch (e) {
      if (e.message == 'INSUFFICIENT_STOCK') {
        throw ApiException('Insufficient station stock', code: 'INSUFFICIENT_STOCK');
      }
      rethrow;
    }
  }

  Map<String, dynamic> _vehicleSaleAsDebtEntry(Map<String, dynamic> sale) {
    return <String, dynamic>{
      'id': sale['id'],
      'debtorName': sale['debtorName'],
      'productId': sale['productId'],
      'product': sale['product'],
      'quantity': sale['quantity'],
      'unitPrice': sale['unitPrice'],
      'totalAmount': sale['totalAmount'],
      'saleDestination': sale['saleDestination']?.toString() ?? 'home',
      'recordedById': sale['driverId'],
      'recordedBy': sale['driver'],
      'recordingSource': 'vehicle',
      'vehicleSaleId': sale['id'],
      'repaidAt': sale['repaidAt'],
      'createdAt': sale['createdAt'],
    };
  }

  Future<Map<String, dynamic>> listStationDebtEntries({
    int page = 1,
    int limit = 100,
  }) async {
    await _requireStaffOrDriver();
    final Map<String, dynamic> actor = await _auth.currentActor();
    final List<Object> results = await Future.wait<Object>(<Future<Object>>[
      _db
          .collection(FirestorePaths.stationDebtEntries)
          .orderBy('createdAt', descending: true)
          .get(),
      _fetchVehicleSalesForDebtList(actor),
    ]);
    final QuerySnapshot<Map<String, dynamic>> stationSnap =
        results[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> vehicleSnap =
        results[1] as QuerySnapshot<Map<String, dynamic>>;

    final Map<String, Map<String, dynamic>> rawStationDebtById =
        <String, Map<String, dynamic>>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in stationSnap.docs)
        doc.id: doc.data(),
    };
    final List<Map<String, dynamic>> stationItems =
        (await _mapStationDebtsBatch(stationSnap.docs))
            .map((Map<String, dynamic> item) {
              final String? id = item['id']?.toString();
              if (id == null) {
                return item;
              }
              final Map<String, dynamic>? raw = rawStationDebtById[id];
              if (raw == null || raw.containsKey('recordingSource')) {
                return item;
              }
              return <String, dynamic>{
                ...item,
                'recordingSource': 'vehicle',
              };
            })
            .toList(growable: false);
    final bool isDriver = actor['role']?.toString() == 'driver';
    final String? driverId = isDriver ? actor['id']?.toString() : null;
    final List<Map<String, dynamic>> openStation = isDriver && driverId != null
        ? stationItems
            .where(
              (Map<String, dynamic> e) =>
                  isDriverVehicleDebtEntry(e, driverId: driverId),
            )
            .toList(growable: false)
        : stationItems
            .where(isUnpaidDebtEntry)
            .toList(growable: false);
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> openVehicleDebtDocs =
        vehicleSnap.docs
            .where(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  isOpenVehicleDebtSale(doc.data()),
            )
            .toList(growable: false);
    final List<Map<String, dynamic>> vehicleSales =
        await _mapVehicleSalesBatch(openVehicleDebtDocs);
    final List<Map<String, dynamic>> vehicleDebts = vehicleSales
        .map(_vehicleSaleAsDebtEntry)
        .toList(growable: false);

    final List<Map<String, dynamic>> merged = <Map<String, dynamic>>[
      ...openStation,
      ...vehicleDebts,
    ];
    merged.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime? da = _debtEntrySortDate(a);
      final DateTime? db = _debtEntrySortDate(b);
      if (da == null && db == null) {
        return 0;
      }
      if (da == null) {
        return 1;
      }
      if (db == null) {
        return -1;
      }
      return db.compareTo(da);
    });
    return _paginate(merged, page: page, limit: limit);
  }

  /// كل سجلات دين المحطة (مفتوحة ومسدّدة) لملخص مبيعات المحطة اليومي.
  Future<Map<String, dynamic>> listStationDebtEntriesForSummary({
    int page = 1,
    int limit = 100,
  }) async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.stationDebtEntries)
        .orderBy('createdAt', descending: true)
        .get();
    final List<Map<String, dynamic>> items =
        await _mapStationDebtsBatch(snap.docs);
    final List<Map<String, dynamic>> stationOnly = items
        .where(isStationDebtSummaryEntry)
        .toList(growable: false);
    return _paginate(stationOnly, page: page, limit: limit);
  }

  /// جلب مبيعات السيارة للقائمة بدون فهرس مركّب (تصفية/ترتيب في الذاكرة).
  Future<QuerySnapshot<Map<String, dynamic>>> _fetchVehicleSalesForDebtList(
    Map<String, dynamic> actor,
  ) {
    if (actor['role'] == 'driver') {
      return _db
          .collection(FirestorePaths.vehicleSales)
          .where('driverId', isEqualTo: actor['id'])
          .get();
    }
    return _db
        .collection(FirestorePaths.vehicleSales)
        .where('isDebt', isEqualTo: true)
        .get();
  }

  DateTime? _debtEntrySortDate(Map<String, dynamic> entry) {
    final Object? raw = entry['createdAt'];
    if (raw is DateTime) {
      return raw;
    }
    return timestampToDate(raw) ?? DateTime.tryParse(raw?.toString() ?? '');
  }

  Future<Map<String, dynamic>> repayStationDebt({
    required String debtorName,
    String? paymentMethod,
  }) async {
    return _repayDebt(
      debtorName: debtorName,
      fromVehicle: false,
      paymentMethod: paymentMethod,
    );
  }

  Future<Map<String, dynamic>> repayStationDebtFromVehicle({
    required String debtorName,
    String? paymentMethod,
  }) async {
    try {
      await _requireStaffOrDriver();
      final Map<String, dynamic> actor = await _auth.currentActor();
      final String name = normalizeDebtorName(debtorName);
      if (name.isEmpty) {
        throw ApiException('No unpaid debt for this person', code: 'NOT_FOUND');
      }
      final String? paymentMethodToSave =
          paymentMethod?.trim().isNotEmpty == true
              ? paymentMethod!.trim().toLowerCase()
              : 'cash';
      Query<Map<String, dynamic>> q = _db
          .collection(FirestorePaths.vehicleSales)
          .where('isDebt', isEqualTo: true)
          .where('repaidAt', isNull: true);
      if (actor['role'] == 'driver') {
        q = q.where('driverId', isEqualTo: actor['id']);
      }
      final QuerySnapshot<Map<String, dynamic>> snap = await q.get();
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> debts = snap.docs
          .where(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                normalizeDebtorName(doc.data()['debtorName']?.toString()) ==
                name,
          )
          .toList(growable: false);
      if (debts.isEmpty) {
        throw ApiException('No unpaid debt for this person', code: 'NOT_FOUND');
      }
      final WriteBatch batch = _db.batch();
      final DateTime now = DateTime.now();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> debtDoc in debts) {
        final Map<String, dynamic> debt = debtDoc.data();
        batch.update(debtDoc.reference, <String, dynamic>{
          'repaidAt': Timestamp.fromDate(now),
          'updatedAt': serverTimestamp(),
        });
        final DocumentReference<Map<String, dynamic>> repaymentRef =
            _db.collection(FirestorePaths.vehicleSales).doc();
        batch.set(repaymentRef, <String, dynamic>{
          'vehicleId': debt['vehicleId'],
          'driverId': debt['driverId'],
          'productId': debt['productId'],
          'quantity': debt['quantity'],
          'unitPrice': debt['unitPrice'],
          'totalAmount': debt['totalAmount'],
          'saleDestination': debt['saleDestination'] ?? 'home',
          'isDebt': false,
          'settledFromDebtSaleId': debtDoc.id,
          'paymentMethod': paymentMethodToSave,
          'repaidAt': null,
          'createdAt': serverTimestamp(),
          'updatedAt': serverTimestamp(),
        });
      }
      await batch.commit();
      clearCatalogCache();
      return <String, dynamic>{'salesCreated': debts.length};
    } on ApiException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _apiExceptionFromFirebase(e);
    }
  }

  Future<Map<String, dynamic>> _repayDebt({
    required String debtorName,
    required bool fromVehicle,
    String? paymentMethod,
  }) async {
    if (fromVehicle) {
      return repayStationDebtFromVehicle(
        debtorName: debtorName,
        paymentMethod: paymentMethod,
      );
    }
    try {
    await _requireStaff();
    final Map<String, dynamic> actor = await _auth.currentActor();
    final String name = normalizeDebtorName(debtorName);
    if (name.isEmpty) {
      throw ApiException('No unpaid debt for this person', code: 'NOT_FOUND');
    }
    final String? paymentMethodToSave =
        paymentMethod?.trim().isNotEmpty == true
            ? paymentMethod!.trim().toLowerCase()
            : 'cash';
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.stationDebtEntries)
        .where('repaidAt', isNull: true)
        .get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> entries =
        snap.docs
            .where(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  normalizeDebtorName(doc.data()['debtorName']?.toString()) ==
                  name,
            )
            .toList(growable: false);
    if (entries.isEmpty) {
      throw ApiException('No unpaid debt for this person', code: 'NOT_FOUND');
    }
    final WriteBatch batch = _db.batch();
    final DateTime now = DateTime.now();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> entry in entries) {
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
        'settledFromDebtId': entry.id,
        'paymentMethod': paymentMethodToSave,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      batch.update(entry.reference, <String, dynamic>{
        'repaidAt': Timestamp.fromDate(now),
        'updatedAt': serverTimestamp(),
      });
    }
    await batch.commit();
    clearCatalogCache();
    return <String, dynamic>{'salesCreated': entries.length};
    } on ApiException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _apiExceptionFromFirebase(e);
    }
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
    final DateTime? from = parseYmd(dateFrom);
    final DateTime? to = parseYmd(dateTo);
    if (from != null) {
      q = q.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay(from)),
      );
    }
    if (to != null) {
      q = q.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay(to)),
      );
    }
    final QuerySnapshot<Map<String, dynamic>> snap =
        await q.orderBy('createdAt', descending: true).get();
    final List<Map<String, dynamic>> items =
        await _mapVehicleSalesBatch(snap.docs);
    return _paginate(items, page: page, limit: limit.clamp(1, 100));
  }

  /// تسجيل عدة أسطر بيع دفعة واحدة — طلب Firestore واحد بدل معاملة لكل سطر.
  Future<void> createVehicleSalesBatch({
    required String vehicleId,
    required List<Map<String, dynamic>> lines,
    String saleDestination = 'home',
    String? paymentMethod,
  }) async {
    if (lines.isEmpty) {
      throw ApiException('No sale lines', code: 'EMPTY_LINES');
    }
    try {
      final Map<String, dynamic> actor = await _auth.currentActor();
      final String role = actor['role']?.toString() ?? '';
      final String actorId = actor['id']!.toString();

      final DocumentSnapshot<Map<String, dynamic>> vehicleSnap =
          await _db.collection(FirestorePaths.vehicles).doc(vehicleId).get();
      if (!vehicleSnap.exists) {
        throw ApiException('Vehicle not found', code: 'NOT_FOUND');
      }
      final String? vehicleDriverId = vehicleSnap.data()?['driverId']?.toString();

      final List<_VehicleSaleBatchLine> parsed = <_VehicleSaleBatchLine>[];
      for (final Map<String, dynamic> line in lines) {
        final Object? rawProductId = line['productId'];
        final Object? rawQty = line['quantity'];
        final Object? rawUnitPrice = line['unitPrice'];
        if (rawProductId is! String || rawProductId.isEmpty) {
          throw ApiException('Invalid product', code: 'NOT_FOUND');
        }
        if (rawQty is! num || rawUnitPrice is! num) {
          throw ApiException('Invalid sale line', code: 'VALIDATION');
        }
        final int qty = rawQty.toInt();
        if (qty <= 0) {
          continue;
        }
        parsed.add(
          _VehicleSaleBatchLine(
            productId: rawProductId,
            quantity: qty,
            unitPrice: rawUnitPrice.toDouble(),
            stockProductId: line['stockProductId'] as String?,
            debtorName: line['debtorName'] as String?,
            isDebt: line['isDebt'] == true,
            skipLoadDeduction: line['skipLoadDeduction'] == true,
            deductStationStock: line['deductStationStock'] == true,
          ),
        );
      }
      if (parsed.isEmpty) {
        throw ApiException('No sale lines', code: 'EMPTY_LINES');
      }

      if (role == 'driver') {
        if (vehicleDriverId != actorId) {
          throw ApiException('Vehicle not assigned to you', code: 'FORBIDDEN');
        }
      } else if (role == 'super_admin' || role == 'admin') {
        for (final _VehicleSaleBatchLine line in parsed) {
          if (!line.isDebt) {
            throw ApiException('Forbidden', code: 'FORBIDDEN');
          }
        }
      } else {
        throw ApiException('Forbidden', code: 'FORBIDDEN');
      }

      final String driverId = vehicleDriverId ?? actorId;
      final String dest = saleDestination == 'store' ? 'store' : 'home';
      final String? paymentMethodToSave =
          paymentMethod?.trim().isNotEmpty == true ? paymentMethod!.trim() : null;

      final List<Map<String, dynamic>> catalogProducts =
          await _loadActiveProductsList();
      final Map<String, Map<String, dynamic>> catalogById =
          <String, Map<String, dynamic>>{
        for (final Map<String, dynamic> p in catalogProducts)
          if ((p['id']?.toString() ?? '').isNotEmpty) p['id']!.toString(): p,
      };

      var needsLoadDeduction = false;
      for (final _VehicleSaleBatchLine line in parsed) {
        if (!line.skipLoadDeduction) {
          needsLoadDeduction = true;
          break;
        }
      }
      final List<_VehicleLoadAllocationRow> allocationRows =
          <_VehicleLoadAllocationRow>[];
      if (needsLoadDeduction) {
        final QuerySnapshot<Map<String, dynamic>> loadsSnap = await _db
            .collection(FirestorePaths.vehicleLoads)
            .where('vehicleId', isEqualTo: vehicleId)
            .where('status', isEqualTo: 'open')
            .orderBy('createdAt', descending: true)
            .get();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in loadsSnap.docs.reversed) {
          final Map<String, dynamic> data = doc.data();
          final String productId = data['productId']?.toString() ?? '';
          if (productId.isEmpty) {
            continue;
          }
          final Map<String, dynamic>? product = catalogById[productId];
          allocationRows.add(
            _VehicleLoadAllocationRow(
              row: _MutableVehicleLoadRow(
                ref: doc.reference,
                loaded: (data['quantityLoaded'] as num?)?.toInt() ?? 0,
                returned: (data['quantityReturned'] as num?)?.toInt() ?? 0,
                quantitySold: (data['quantitySold'] as num?)?.toInt() ?? 0,
              ),
              productId: productId,
              productName: product?['name']?.toString() ?? '',
            ),
          );
        }
      }

      void allocateFromVehicleLoads(String productId, int quantity) {
        int remaining = quantity;
        final Map<String, dynamic>? target = catalogById[productId];
        final String targetName = target?['name']?.toString() ?? '';
        for (final _VehicleLoadAllocationRow entry in allocationRows) {
          if (remaining <= 0) {
            break;
          }
          if (!vehicleLoadProductIdsMatch(
            targetProductId: productId,
            targetProductName: targetName,
            loadProductId: entry.productId,
            loadProductName: entry.productName,
          )) {
            continue;
          }
          final int avail = entry.row.available;
          if (avail <= 0) {
            continue;
          }
          final int take = min(avail, remaining);
          entry.row.sold += take;
          remaining -= take;
        }
        if (remaining > 0) {
          throw ApiException(
            'Insufficient loaded stock on vehicle for this product',
            code: 'INSUFFICIENT_STOCK',
          );
        }
      }
      final Map<String, int> stationStockToDeduct = <String, int>{};
      for (final _VehicleSaleBatchLine line in parsed) {
        if (!line.skipLoadDeduction) {
          final String deductProductId = line.stockProductId ?? line.productId;
          allocateFromVehicleLoads(deductProductId, line.quantity);
        }
        if (line.deductStationStock) {
          final String stockId = line.stockProductId ?? line.productId;
          final Map<String, int> plan = planStationStockDeduction(
            products: catalogProducts,
            productId: stockId,
            quantity: line.quantity,
          );
          for (final MapEntry<String, int> entry in plan.entries) {
            stationStockToDeduct[entry.key] =
                (stationStockToDeduct[entry.key] ?? 0) + entry.value;
          }
        }
      }

      final Map<String, DocumentSnapshot<Map<String, dynamic>>> productSnaps =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      if (stationStockToDeduct.isNotEmpty) {
        await Future.wait(
          stationStockToDeduct.keys.map((String productId) async {
            productSnaps[productId] = await _db
                .collection(FirestorePaths.products)
                .doc(productId)
                .get();
          }),
        );
        for (final MapEntry<String, int> entry in stationStockToDeduct.entries) {
          final DocumentSnapshot<Map<String, dynamic>>? snap =
              productSnaps[entry.key];
          if (snap == null || !snap.exists) {
            throw ApiException('Product not found', code: 'NOT_FOUND');
          }
          final int stock =
              (mapProductDoc(snap)['stationStock'] as num?)?.toInt() ?? 0;
          if (stock < entry.value) {
            throw ApiException(
              'Insufficient station stock',
              code: 'INSUFFICIENT_STOCK',
            );
          }
        }
      }

      final WriteBatch batch = _db.batch();
      for (final _VehicleLoadAllocationRow entry in allocationRows) {
        final _MutableVehicleLoadRow row = entry.row;
        final int soldDelta = row.sold - row.initialSold;
        if (soldDelta != 0) {
          batch.update(row.ref, <String, dynamic>{
            'quantitySold': FieldValue.increment(soldDelta),
            'updatedAt': serverTimestamp(),
          });
        }
      }
      for (final _VehicleSaleBatchLine line in parsed) {
        final DocumentReference<Map<String, dynamic>> saleRef =
            _db.collection(FirestorePaths.vehicleSales).doc();
        batch.set(saleRef, <String, dynamic>{
          'vehicleId': vehicleId,
          'driverId': driverId,
          'productId': line.productId,
          'quantity': line.quantity,
          'unitPrice': line.unitPrice,
          'totalAmount': line.quantity * line.unitPrice,
          'saleDestination': dest,
          'isDebt': line.isDebt,
          if (!line.isDebt &&
              paymentMethodToSave != null &&
              paymentMethodToSave.isNotEmpty)
            'paymentMethod': paymentMethodToSave,
          if (line.debtorName != null && line.debtorName!.trim().isNotEmpty)
            'debtorName': line.debtorName!.trim(),
          'repaidAt': null,
          'createdAt': serverTimestamp(),
          'updatedAt': serverTimestamp(),
        });
      }
      for (final MapEntry<String, int> entry in stationStockToDeduct.entries) {
        final DocumentSnapshot<Map<String, dynamic>> productSnap =
            productSnaps[entry.key]!;
        batch.update(productSnap.reference, <String, dynamic>{
          'stationStock': FieldValue.increment(-entry.value),
          'updatedAt': serverTimestamp(),
        });
        final DocumentReference<Map<String, dynamic>> movRef =
            _db.collection(FirestorePaths.stockMovements).doc();
        batch.set(movRef, <String, dynamic>{
          'productId': entry.key,
          'type': 'out',
          'quantity': entry.value,
          'reason': 'station_sale',
          'referenceId': null,
          'createdById': actorId,
          'createdAt': serverTimestamp(),
        });
      }
      await batch.commit();
      clearCatalogCache();
    } on ApiException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ApiException(
          'لا صلاحية لتسجيل البيع — تحقق من قواعد Firestore',
          code: 'PERMISSION_DENIED',
        );
      }
      throw _apiExceptionFromFirebase(e);
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
    await createVehicleSalesBatch(
      vehicleId: vehicleId,
      saleDestination: saleDestination,
      lines: <Map<String, dynamic>>[
        <String, dynamic>{
          'productId': productId,
          'quantity': quantity,
          'unitPrice': unitPrice,
          if (stockProductId != null) 'stockProductId': stockProductId,
          if (debtorName != null) 'debtorName': debtorName,
          'isDebt': isDebt,
          'skipLoadDeduction': skipLoadDeduction,
        },
      ],
    );
    return <String, dynamic>{'ok': true};
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

  static const String _stationCashBalanceDocId = 'main';

  Future<({double today, double yesterday})> _stationCashBalanceSnapshot() async {
    final DocumentSnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.stationCashBalance)
        .doc(_stationCashBalanceDocId)
        .get();
    final double today = snap.exists
        ? (snap.data()?['amount'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final QuerySnapshot<Map<String, dynamic>> entries = await _db
        .collection(FirestorePaths.stationCashEntries)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    final double yesterday = entries.docs.isEmpty
        ? 0.0
        : (entries.docs.first.data()['previousAmount'] as num?)?.toDouble() ??
            0.0;
    return (today: today, yesterday: yesterday);
  }

  Future<Map<String, dynamic>> getStationCashBalance() async {
    await _requireStaff();
    final ({double today, double yesterday}) snapshot =
        await _stationCashBalanceSnapshot();
    final DocumentSnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.stationCashBalance)
        .doc(_stationCashBalanceDocId)
        .get();
    if (!snap.exists) {
      return <String, dynamic>{
        'amount': snapshot.today,
        'yesterdayAmount': snapshot.yesterday,
      };
    }
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    return <String, dynamic>{
      'amount': snapshot.today,
      'yesterdayAmount': snapshot.yesterday,
      'updatedAt': timestampToDate(data['updatedAt']),
      'updatedById': data['updatedById'],
    };
  }

  Future<Map<String, dynamic>> listStationCashEntries({
    int page = 1,
    int limit = 50,
  }) async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.stationCashEntries)
        .orderBy('createdAt', descending: true)
        .get();
    final List<Map<String, dynamic>> items = snap.docs
        .map(mapStationCashEntryDoc)
        .toList(growable: false);
    return _paginate(items, page: page, limit: limit.clamp(1, 100));
  }

  Future<Map<String, dynamic>> setStationCashBalance({
    required double amount,
    String? note,
  }) async {
    if (amount < 0) {
      throw ApiException('Amount cannot be negative', code: 'INVALID_AMOUNT');
    }
    await _requireStaff();
    final Map<String, dynamic> actor = await _auth.currentActor();
    final DocumentReference<Map<String, dynamic>> balanceRef = _db
        .collection(FirestorePaths.stationCashBalance)
        .doc(_stationCashBalanceDocId);
    final DocumentSnapshot<Map<String, dynamic>> current = await balanceRef.get();
    final double previous = current.exists
        ? (current.data()?['amount'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final WriteBatch batch = _db.batch();
    batch.set(
      balanceRef,
      <String, dynamic>{
        'amount': amount,
        'updatedById': actor['id'],
        'updatedAt': serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    final DocumentReference<Map<String, dynamic>> entryRef =
        _db.collection(FirestorePaths.stationCashEntries).doc();
    batch.set(entryRef, <String, dynamic>{
      'amount': amount,
      'previousAmount': previous,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'createdById': actor['id'],
      'createdAt': serverTimestamp(),
    });
    await batch.commit();
    return <String, dynamic>{
      'amount': amount,
      'previousAmount': previous,
      'entryId': entryRef.id,
    };
  }

  Future<({double today, double yesterday})> _driverCashBalanceSnapshot(
    String driverId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.driverCashBalance)
        .doc(driverId)
        .get();
    final double today = snap.exists
        ? (snap.data()?['amount'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final QuerySnapshot<Map<String, dynamic>> entries = await _db
        .collection(FirestorePaths.driverCashEntries)
        .where('driverId', isEqualTo: driverId)
        .get();
    QueryDocumentSnapshot<Map<String, dynamic>>? latestEntry;
    DateTime? latestCreatedAt;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in entries.docs) {
      final DateTime? createdAt = timestampToDate(doc.data()['createdAt']);
      if (latestEntry == null ||
          (createdAt != null &&
              (latestCreatedAt == null || createdAt.isAfter(latestCreatedAt)))) {
        latestEntry = doc;
        latestCreatedAt = createdAt;
      }
    }
    final double yesterday = latestEntry == null
        ? 0.0
        : (latestEntry.data()['previousAmount'] as num?)?.toDouble() ?? 0.0;
    return (today: today, yesterday: yesterday);
  }

  Future<String> _requireDriverActorId() async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    if (actor['role'] != 'driver') {
      throw ApiException('Driver access only', code: 'FORBIDDEN');
    }
    final String? id = actor['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ApiException('Driver not found', code: 'FORBIDDEN');
    }
    return id;
  }

  Future<Map<String, dynamic>> getDriverCashBalance() async {
    final String driverId = await _requireDriverActorId();
    final ({double today, double yesterday}) snapshot =
        await _driverCashBalanceSnapshot(driverId);
    final DocumentSnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.driverCashBalance)
        .doc(driverId)
        .get();
    if (!snap.exists) {
      return <String, dynamic>{
        'amount': snapshot.today,
        'yesterdayAmount': snapshot.yesterday,
        'driverId': driverId,
      };
    }
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    return <String, dynamic>{
      'amount': snapshot.today,
      'yesterdayAmount': snapshot.yesterday,
      'driverId': driverId,
      'updatedAt': timestampToDate(data['updatedAt']),
      'updatedById': data['updatedById'],
    };
  }

  Future<Map<String, dynamic>> listDriverCashEntries({
    int page = 1,
    int limit = 50,
  }) async {
    final String driverId = await _requireDriverActorId();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.driverCashEntries)
        .where('driverId', isEqualTo: driverId)
        .get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedDocs =
        snap.docs.toList(growable: true)
          ..sort(
            (
              QueryDocumentSnapshot<Map<String, dynamic>> a,
              QueryDocumentSnapshot<Map<String, dynamic>> b,
            ) {
              final DateTime? aAt = timestampToDate(a.data()['createdAt']);
              final DateTime? bAt = timestampToDate(b.data()['createdAt']);
              return (bAt ?? DateTime(0)).compareTo(aAt ?? DateTime(0));
            },
          );
    final List<Map<String, dynamic>> items = sortedDocs
        .map(mapDriverCashEntryDoc)
        .toList(growable: false);
    return _paginate(items, page: page, limit: limit.clamp(1, 100));
  }

  Future<Map<String, dynamic>> setDriverCashBalance({
    required double amount,
    String? note,
  }) async {
    if (amount < 0) {
      throw ApiException('Amount cannot be negative', code: 'INVALID_AMOUNT');
    }
    final String driverId = await _requireDriverActorId();
    final Map<String, dynamic> actor = await _auth.currentActor();
    final DocumentReference<Map<String, dynamic>> balanceRef = _db
        .collection(FirestorePaths.driverCashBalance)
        .doc(driverId);
    final DocumentSnapshot<Map<String, dynamic>> current = await balanceRef.get();
    final double previous = current.exists
        ? (current.data()?['amount'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final WriteBatch batch = _db.batch();
    batch.set(
      balanceRef,
      <String, dynamic>{
        'amount': amount,
        'driverId': driverId,
        'updatedById': actor['id'],
        'updatedAt': serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    final DocumentReference<Map<String, dynamic>> entryRef =
        _db.collection(FirestorePaths.driverCashEntries).doc();
    batch.set(entryRef, <String, dynamic>{
      'driverId': driverId,
      'amount': amount,
      'previousAmount': previous,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'createdById': actor['id'],
      'createdAt': serverTimestamp(),
    });
    await batch.commit();
    return <String, dynamic>{
      'amount': amount,
      'previousAmount': previous,
      'entryId': entryRef.id,
      'driverId': driverId,
    };
  }

  Future<({
    Map<String, double> todayByDriverId,
    Map<String, double> yesterdayByDriverId,
    Map<String, Map<String, double>> recordedOnDayByDriverId,
    Map<String, Map<String, double>> recordedByMonthByDriverId,
  })> _driverCashProfitContext() async {
    final QuerySnapshot<Map<String, dynamic>> balanceSnap = await _db
        .collection(FirestorePaths.driverCashBalance)
        .get();
    final Map<String, double> todayByDriverId = <String, double>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in balanceSnap.docs)
        doc.id: _num(doc.data()['amount']),
    };
    final QuerySnapshot<Map<String, dynamic>> entriesSnap = await _db
        .collection(FirestorePaths.driverCashEntries)
        .get();
    final List<Map<String, dynamic>> entries = entriesSnap.docs
        .map(mapDriverCashEntryDoc)
        .toList(growable: false);
    return (
      todayByDriverId: todayByDriverId,
      yesterdayByDriverId: buildDriverCashYesterdayByDriver(entries),
      recordedOnDayByDriverId: buildDriverCashRecordedOnDayByDriver(entries),
      recordedByMonthByDriverId: buildDriverCashRecordedByMonthByDriver(entries),
    );
  }

  Future<Map<String, dynamic>> listReturns({int page = 1, int limit = 100}) async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestorePaths.vehicleLoads).orderBy('updatedAt', descending: true).get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> returned =
        snap.docs
            .where(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  ((doc.data()['quantityReturned'] as num?)?.toInt() ?? 0) > 0,
            )
            .toList(growable: false);
    final List<Map<String, dynamic>> items =
        await _mapVehicleLoadsBatch(returned);
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) async {
    try {
      final Map<String, dynamic> actor = await _auth.currentActor();
      final DocumentSnapshot<Map<String, dynamic>> loadSnap = await _db
          .collection(FirestorePaths.vehicleLoads)
          .doc(vehicleLoadId)
          .get();
      if (!loadSnap.exists) {
        throw ApiException('Vehicle load not found', code: 'NOT_FOUND');
      }
      final Map<String, dynamic> load = loadSnap.data()!;
      if (actor['role'] == 'driver') {
        final String actorId = actor['id']!.toString();
        final String? loadDriverId = load['driverId']?.toString();
        if (loadDriverId != actorId) {
          final String? vehicleId = load['vehicleId']?.toString();
          if (vehicleId == null || vehicleId.isEmpty) {
            throw ApiException('Forbidden', code: 'FORBIDDEN');
          }
          final DocumentSnapshot<Map<String, dynamic>> vehicleSnap = await _db
              .collection(FirestorePaths.vehicles)
              .doc(vehicleId)
              .get();
          final String? vehicleDriverId =
              vehicleSnap.data()?['driverId']?.toString();
          if (vehicleDriverId != actorId) {
            throw ApiException('Forbidden', code: 'FORBIDDEN');
          }
        }
      }
      final int loaded = (load['quantityLoaded'] as num?)?.toInt() ?? 0;
      final int sold = (load['quantitySold'] as num?)?.toInt() ?? 0;
      final int prevReturned = (load['quantityReturned'] as num?)?.toInt() ?? 0;
      final int physical = loaded - sold - prevReturned;
      if (quantityReturned > physical) {
        throw ApiException(
          'Return quantity exceeds remaining on load',
          code: 'VALIDATION',
        );
      }
      final String productId = load['productId'] as String;
      final DocumentSnapshot<Map<String, dynamic>> productSnap = await _db
          .collection(FirestorePaths.products)
          .doc(productId)
          .get();
      final WriteBatch batch = _db.batch();
      batch.update(loadSnap.reference, <String, dynamic>{
        'quantityReturned': FieldValue.increment(quantityReturned),
        'updatedAt': serverTimestamp(),
      });
      if (productSnap.exists) {
        batch.update(productSnap.reference, <String, dynamic>{
          'stationStock': FieldValue.increment(quantityReturned),
          'updatedAt': serverTimestamp(),
        });
        final DocumentReference<Map<String, dynamic>> movRef =
            _db.collection(FirestorePaths.stockMovements).doc();
        batch.set(movRef, <String, dynamic>{
          'productId': productId,
          'type': 'in',
          'quantity': quantityReturned,
          'reason': 'vehicle_return',
          'referenceId': vehicleLoadId,
          'createdById': actor['id'],
          'createdAt': serverTimestamp(),
        });
      }
      await batch.commit();
      clearCatalogCache();
      return <String, dynamic>{'ok': true};
    } on ApiException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ApiException(
          'لا صلاحية لتسجيل الإرجاع — تحقق من قواعد Firestore',
          code: 'PERMISSION_DENIED',
        );
      }
      throw _apiExceptionFromFirebase(e);
    }
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

    void addAmount(Object? createdAt, double amount) {
      if (amount == 0) {
        return;
      }
      final String? key = profitRowLocalYmd(timestampToDate(createdAt));
      if (key == null || key.isEmpty) {
        return;
      }
      byDay[key] = (byDay[key] ?? 0) + amount;
    }

    // مبيعات المحطة (بما فيها سداد الدين المسجّل كمبيع).
    final QuerySnapshot<Map<String, dynamic>> stationSnap =
        await _db.collection(FirestorePaths.stationSales).get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in stationSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      addAmount(data['createdAt'], _num(data['totalAmount']));
    }

    // مبيعات المركبة النقدية فقط — نفس منطق KPI «مبيعات اليوم»
    // (يستثني تسجيل الدين المفتوح؛ سداد الدين يُحسب لأنه isDebt != true).
    final QuerySnapshot<Map<String, dynamic>> vehicleSnap =
        await _db.collection(FirestorePaths.vehicleSales).get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in vehicleSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      if (!isCashVehicleSaleRow(data)) {
        continue;
      }
      addAmount(data['createdAt'], _num(data['totalAmount']));
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
    final String todayYmd = ymd(startOfDay(now));
    final String yesterdayYmd =
        ymd(startOfDay(now).subtract(const Duration(days: 1)));

    final QuerySnapshot<Map<String, dynamic>> vehiclesSnap =
        await _db.collection(FirestorePaths.vehicles).get();
    final Map<String, String> vehicleIdToNumber = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['vehicleNumber']?.toString() ?? '',
    };
    final Map<String, String> vehicleIdToDriverId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['driverId']?.toString() ?? '',
    };
    final Map<String, String> driverIdToVehicleId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        if ((doc.data()['driverId']?.toString() ?? '').isNotEmpty)
          doc.data()['driverId']!.toString(): doc.id,
    };

    final Map<String, double> stationSalesByDay = <String, double>{};
    final Map<String, Map<String, double>> vehicleGrossByDay =
        <String, Map<String, double>>{};
    final Map<String, List<Map<String, dynamic>>> expensesByDay =
        <String, List<Map<String, dynamic>>>{};

    final QuerySnapshot<Map<String, dynamic>> stationSnap = await _db
        .collection(FirestorePaths.stationSales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in stationSnap.docs) {
      profitAccumulateByDay(
        stationSalesByDay,
        profitRowLocalYmd(timestampToDate(doc.data()['createdAt'])),
        _num(doc.data()['totalAmount']),
      );
    }

    final QuerySnapshot<Map<String, dynamic>> vehicleSnap = await _db
        .collection(FirestorePaths.vehicleSales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in vehicleSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      if (!isCashVehicleSaleRow(data)) {
        continue;
      }
      final double amount = _num(data['totalAmount']);
      final String? vehicleId = data['vehicleId']?.toString();
      final String? dayYmd =
          profitRowLocalYmd(timestampToDate(data['createdAt']));
      profitAccumulateVehicleSalesByKey(
        vehicleGrossByDay,
        dayYmd,
        vehicleId,
        amount,
      );
    }

    final QuerySnapshot<Map<String, dynamic>> expensesSnap = await _db
        .collection(FirestorePaths.expenses)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in expensesSnap.docs) {
      final Map<String, dynamic> row = mapExpenseDoc(doc);
      profitAppendExpenseByDay(
        expensesByDay,
        profitRowLocalYmd(row['createdAt']),
        row,
      );
    }

    final ({double today, double yesterday}) cashSnapshot =
        await _stationCashBalanceSnapshot();
    final QuerySnapshot<Map<String, dynamic>> cashEntriesSnap = await _db
        .collection(FirestorePaths.stationCashEntries)
        .orderBy('createdAt')
        .get();
    final Map<String, double> cashRecordedOnDay = buildStationCashRecordedOnDay(
      cashEntriesSnap.docs.map(mapStationCashEntryDoc),
    );
    final ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    }) driverCash = await _driverCashProfitContext();

    final Set<String> dayKeys = <String>{
      todayYmd,
      yesterdayYmd,
      ...stationSalesByDay.keys,
      ...vehicleGrossByDay.keys,
      ...expensesByDay.keys,
      ...cashRecordedOnDay.keys,
    };

    final Map<String, Map<String, dynamic>> byDay =
        <String, Map<String, dynamic>>{};
    for (final String dayYmd in dayKeys) {
      byDay[dayYmd] = computeProfitDaySnapshot(
        stationSalesGross: stationSalesByDay[dayYmd] ?? 0,
        vehicleSalesGrossById:
            vehicleGrossByDay[dayYmd] ?? const <String, double>{},
        expenseRows: expensesByDay[dayYmd] ?? const <Map<String, dynamic>>[],
        stationCashBalance: resolveStationCashBalanceForDay(
          dayYmd,
          todayYmd: todayYmd,
          yesterdayYmd: yesterdayYmd,
          currentBalance: cashSnapshot.today,
          yesterdayBalance: cashSnapshot.yesterday,
          cashRecordedOnDay: cashRecordedOnDay,
        ),
        vehicleIdToNumber: vehicleIdToNumber,
        vehicleIdToDriverId: vehicleIdToDriverId,
        driverIdToVehicleId: driverIdToVehicleId,
        driverCashTodayByDriverId: driverCash.todayByDriverId,
        driverCashYesterdayByDriverId: driverCash.yesterdayByDriverId,
        driverCashRecordedOnDayByDriverId: driverCash.recordedOnDayByDriverId,
        dayYmd: dayYmd,
        todayYmd: todayYmd,
        yesterdayYmd: yesterdayYmd,
      );
    }

    final List<Map<String, dynamic>> profitDays =
        buildProfitDayCardsPayload(byDay, now);
    final Map<String, dynamic> todayPayload =
        byDay[todayYmd] ?? profitDays.first;

    return <String, dynamic>{
      'from': start.toIso8601String(),
      'to': end.toIso8601String(),
      'profitDays': profitDays,
      'today': todayPayload,
    };
  }

  Future<Map<String, dynamic>> reportsProfitLossMonthly() async {
    await _requireStaff();
    final DateTime now = DateTime.now();
    final DateTime rangeStart = DateTime(now.year, now.month - 11, 1);
    final DateTime rangeEnd = endOfDay(DateTime(now.year, now.month + 1, 0));

    final QuerySnapshot<Map<String, dynamic>> vehiclesSnap =
        await _db.collection(FirestorePaths.vehicles).get();
    final Map<String, String> vehicleIdToNumber = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['vehicleNumber']?.toString() ?? '',
    };
    final Map<String, String> vehicleIdToDriverId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['driverId']?.toString() ?? '',
    };
    final Map<String, String> driverIdToVehicleId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        if ((doc.data()['driverId']?.toString() ?? '').isNotEmpty)
          doc.data()['driverId']!.toString(): doc.id,
    };

    final Map<String, double> stationSalesByMonth = <String, double>{};
    final Map<String, Map<String, double>> vehicleGrossByMonth =
        <String, Map<String, double>>{};
    final Map<String, List<Map<String, dynamic>>> expensesByMonth =
        <String, List<Map<String, dynamic>>>{};

    final QuerySnapshot<Map<String, dynamic>> stationSnap = await _db
        .collection(FirestorePaths.stationSales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in stationSnap.docs) {
      profitAccumulateByKey(
        stationSalesByMonth,
        profitRowLocalMonthKey(timestampToDate(doc.data()['createdAt'])),
        _num(doc.data()['totalAmount']),
      );
    }

    final QuerySnapshot<Map<String, dynamic>> vehicleSnap = await _db
        .collection(FirestorePaths.vehicleSales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in vehicleSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      if (!isCashVehicleSaleRow(data)) {
        continue;
      }
      final double amount = _num(data['totalAmount']);
      final String? vehicleId = data['vehicleId']?.toString();
      final String? monthKey =
          profitRowLocalMonthKey(timestampToDate(data['createdAt']));
      profitAccumulateVehicleSalesByKey(
        vehicleGrossByMonth,
        monthKey,
        vehicleId,
        amount,
      );
    }

    final QuerySnapshot<Map<String, dynamic>> expensesSnap = await _db
        .collection(FirestorePaths.expenses)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in expensesSnap.docs) {
      final Map<String, dynamic> row = mapExpenseDoc(doc);
      profitAppendExpenseByKey(
        expensesByMonth,
        profitRowLocalMonthKey(row['createdAt']),
        row,
      );
    }

    final ({double today, double yesterday}) cashSnapshot =
        await _stationCashBalanceSnapshot();
    final QuerySnapshot<Map<String, dynamic>> cashEntriesSnap = await _db
        .collection(FirestorePaths.stationCashEntries)
        .orderBy('createdAt')
        .get();
    final Map<String, double> cashRecordedByMonth = buildStationCashRecordedByMonth(
      cashEntriesSnap.docs.map(mapStationCashEntryDoc),
    );

    final Set<String> monthKeys = <String>{
      profitMonthKey(now.year, now.month),
      profitMonthKey(
        profitCalendarPreviousMonth(now.year, now.month).y,
        profitCalendarPreviousMonth(now.year, now.month).m,
      ),
      ...stationSalesByMonth.keys,
      ...vehicleGrossByMonth.keys,
      ...expensesByMonth.keys,
      ...cashRecordedByMonth.keys,
    };

    final ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    }) driverCash = await _driverCashProfitContext();

    final Map<String, Map<String, dynamic>> byMonth =
        <String, Map<String, dynamic>>{};
    for (final String monthKey in monthKeys) {
      final List<String> parts = monthKey.split('-');
      if (parts.length != 2) {
        continue;
      }
      final int? year = int.tryParse(parts[0]);
      final int? month = int.tryParse(parts[1]);
      if (year == null || month == null) {
        continue;
      }
      byMonth[monthKey] = computeProfitDaySnapshot(
        stationSalesGross: stationSalesByMonth[monthKey] ?? 0,
        vehicleSalesGrossById:
            vehicleGrossByMonth[monthKey] ?? const <String, double>{},
        expenseRows:
            expensesByMonth[monthKey] ?? const <Map<String, dynamic>>[],
        stationCashBalance: resolveStationCashBalanceForMonth(
          year,
          month,
          currentYear: now.year,
          currentMonth: now.month,
          currentBalance: cashSnapshot.today,
          cashRecordedByMonth: cashRecordedByMonth,
        ),
        vehicleIdToNumber: vehicleIdToNumber,
        vehicleIdToDriverId: vehicleIdToDriverId,
        driverIdToVehicleId: driverIdToVehicleId,
        driverCashTodayByDriverId: driverCash.todayByDriverId,
        driverCashYesterdayByDriverId: const <String, double>{},
        driverCashRecordedOnDayByDriverId: const <String, Map<String, double>>{},
        cashMonthYear: year,
        cashMonth: month,
        cashCurrentYear: now.year,
        cashCurrentMonth: now.month,
        driverCashRecordedByMonthByDriverId:
            driverCash.recordedByMonthByDriverId,
        includeCashBalance: false,
      );
    }

    final List<Map<String, dynamic>> profitMonths =
        buildProfitMonthCardsPayload(byMonth, now);
    final String currentKey = profitMonthKey(now.year, now.month);
    final Map<String, dynamic> currentPayload =
        byMonth[currentKey] ?? profitMonths.first;

    return <String, dynamic>{
      'from': rangeStart.toIso8601String(),
      'to': rangeEnd.toIso8601String(),
      'profitMonths': profitMonths,
      'year': now.year,
      'month': now.month,
      'current': currentPayload,
    };
  }

  Future<({double today, double month})> _profitKpiTotalsForDashboard({
    required DateTime dayStart,
    required DateTime dayEnd,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    final DateTime now = DateTime.now();
    final String todayYmd = ymd(startOfDay(now));
    final String yesterdayYmd =
        ymd(startOfDay(now).subtract(const Duration(days: 1)));

    final List<Object> snaps = await Future.wait<Object>(<Future<Object>>[
      _db.collection(FirestorePaths.vehicles).get(),
      _driverCashProfitContext(),
      _stationCashBalanceSnapshot(),
      _db
          .collection(FirestorePaths.stationCashEntries)
          .orderBy('createdAt')
          .get(),
      _db
          .collection(FirestorePaths.stationSales)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get(),
      _db
          .collection(FirestorePaths.vehicleSales)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get(),
      _db
          .collection(FirestorePaths.expenses)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get(),
    ]);

    final QuerySnapshot<Map<String, dynamic>> vehiclesSnap =
        snaps[0] as QuerySnapshot<Map<String, dynamic>>;
    final ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    }) driverCash = snaps[1] as ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    });
    final ({double today, double yesterday}) cashSnapshot =
        snaps[2] as ({double today, double yesterday});
    final QuerySnapshot<Map<String, dynamic>> cashEntriesSnap =
        snaps[3] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> stationSnap =
        snaps[4] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> vehicleSnap =
        snaps[5] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> expensesSnap =
        snaps[6] as QuerySnapshot<Map<String, dynamic>>;

    final Map<String, String> vehicleIdToNumber = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['vehicleNumber']?.toString() ?? '',
    };
    final Map<String, String> vehicleIdToDriverId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['driverId']?.toString() ?? '',
    };
    final Map<String, String> driverIdToVehicleId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        if ((doc.data()['driverId']?.toString() ?? '').isNotEmpty)
          doc.data()['driverId']!.toString(): doc.id,
    };

    final List<Map<String, dynamic>> cashEntries = cashEntriesSnap.docs
        .map(mapStationCashEntryDoc)
        .toList(growable: false);
    final Map<String, double> cashRecordedOnDay =
        buildStationCashRecordedOnDay(cashEntries);
    final Map<String, double> cashRecordedByMonth =
        buildStationCashRecordedByMonth(cashEntries);

    var stationSalesDay = 0.0;
    var stationSalesMonth = 0.0;
    final Map<String, double> vehicleSalesDay = <String, double>{};
    final Map<String, double> vehicleSalesMonth = <String, double>{};
    final List<Map<String, dynamic>> expenseRowsDay = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> expenseRowsMonth =
        <Map<String, dynamic>>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in stationSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      final DateTime? created = timestampToDate(data['createdAt']);
      final double amount = _num(data['totalAmount']);
      if (isInRange(created, monthStart, monthEnd)) {
        stationSalesMonth += amount;
      }
      if (isInRange(created, dayStart, dayEnd)) {
        stationSalesDay += amount;
      }
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in vehicleSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      if (!isCashVehicleSaleRow(data)) {
        continue;
      }
      final DateTime? created = timestampToDate(data['createdAt']);
      final double amount = _num(data['totalAmount']);
      final String? vehicleId = data['vehicleId']?.toString();
      if (vehicleId == null || vehicleId.isEmpty) {
        continue;
      }
      if (isInRange(created, monthStart, monthEnd)) {
        vehicleSalesMonth[vehicleId] =
            (vehicleSalesMonth[vehicleId] ?? 0) + amount;
      }
      if (isInRange(created, dayStart, dayEnd)) {
        vehicleSalesDay[vehicleId] = (vehicleSalesDay[vehicleId] ?? 0) + amount;
      }
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in expensesSnap.docs) {
      final Map<String, dynamic> row = mapExpenseDoc(doc);
      final DateTime? created = timestampToDate(row['createdAt']);
      if (isInRange(created, monthStart, monthEnd)) {
        expenseRowsMonth.add(row);
      }
      if (isInRange(created, dayStart, dayEnd)) {
        expenseRowsDay.add(row);
      }
    }

    final Map<String, dynamic> todaySnapshot = computeProfitDaySnapshot(
      stationSalesGross: stationSalesDay,
      vehicleSalesGrossById: vehicleSalesDay,
      expenseRows: expenseRowsDay,
      stationCashBalance: resolveStationCashBalanceForDay(
        todayYmd,
        todayYmd: todayYmd,
        yesterdayYmd: yesterdayYmd,
        currentBalance: cashSnapshot.today,
        yesterdayBalance: cashSnapshot.yesterday,
        cashRecordedOnDay: cashRecordedOnDay,
      ),
      vehicleIdToNumber: vehicleIdToNumber,
      vehicleIdToDriverId: vehicleIdToDriverId,
      driverIdToVehicleId: driverIdToVehicleId,
      driverCashTodayByDriverId: driverCash.todayByDriverId,
      driverCashYesterdayByDriverId: driverCash.yesterdayByDriverId,
      driverCashRecordedOnDayByDriverId: driverCash.recordedOnDayByDriverId,
      dayYmd: todayYmd,
      todayYmd: todayYmd,
      yesterdayYmd: yesterdayYmd,
    );
    final Map<String, dynamic> monthSnapshot = computeProfitDaySnapshot(
      stationSalesGross: stationSalesMonth,
      vehicleSalesGrossById: vehicleSalesMonth,
      expenseRows: expenseRowsMonth,
      stationCashBalance: resolveStationCashBalanceForMonth(
        monthStart.year,
        monthStart.month,
        currentYear: now.year,
        currentMonth: now.month,
        currentBalance: cashSnapshot.today,
        cashRecordedByMonth: cashRecordedByMonth,
      ),
      vehicleIdToNumber: vehicleIdToNumber,
      vehicleIdToDriverId: vehicleIdToDriverId,
      driverIdToVehicleId: driverIdToVehicleId,
      driverCashTodayByDriverId: driverCash.todayByDriverId,
      driverCashYesterdayByDriverId: const <String, double>{},
      driverCashRecordedOnDayByDriverId: const <String, Map<String, double>>{},
      cashMonthYear: monthStart.year,
      cashMonth: monthStart.month,
      cashCurrentYear: now.year,
      cashCurrentMonth: now.month,
      driverCashRecordedByMonthByDriverId:
          driverCash.recordedByMonthByDriverId,
      includeCashBalance: false,
    );

    return (
      today: _num(todaySnapshot['total']),
      month: _num(monthSnapshot['total']),
    );
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
    double monthlyCartonSales = 0,
    double stationCashTodayAmount = 0,
    double stationCashYesterdayAmount = 0,
    double totalProfitToday = 0,
    double totalProfitMonth = 0,
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
        'totalProfitToday': totalProfitToday,
        'totalProfitMonth': totalProfitMonth,
        'totalMonthlySales': monthlyStation + monthlyVehicle,
        'totalMonthlyCartonSales': monthlyCartonSales,
        'stationCashTodayAmount': stationCashTodayAmount,
        'stationCashYesterdayAmount': stationCashYesterdayAmount,
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
      'totalProfitToday': totalProfitToday,
      'totalProfitMonth': totalProfitMonth,
      'totalMonthlySales': monthlyStation + monthlyVehicle,
      'totalMonthlyCartonSales': monthlyCartonSales,
      'stationCashTodayAmount': stationCashTodayAmount,
      'stationCashYesterdayAmount': stationCashYesterdayAmount,
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

    final Future<List<Object>> coreSnapsFuture = Future.wait<Object>(<Future<Object>>[
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
      _db
          .collection(FirestorePaths.vehicleSales)
          .where('isDebt', isEqualTo: true)
          .limit(400)
          .get(),
    ]);
    final Future<List<Object>> salesFastFuture = Future.wait<Object>(<Future<Object>>[
      _sumSales(FirestorePaths.stationSales, day.start, day.end),
      _sumVehicleCashSales(day.start, day.end),
      _sumExpenses(day.start, day.end),
      _sumSales(FirestorePaths.stationSales, month.start, month.end),
      _sumVehicleCashSales(month.start, month.end),
      _sumExpenses(month.start, month.end),
      _stationCashBalanceSnapshot(),
    ]);
    final Future<Map<String, dynamic>> cartonFuture =
        _superAdminCartonMetricsForRange(start: month.start, end: month.end);
    final Future<({double today, double month})> profitTotalsFuture =
        _profitKpiTotalsForDashboard(
      dayStart: day.start,
      dayEnd: day.end,
      monthStart: month.start,
      monthEnd: month.end,
    );

    final List<Object> coreSnaps = await coreSnapsFuture;
    final QuerySnapshot<Map<String, dynamic>> users =
        coreSnaps[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> vehicles =
        coreSnaps[1] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> products =
        coreSnaps[2] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> openLoads =
        coreSnaps[3] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> debtSnap =
        coreSnaps[4] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> vehicleDebtSnap =
        coreSnaps[5] as QuerySnapshot<Map<String, dynamic>>;
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
    final List<Map<String, dynamic>> debtPreview = _debtOpenPreviewFromEntries(
      entries: _openDebtPreviewRowsFromStationSnap(
        debtSnap,
        productById: productById,
      )..addAll(
          _openDebtPreviewRowsFromVehicleDebtSnap(
            vehicleDebtSnap,
            productById: productById,
          ),
        ),
      productById: productById,
    );

    void emitPartial({
      double stationToday = 0,
      double vehicleToday = 0,
      double expensesToday = 0,
      double monthlyStation = 0,
      double monthlyVehicle = 0,
      double monthlyExpenses = 0,
      double monthlyCartonSales = 0,
      double stationCashTodayAmount = 0,
      double stationCashYesterdayAmount = 0,
      double totalProfitToday = 0,
      double totalProfitMonth = 0,
    }) {
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
          stationToday: stationToday,
          vehicleToday: vehicleToday,
          expensesToday: expensesToday,
          monthlyStation: monthlyStation,
          monthlyVehicle: monthlyVehicle,
          monthlyExpenses: monthlyExpenses,
          monthlyCartonSales: monthlyCartonSales,
          stationCashTodayAmount: stationCashTodayAmount,
          stationCashYesterdayAmount: stationCashYesterdayAmount,
          totalProfitToday: totalProfitToday,
          totalProfitMonth: totalProfitMonth,
        ),
      );
    }

    emitPartial();

    final List<Object> salesFast = await salesFastFuture;
    final ({double today, double yesterday}) cashSnapshot =
        salesFast[6] as ({double today, double yesterday});
    emitPartial(
      stationToday: salesFast[0] as double,
      vehicleToday: salesFast[1] as double,
      expensesToday: salesFast[2] as double,
      monthlyStation: salesFast[3] as double,
      monthlyVehicle: salesFast[4] as double,
      monthlyExpenses: salesFast[5] as double,
      stationCashTodayAmount: cashSnapshot.today,
      stationCashYesterdayAmount: cashSnapshot.yesterday,
    );

    final List<Object> slowResults = await Future.wait<Object>(<Future<Object>>[
      cartonFuture,
      profitTotalsFuture,
    ]);
    final Map<String, dynamic> cartonMetrics =
        slowResults[0] as Map<String, dynamic>;
    final ({double today, double month}) profitTotals =
        slowResults[1] as ({double today, double month});

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
      stationToday: salesFast[0] as double,
      vehicleToday: salesFast[1] as double,
      expensesToday: salesFast[2] as double,
      monthlyStation: salesFast[3] as double,
      monthlyVehicle: salesFast[4] as double,
      monthlyExpenses: salesFast[5] as double,
      monthlyCartonSales:
          _num(cartonMetrics['monthlyCartonSalesTotalAmount']),
      stationCashTodayAmount: cashSnapshot.today,
      stationCashYesterdayAmount: cashSnapshot.yesterday,
      totalProfitToday: profitTotals.today,
      totalProfitMonth: profitTotals.month,
    );
  }

  Future<Map<String, dynamic>> _superAdminCartonMetricsForRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final List<Object> snaps = await Future.wait<Object>(<Future<Object>>[
      _db.collection(FirestorePaths.products).where('isActive', isEqualTo: true).get(),
      _db.collection(FirestorePaths.stationSales).get(),
      _db.collection(FirestorePaths.vehicleSales).get(),
      _db.collection(FirestorePaths.stationDebtEntries).get(),
      _db.collection(FirestorePaths.expenses).get(),
    ]);
    final QuerySnapshot<Map<String, dynamic>> productsSnap =
        snaps[0] as QuerySnapshot<Map<String, dynamic>>;
    final Map<String, Map<String, dynamic>> productById =
        <String, Map<String, dynamic>>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in productsSnap.docs)
        doc.id: mapProductDoc(doc),
    };

    final List<Map<String, dynamic>> products = productById.values.toList(
      growable: false,
    );
    final int cartonStock = aggregateStationStockForBalanceRow(
      products: products,
      rowIndex: 0,
    );

    double monthlyAmount = 0;
    int homeQty = 0;
    int storeQty = 0;
    var debtQty = 0;
    var debtAmount = 0.0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[1] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final Map<String, dynamic> sale = doc.data();
      if (isStationDebtRepaymentSale(sale)) {
        continue;
      }
      final String? note = sale['note']?.toString();
      if (note != null && note.startsWith('سداد دين')) {
        continue;
      }
      final DateTime? created = timestampToDate(sale['createdAt']);
      if (!isInRange(created, start, end)) {
        continue;
      }
      final String? productId = sale['productId']?.toString();
      final Map<String, dynamic>? product = productById[productId];
      if (!isCartonSaleRow(productId: productId, product: product)) {
        continue;
      }
      monthlyAmount += _num(sale['totalAmount']);
      homeQty += (sale['quantity'] as num?)?.toInt() ?? 0;
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[2] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final Map<String, dynamic> sale = doc.data();
      final String? productId = sale['productId']?.toString();
      final Map<String, dynamic>? product = productById[productId];
      if (!isCartonSaleRow(productId: productId, product: product)) {
        continue;
      }
      if (sale['isDebt'] == true) {
        if (sale['repaidAt'] == null) {
          debtQty += (sale['quantity'] as num?)?.toInt() ?? 0;
          debtAmount += _num(sale['totalAmount']);
        }
        continue;
      }
      if (isVehicleDebtRepaymentSale(sale)) {
        continue;
      }
      final DateTime? created = timestampToDate(sale['createdAt']);
      if (!isInRange(created, start, end)) {
        continue;
      }
      monthlyAmount += _num(sale['totalAmount']);
      final int qty = (sale['quantity'] as num?)?.toInt() ?? 0;
      if (sale['saleDestination']?.toString() == 'store') {
        storeQty += qty;
      } else {
        homeQty += qty;
      }
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[3] as QuerySnapshot<Map<String, dynamic>>).docs) {
      if (doc.data()['repaidAt'] != null) {
        continue;
      }
      final Map<String, dynamic> e = doc.data();
      final String? productId = e['productId']?.toString();
      final Map<String, dynamic>? product = productById[productId];
      if (!isCartonSaleRow(productId: productId, product: product)) {
        continue;
      }
      debtQty += (e['quantity'] as num?)?.toInt() ?? 0;
      debtAmount += _num(e['totalAmount']);
    }

    double cartonExpenses = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in (snaps[4] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final Map<String, dynamic> e = doc.data();
      if (e['driverId'] != null || e['vehicleId'] != null) {
        continue;
      }
      final DateTime? created = timestampToDate(e['createdAt']);
      if (!isInRange(created, start, end)) {
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
      'monthlyCartonSalesTotalQty': homeQty + storeQty,
      'monthlyCartonSalesHomeQty': homeQty,
      'monthlyCartonSalesStoreQty': storeQty,
      'cartonDebtUnpaidQuantity': debtQty,
      'cartonDebtUnpaidTotalAmount': debtAmount,
    };
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
    return _superAdminCartonMetricsForRange(start: range.start, end: range.end);
  }

  Future<Map<String, dynamic>> getDashboardAdmin() async {
    await _requireStaff();
    if (_adminDashboardCache != null &&
        _adminDashboardCachedAt != null &&
        DateTime.now().difference(_adminDashboardCachedAt!) < _dashboardCacheTtl) {
      return _adminDashboardCache!;
    }
    final DateTime now = DateTime.now();
    final ({DateTime start, DateTime end}) day = businessDayRange(now);
    final ({DateTime start, DateTime end}) month = businessMonthRange(now);
    final List<Object> core = await Future.wait<Object>(<Future<Object>>[
      _db.collection(FirestorePaths.products).where('isActive', isEqualTo: true).get(),
      _db.collection(FirestorePaths.vehicleLoads).get(),
      _db
          .collection(FirestorePaths.users)
          .where('role', isEqualTo: 'driver')
          .where('isActive', isEqualTo: true)
          .get(),
      _sumSales(FirestorePaths.stationSales, day.start, day.end),
      _sumVehicleCashSales(day.start, day.end),
      _sumSales(FirestorePaths.stationSales, month.start, month.end),
      _sumVehicleCashSales(month.start, month.end),
    ]);
    final QuerySnapshot<Map<String, dynamic>> products =
        core[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> allLoads =
        core[1] as QuerySnapshot<Map<String, dynamic>>;
    final int activeDrivers =
        (core[2] as QuerySnapshot<Map<String, dynamic>>).docs.length;
    final double stationToday = core[3] as double;
    final double vehicleToday = core[4] as double;
    final double monthlyStation = core[5] as double;
    final double monthlyVehicle = core[6] as double;

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> todayLoadDocs =
        <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var returnedToday = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in allLoads.docs) {
      final Map<String, dynamic> data = doc.data();
      final DateTime? loadDate = timestampToDate(data['loadDate']);
      if (isInRange(loadDate, day.start, day.end)) {
        todayLoadDocs.add(doc);
      }
      final DateTime? updated = timestampToDate(data['updatedAt']);
      if (isInRange(updated, day.start, day.end)) {
        returnedToday += (data['quantityReturned'] as num?)?.toInt() ?? 0;
      }
    }
    final List<Map<String, dynamic>> loadsForDay =
        await _mapVehicleLoadsBatch(todayLoadDocs);
    final Map<String, dynamic> stock = _stockSnapshotFromProductsAndLoads(
      products: products.docs,
      openLoads: allLoads.docs.where(
        (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            doc.data()['status']?.toString() != 'closed',
      ),
    );
    final List<Map<String, dynamic>> lowStock = products.docs
        .map(mapProductDoc)
        .where((Map<String, dynamic> p) => ((p['stationStock'] as num?)?.toInt() ?? 0) < 50)
        .take(10)
        .toList(growable: false);
    final Map<String, dynamic> result = <String, dynamic>{
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
    _adminDashboardCache = result;
    _adminDashboardCachedAt = DateTime.now();
    return result;
  }

  Future<Map<String, dynamic>> getDashboardDriver() async {
    final Map<String, dynamic> actor = await _auth.currentActor();
    if (actor['role'] != 'driver') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    final String actorId = actor['id']!.toString();
    if (_driverDashboardCache != null &&
        _driverDashboardCacheUserId == actorId &&
        _driverDashboardCachedAt != null &&
        DateTime.now().difference(_driverDashboardCachedAt!) < _dashboardCacheTtl) {
      return _driverDashboardCache!;
    }
    final DateTime now = DateTime.now();
    final ({DateTime start, DateTime end}) day = businessDayRange(now);
    final QuerySnapshot<Map<String, dynamic>> vehicles = await _db
        .collection(FirestorePaths.vehicles)
        .where('driverId', isEqualTo: actorId)
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
    final List<Object> driverData = await Future.wait<Object>(<Future<Object>>[
      _db
          .collection(FirestorePaths.vehicleLoads)
          .where('vehicleId', isEqualTo: vehicle['id'])
          .where('driverId', isEqualTo: actorId)
          .get(),
      _db.collection(FirestorePaths.vehicleSales).where('driverId', isEqualTo: actorId).get(),
      _db.collection(FirestorePaths.expenses).where('driverId', isEqualTo: actorId).get(),
    ]);
    final QuerySnapshot<Map<String, dynamic>> loads =
        driverData[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> sales =
        driverData[1] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> expenses =
        driverData[2] as QuerySnapshot<Map<String, dynamic>>;

    final List<Map<String, dynamic>> hydratedLoads =
        await _mapVehicleLoadsBatch(loads.docs);
    final List<Map<String, dynamic>> loadsToday = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> remainingQuantities = <Map<String, dynamic>>[];
    var returnedToday = 0;
    for (final Map<String, dynamic> load in hydratedLoads) {
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
    var soldQty = 0;
    var salesAmount = 0.0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in sales.docs) {
      final DateTime? created = timestampToDate(doc.data()['createdAt']);
      if (!isInRange(created, day.start, day.end)) {
        continue;
      }
      soldQty += (doc.data()['quantity'] as num?)?.toInt() ?? 0;
      salesAmount += _num(doc.data()['totalAmount']);
    }
    var totalExpensesToday = 0.0;
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
    final Map<String, dynamic> result = <String, dynamic>{
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
    _driverDashboardCache = result;
    _driverDashboardCachedAt = DateTime.now();
    _driverDashboardCacheUserId = actorId;
    return result;
  }

  Future<Map<String, dynamic>> _hydrateStationSale(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Map<String, dynamic>? product = await _productById(data['productId'] as String?);
    final Map<String, dynamic>? soldBy = await _userBrief(data['soldById'] as String?);
    return mapStationSaleDoc(doc, product: product, soldBy: soldBy);
  }

  Future<Map<String, dynamic>> _hydrateVehicleSale(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final List<Map<String, dynamic>> rows =
        await _mapVehicleSalesBatch(<DocumentSnapshot<Map<String, dynamic>>>[doc]);
    return rows.first;
  }

  Future<Map<String, dynamic>> _hydrateVehicleLoad(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final List<Map<String, dynamic>> rows =
        await _mapVehicleLoadsBatch(<DocumentSnapshot<Map<String, dynamic>>>[doc]);
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> _mapVehicleLoadsBatch(
    Iterable<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final List<DocumentSnapshot<Map<String, dynamic>>> list =
        docs.toList(growable: false);
    if (list.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final List<Object> lookups = await Future.wait<Object>(<Future<Object>>[
      _loadProductsLookup(),
      _loadVehiclesLookup(),
      _loadUserBriefsLookup(
        list.expand(
          (DocumentSnapshot<Map<String, dynamic>> doc) => <String>[
            doc.data()?['driverId']?.toString() ?? '',
            doc.data()?['createdById']?.toString() ?? '',
          ],
        ),
      ),
    ]);
    final Map<String, Map<String, dynamic>> productsById =
        lookups[0] as Map<String, Map<String, dynamic>>;
    final Map<String, Map<String, dynamic>> vehiclesById =
        lookups[1] as Map<String, Map<String, dynamic>>;
    final Map<String, Map<String, dynamic>> usersById =
        lookups[2] as Map<String, Map<String, dynamic>>;
    return list
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
          final String productId = data['productId']?.toString() ?? '';
          final String vehicleId = data['vehicleId']?.toString() ?? '';
          final String driverId = data['driverId']?.toString() ?? '';
          final String createdById = data['createdById']?.toString() ?? '';
          return mapVehicleLoadDoc(
            doc,
            vehicle: vehiclesById[vehicleId],
            driver: usersById[driverId],
            product: productsById[productId],
            createdBy: usersById[createdById],
          );
        })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _mapVehicleSalesBatch(
    Iterable<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final List<DocumentSnapshot<Map<String, dynamic>>> list =
        docs.toList(growable: false);
    if (list.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final List<Object> lookups = await Future.wait<Object>(<Future<Object>>[
      _loadProductsLookup(),
      _loadVehiclesLookup(),
      _loadUserBriefsLookup(
        list.map(
          (DocumentSnapshot<Map<String, dynamic>> doc) =>
              doc.data()?['driverId']?.toString() ?? '',
        ),
      ),
    ]);
    final Map<String, Map<String, dynamic>> productsById =
        lookups[0] as Map<String, Map<String, dynamic>>;
    final Map<String, Map<String, dynamic>> vehiclesById =
        lookups[1] as Map<String, Map<String, dynamic>>;
    final Map<String, Map<String, dynamic>> usersById =
        lookups[2] as Map<String, Map<String, dynamic>>;
    return list
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
          return mapVehicleSaleDoc(
            doc,
            product: productsById[data['productId']?.toString() ?? ''],
            vehicle: vehiclesById[data['vehicleId']?.toString() ?? ''],
            driver: usersById[data['driverId']?.toString() ?? ''],
          );
        })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _mapStationDebtsBatch(
    Iterable<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final List<DocumentSnapshot<Map<String, dynamic>>> list =
        docs.toList(growable: false);
    if (list.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final List<Object> lookups = await Future.wait<Object>(<Future<Object>>[
      _loadProductsLookup(),
      _loadUserBriefsLookup(
        list.map(
          (DocumentSnapshot<Map<String, dynamic>> doc) =>
              doc.data()?['recordedById']?.toString() ?? '',
        ),
      ),
    ]);
    final Map<String, Map<String, dynamic>> productsById =
        lookups[0] as Map<String, Map<String, dynamic>>;
    final Map<String, Map<String, dynamic>> usersById =
        lookups[1] as Map<String, Map<String, dynamic>>;
    return list
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
          return mapStationDebtDoc(
            doc,
            product: productsById[data['productId']?.toString() ?? ''],
            recordedBy: usersById[data['recordedById']?.toString() ?? ''],
          );
        })
        .toList(growable: false);
  }

  Future<Map<String, Map<String, dynamic>>> _loadProductsLookup() async {
    if (_allProductsLookupCache != null &&
        _catalogCacheFresh(_allProductsLookupCachedAt)) {
      return _allProductsLookupCache!;
    }
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestorePaths.products).get();
    final Map<String, Map<String, dynamic>> lookup = <String, Map<String, dynamic>>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs)
        doc.id: mapProductDoc(doc),
    };
    _allProductsLookupCache = lookup;
    _allProductsLookupCachedAt = DateTime.now();
    return lookup;
  }

  Future<Map<String, Map<String, dynamic>>> _loadVehiclesLookup() async {
    if (_vehiclesLookupCache != null && _catalogCacheFresh(_vehiclesLookupCachedAt)) {
      return _vehiclesLookupCache!;
    }
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestorePaths.vehicles).get();
    final Map<String, Map<String, dynamic>> lookup = <String, Map<String, dynamic>>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs)
        doc.id: mapVehicleDoc(doc),
    };
    _vehiclesLookupCache = lookup;
    _vehiclesLookupCachedAt = DateTime.now();
    return lookup;
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
    if (id == null || id.isEmpty) {
      return null;
    }
    final Map<String, Map<String, dynamic>> lookup = await _loadProductsLookup();
    return lookup[id];
  }

  Future<void> _attachDriversToVehicles(
    List<Map<String, dynamic>> vehicles,
  ) async {
    if (vehicles.isEmpty) {
      return;
    }
    final Map<String, Map<String, dynamic>> briefs = await _loadUserBriefsLookup(
      vehicles.map((Map<String, dynamic> v) => v['driverId']?.toString() ?? ''),
    );
    for (final Map<String, dynamic> vehicle in vehicles) {
      final String? driverId = vehicle['driverId']?.toString();
      if (driverId == null || driverId.isEmpty) {
        continue;
      }
      final Map<String, dynamic>? brief = briefs[driverId];
      if (brief != null) {
        vehicle['driver'] = brief;
      }
    }
  }

  Future<Map<String, dynamic>?> _userBrief(String? id) async {
    if (id == null || id.isEmpty) {
      return null;
    }
    final Map<String, dynamic>? cached = _userBriefMemCache[id];
    if (cached != null) {
      return cached;
    }
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestorePaths.users).doc(id).get();
    if (!doc.exists) {
      return null;
    }
    final Map<String, dynamic> u = mapUserDoc(doc);
    final Map<String, dynamic> brief = <String, dynamic>{
      'id': u['id'],
      'fullName': u['fullName'],
      if (u['phone'] != null) 'phone': u['phone'],
    };
    _userBriefMemCache[id] = brief;
    return brief;
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

  Future<double> _sumVehicleCashSales(DateTime start, DateTime end) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.vehicleSales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    double total = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Map<String, dynamic> data = doc.data();
      if (!isCashVehicleSaleRow(data)) {
        continue;
      }
      total += _num(data['totalAmount']);
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

  List<Map<String, dynamic>> _openDebtPreviewRowsFromStationSnap(
    QuerySnapshot<Map<String, dynamic>> snap, {
    required Map<String, Map<String, dynamic>> productById,
  }) {
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Map<String, dynamic> e = doc.data();
      final String debtor = normalizeDebtorName(e['debtorName']?.toString());
      final String? productId = e['productId']?.toString();
      if (debtor.isEmpty || productId == null || productId.isEmpty) {
        continue;
      }
      rows.add(<String, dynamic>{
        'debtorName': debtor,
        'productId': productId,
        'quantity': (e['quantity'] as num?)?.toInt() ?? 0,
        'recordingSource': 'station',
        'product': productById[productId],
      });
    }
    return rows;
  }

  List<Map<String, dynamic>> _openDebtPreviewRowsFromVehicleDebtSnap(
    QuerySnapshot<Map<String, dynamic>> snap, {
    required Map<String, Map<String, dynamic>> productById,
  }) {
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Map<String, dynamic> e = doc.data();
      if (!isOpenVehicleDebtSale(e)) {
        continue;
      }
      final String debtor = normalizeDebtorName(e['debtorName']?.toString());
      final String? productId = e['productId']?.toString();
      if (debtor.isEmpty || productId == null || productId.isEmpty) {
        continue;
      }
      rows.add(<String, dynamic>{
        'debtorName': debtor,
        'productId': productId,
        'quantity': (e['quantity'] as num?)?.toInt() ?? 0,
        'recordingSource': 'vehicle',
        'saleDestination': e['saleDestination']?.toString() ?? 'home',
        'vehicleSaleId': doc.id,
        'product': productById[productId],
      });
    }
    return rows;
  }

  String _debtPreviewLineKey(Map<String, dynamic> entry) {
    final String productId = entry['productId']?.toString() ?? '';
    if (isVehicleDebtEntry(entry)) {
      final String dest = entry['saleDestination']?.toString() ?? 'home';
      return '$productId:$dest';
    }
    return productId;
  }

  List<Map<String, dynamic>> _debtOpenPreviewFromEntries({
    required List<Map<String, dynamic>> entries,
    required Map<String, Map<String, dynamic>> productById,
  }) {
    final Map<String, Map<String, Map<String, dynamic>>> byDebtor =
        <String, Map<String, Map<String, dynamic>>>{};
    for (final Map<String, dynamic> e in entries) {
      final String dname = normalizeDebtorName(e['debtorName']?.toString());
      if (dname.isEmpty) {
        continue;
      }
      byDebtor.putIfAbsent(dname, () => <String, Map<String, dynamic>>{});
      final String lineKey = _debtPreviewLineKey(e);
      if (lineKey.isEmpty) {
        continue;
      }
      final Map<String, dynamic>? product =
          e['product'] as Map<String, dynamic>? ??
              productById[e['productId']?.toString() ?? ''];
      final Map<String, Map<String, dynamic>> prodMap = byDebtor[dname]!;
      final Map<String, dynamic>? prev = prodMap[lineKey];
      final int qty = (e['quantity'] as num?)?.toInt() ?? 0;
      final String rawName = product?['name']?.toString() ?? '';
      prodMap[lineKey] = <String, dynamic>{
        'productName': rawName,
        'quantity': ((prev?['quantity'] as num?)?.toInt() ?? 0) + qty,
        'kind': isVehicleDebtEntry(e) ? 'vehicle' : 'station',
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

final class _StationSaleBatchLine {
  const _StationSaleBatchLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.fillingLineSlot,
    this.note,
  });

  final String productId;
  final int quantity;
  final double unitPrice;
  final int? fillingLineSlot;
  final String? note;
}

final class _VehicleSaleBatchLine {
  const _VehicleSaleBatchLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.stockProductId,
    this.debtorName,
    this.isDebt = false,
    this.skipLoadDeduction = false,
    this.deductStationStock = false,
  });

  final String productId;
  final int quantity;
  final double unitPrice;
  final String? stockProductId;
  final String? debtorName;
  final bool isDebt;
  final bool skipLoadDeduction;
  final bool deductStationStock;
}

final class _MutableVehicleLoadRow {
  _MutableVehicleLoadRow({
    required this.ref,
    required this.loaded,
    required this.returned,
    required int quantitySold,
  })  : initialSold = quantitySold,
        sold = quantitySold;

  final DocumentReference<Map<String, dynamic>> ref;
  final int loaded;
  final int returned;
  final int initialSold;
  int sold;

  int get available => loaded - sold - returned;
}

final class _VehicleLoadAllocationRow {
  const _VehicleLoadAllocationRow({
    required this.row,
    required this.productId,
    required this.productName,
  });

  final _MutableVehicleLoadRow row;
  final String productId;
  final String productName;
}
