part of '../amethyst_firebase_backend.dart';

mixin _FirebaseStationSalesOps on _FirebaseCatalogOps {
  Future<List<Map<String, dynamic>>> _mapStationSalesBatch(
    Iterable<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final List<DocumentSnapshot<Map<String, dynamic>>> list =
        docs.toList(growable: false);
    if (list.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final List<Object> lookups = await Future.wait(<Future<Object>>[
      _loadProductsLookup(),
      _loadUserBriefsLookup(
        list.map(
          (DocumentSnapshot<Map<String, dynamic>> d) =>
              d.data()?['soldById']?.toString() ?? '',
        ),
      ),
    ]);
    final Map<String, Map<String, dynamic>> productsById =
        lookups[0] as Map<String, Map<String, dynamic>>;
    final Map<String, Map<String, dynamic>> usersById =
        lookups[1] as Map<String, Map<String, dynamic>>;
    return list
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data =
              doc.data() ?? <String, dynamic>{};
          return mapStationSaleDoc(
            doc,
            product: productsById[data['productId']?.toString() ?? ''],
            soldBy: usersById[data['soldById']?.toString() ?? ''],
          );
        })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _loadHydratedStationSalesList() async {
    if (_hydratedStationSalesCache != null &&
        _catalogCacheFresh(_hydratedStationSalesCachedAt)) {
      return _hydratedStationSalesCache!;
    }
    if (_hydratedStationSalesInFlight != null) {
      return _hydratedStationSalesInFlight!;
    }
    _hydratedStationSalesInFlight = () async {
      try {
        final QuerySnapshot<Map<String, dynamic>> snap = await _db
            .collection(FirestorePaths.stationSales)
            .orderBy('createdAt', descending: true)
            .get();
        final List<Map<String, dynamic>> items =
            await _mapStationSalesBatch(snap.docs);
        _hydratedStationSalesCache = items;
        _hydratedStationSalesCachedAt = DateTime.now();
        return items;
      } finally {
        _hydratedStationSalesInFlight = null;
      }
    }();
    return _hydratedStationSalesInFlight!;
  }

  Future<Map<String, dynamic>> listStationSales({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    await _requireStaff();
    final DateTime? from = parseYmd(dateFrom);
    final DateTime? to = parseYmd(dateTo);
    if (from != null || to != null) {
      final List<Map<String, dynamic>> items = await _cachedRangeList(
        'stationSales|${dateFrom ?? ''}|${dateTo ?? ''}',
        () async {
          Query<Map<String, dynamic>> q =
              _db.collection(FirestorePaths.stationSales);
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
          return _mapStationSalesBatch(snap.docs);
        },
      );
      return _paginate(items, page: page, limit: limit);
    }
    final List<Map<String, dynamic>> all = await _loadHydratedStationSalesList();
    return _paginate(all, page: page, limit: limit);
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
}
