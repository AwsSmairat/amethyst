part of '../amethyst_firebase_backend.dart';

ApiException _apiExceptionFromFirebase(FirebaseException e) {
  return ApiException(
    e.message ?? 'Firestore error',
    code: e.code.toUpperCase(),
  );
}

mixin _FirebaseBackendHelpers on _AmethystFirebaseBackendBase {
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
    final int safeLimit = limit.clamp(1, 500);
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
