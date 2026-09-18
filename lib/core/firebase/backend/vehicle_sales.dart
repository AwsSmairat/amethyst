part of '../amethyst_firebase_backend.dart';

mixin _FirebaseVehicleSalesOps on _FirebaseCatalogOps {
  Future<List<Map<String, dynamic>>> _loadHydratedVehicleSalesList(
    Map<String, dynamic> actor,
  ) async {
    final String scopeKey =
        actor['role'] == 'driver' ? 'driver:${actor['id']}' : 'staff';
    if (_hydratedVehicleSalesCache != null &&
        _hydratedVehicleSalesScopeKey == scopeKey &&
        _catalogCacheFresh(_hydratedVehicleSalesCachedAt)) {
      return _hydratedVehicleSalesCache!;
    }
    if (_hydratedVehicleSalesInFlight != null &&
        _hydratedVehicleSalesInFlightKey == scopeKey) {
      return _hydratedVehicleSalesInFlight!;
    }
    _hydratedVehicleSalesInFlightKey = scopeKey;
    _hydratedVehicleSalesInFlight = () async {
      try {
        Query<Map<String, dynamic>> q =
            _db.collection(FirestorePaths.vehicleSales);
        if (actor['role'] == 'driver') {
          q = q.where('driverId', isEqualTo: actor['id']);
        }
        final QuerySnapshot<Map<String, dynamic>> snap =
            await q.orderBy('createdAt', descending: true).get();
        final List<Map<String, dynamic>> items =
            await _mapVehicleSalesBatch(snap.docs);
        _hydratedVehicleSalesCache = items;
        _hydratedVehicleSalesCachedAt = DateTime.now();
        _hydratedVehicleSalesScopeKey = scopeKey;
        return items;
      } finally {
        _hydratedVehicleSalesInFlight = null;
        _hydratedVehicleSalesInFlightKey = null;
      }
    }();
    return _hydratedVehicleSalesInFlight!;
  }

  Future<List<Map<String, dynamic>>> _queryVehicleSalesFiltered({
    required Map<String, dynamic> actor,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final String scopeKey =
        actor['role'] == 'driver' ? 'driver:${actor['id']}' : 'staff';
    final String cacheKey =
        '$scopeKey|${vehicleId ?? ''}|${driverId ?? ''}|${dateFrom ?? ''}|${dateTo ?? ''}';
    final List<Map<String, dynamic>>? cached = _vehicleSalesQueryCache[cacheKey];
    final DateTime? cachedAt = _vehicleSalesQueryCachedAt[cacheKey];
    if (cached != null && _catalogCacheFresh(cachedAt)) {
      return cached;
    }
    final Future<List<Map<String, dynamic>>>? inFlight =
        _vehicleSalesQueryInFlight[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }
    final Future<List<Map<String, dynamic>>> future = () async {
      try {
        Query<Map<String, dynamic>> q =
            _db.collection(FirestorePaths.vehicleSales);
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
        _vehicleSalesQueryCache[cacheKey] = items;
        _vehicleSalesQueryCachedAt[cacheKey] = DateTime.now();
        return items;
      } finally {
        _vehicleSalesQueryInFlight.remove(cacheKey);
      }
    }();
    _vehicleSalesQueryInFlight[cacheKey] = future;
    return future;
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
    final bool hasNarrowFilter =
        (vehicleId != null && vehicleId.isNotEmpty) ||
            (driverId != null &&
                driverId.isNotEmpty &&
                actor['role'] != 'driver') ||
            (dateFrom != null && dateFrom.isNotEmpty) ||
            (dateTo != null && dateTo.isNotEmpty);
    final List<Map<String, dynamic>> items = hasNarrowFilter
        ? await _queryVehicleSalesFiltered(
            actor: actor,
            vehicleId: vehicleId,
            driverId: driverId,
            dateFrom: dateFrom,
            dateTo: dateTo,
          )
        : await _loadHydratedVehicleSalesList(actor);
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
}
