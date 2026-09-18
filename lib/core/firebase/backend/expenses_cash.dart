part of '../amethyst_firebase_backend.dart';

mixin _FirebaseExpensesCashOps on _FirebaseBackendHelpers {
  Future<List<Map<String, dynamic>>> _loadHydratedExpensesList() async {
    if (_hydratedExpensesCache != null &&
        _catalogCacheFresh(_hydratedExpensesCachedAt)) {
      return _hydratedExpensesCache!;
    }
    if (_hydratedExpensesInFlight != null) {
      return _hydratedExpensesInFlight!;
    }
    _hydratedExpensesInFlight = () async {
      try {
        final QuerySnapshot<Map<String, dynamic>> snap = await _db
            .collection(FirestorePaths.expenses)
            .orderBy('createdAt', descending: true)
            .get();
        final List<Map<String, dynamic>> items = snap.docs
            .map(mapExpenseDoc)
            .toList(growable: false);
        _hydratedExpensesCache = items;
        _hydratedExpensesCachedAt = DateTime.now();
        return items;
      } finally {
        _hydratedExpensesInFlight = null;
      }
    }();
    return _hydratedExpensesInFlight!;
  }

  Future<Map<String, dynamic>> listExpenses({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    await _requireStaffOrDriver();
    final DateTime? from = parseYmd(dateFrom);
    final DateTime? to = parseYmd(dateTo);
    if (from != null || to != null) {
      final List<Map<String, dynamic>> items = await _cachedRangeList(
        'expenses|${dateFrom ?? ''}|${dateTo ?? ''}',
        () async {
          Query<Map<String, dynamic>> q =
              _db.collection(FirestorePaths.expenses);
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
          return snap.docs.map(mapExpenseDoc).toList(growable: false);
        },
      );
      return _paginate(items, page: page, limit: limit.clamp(1, 500));
    }
    final List<Map<String, dynamic>> all = await _loadHydratedExpensesList();
    return _paginate(all, page: page, limit: limit.clamp(1, 100));
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
    _clearListCaches();
    clearDashboardCache();
    return mapExpenseDoc(doc);
  }

  Future<void> deleteExpense(String id) async {
    await _requireSuperAdmin();
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestorePaths.expenses).doc(id);
    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
    if (!snap.exists) {
      throw ApiException('Expense not found', code: 'NOT_FOUND');
    }
    await ref.delete();
    _clearListCaches();
    clearDashboardCache();
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
    return <String, dynamic>{
      'amount': snapshot.today,
      'yesterdayAmount': snapshot.yesterday,
    };
  }

  Future<Map<String, dynamic>> listStationCashEntries({
    int page = 1,
    int limit = 50,
  }) async {
    await _requireStaff();
    final int safeLimit = limit.clamp(1, 100);
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.stationCashEntries)
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .get();
    final List<Map<String, dynamic>> items = snap.docs
        .map(mapStationCashEntryDoc)
        .toList(growable: false);
    return <String, dynamic>{
      'items': items,
      'total': items.length,
      'page': 1,
      'limit': safeLimit,
    };
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
    clearDashboardCache();
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
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    final double yesterday = entries.docs.isEmpty
        ? 0.0
        : (entries.docs.first.data()['previousAmount'] as num?)?.toDouble() ??
            0.0;
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
    return <String, dynamic>{
      'amount': snapshot.today,
      'yesterdayAmount': snapshot.yesterday,
      'driverId': driverId,
    };
  }

  Future<Map<String, dynamic>> listDriverCashEntries({
    int page = 1,
    int limit = 50,
  }) async {
    final String driverId = await _requireDriverActorId();
    final int safeLimit = limit.clamp(1, 100);
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.driverCashEntries)
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .get();
    final List<Map<String, dynamic>> items = snap.docs
        .map(mapDriverCashEntryDoc)
        .toList(growable: false);
    return <String, dynamic>{
      'items': items,
      'total': items.length,
      'page': 1,
      'limit': safeLimit,
    };
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
    clearDashboardCache();
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
  })> _driverCashProfitContext({DateTime? createdFrom}) async {
    Query<Map<String, dynamic>> entriesQuery =
        _db.collection(FirestorePaths.driverCashEntries);
    if (createdFrom != null) {
      entriesQuery = entriesQuery.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(createdFrom),
      );
    }
    final List<Object> snaps = await Future.wait<Object>(<Future<Object>>[
      _db.collection(FirestorePaths.driverCashBalance).get(),
      entriesQuery.get(),
    ]);
    final QuerySnapshot<Map<String, dynamic>> balanceSnap =
        snaps[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> entriesSnap =
        snaps[1] as QuerySnapshot<Map<String, dynamic>>;
    final Map<String, double> todayByDriverId = <String, double>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in balanceSnap.docs)
        doc.id: _num(doc.data()['amount']),
    };
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
      final WriteBatch batch = _db.batch();
      batch.update(loadSnap.reference, <String, dynamic>{
        'quantityReturned': FieldValue.increment(quantityReturned),
        'updatedAt': serverTimestamp(),
      });
      // التحميل لا يخصم مخزون المحطة؛ لذلك الإرجاع لا يزيده — وإلا ينتفخ
      // «مخزون كراتين» مع كل إرجاع سائق.
      final DocumentReference<Map<String, dynamic>> movRef =
          _db.collection(FirestorePaths.stockMovements).doc();
      batch.set(movRef, <String, dynamic>{
        'productId': productId,
        'type': 'transfer',
        'quantity': quantityReturned,
        'reason': 'vehicle_return',
        'referenceId': vehicleLoadId,
        'createdById': actor['id'],
        'createdAt': serverTimestamp(),
      });
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
}
