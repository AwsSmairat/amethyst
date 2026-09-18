part of '../amethyst_firebase_backend.dart';

mixin _FirebaseDebtOps on _FirebaseCatalogOps {
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

  Future<List<Map<String, dynamic>>> _loadOpenDebtList(
    Map<String, dynamic> actor,
  ) async {
    final String scopeKey =
        actor['role'] == 'driver' ? 'driver:${actor['id']}' : 'staff';
    if (_openDebtListCache != null &&
        _openDebtListScopeKey == scopeKey &&
        _catalogCacheFresh(_openDebtListCachedAt)) {
      return _openDebtListCache!;
    }
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
    _openDebtListCache = merged;
    _openDebtListCachedAt = DateTime.now();
    _openDebtListScopeKey = scopeKey;
    return merged;
  }

  Future<Map<String, dynamic>> listStationDebtEntries({
    int page = 1,
    int limit = 100,
  }) async {
    await _requireStaffOrDriver();
    final Map<String, dynamic> actor = await _auth.currentActor();
    final List<Map<String, dynamic>> merged = await _loadOpenDebtList(actor);
    return _paginate(merged, page: page, limit: limit);
  }

  Future<List<Map<String, dynamic>>> _loadStationDebtSummaryList() async {
    if (_stationDebtSummaryCache != null &&
        _catalogCacheFresh(_stationDebtSummaryCachedAt)) {
      return _stationDebtSummaryCache!;
    }
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.stationDebtEntries)
        .orderBy('createdAt', descending: true)
        .get();
    final List<Map<String, dynamic>> items =
        await _mapStationDebtsBatch(snap.docs);
    final List<Map<String, dynamic>> stationOnly = items
        .where(isStationDebtSummaryEntry)
        .toList(growable: false);
    _stationDebtSummaryCache = stationOnly;
    _stationDebtSummaryCachedAt = DateTime.now();
    return stationOnly;
  }

  /// كل سجلات دين المحطة (مفتوحة ومسدّدة) لملخص مبيعات المحطة اليومي.
  Future<Map<String, dynamic>> listStationDebtEntriesForSummary({
    int page = 1,
    int limit = 100,
  }) async {
    await _requireStaff();
    final List<Map<String, dynamic>> stationOnly =
        await _loadStationDebtSummaryList();
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
}
