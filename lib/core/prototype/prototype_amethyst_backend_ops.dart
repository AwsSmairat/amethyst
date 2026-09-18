part of 'prototype_amethyst_backend.dart';

mixin _PrototypeBackendOps on _PrototypeAmethystBackendBase {
  Future<Map<String, dynamic>> listExpenses({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    List<Map<String, dynamic>> items = PrototypeSampleData.instance.expenses;
    if (dateFrom != null || dateTo != null) {
      items = items
          .where(
            (Map<String, dynamic> e) => apiDateMatchesRange(
              createdAt: e['createdAt'],
              dateFrom: dateFrom,
              dateTo: dateTo,
            ),
          )
          .toList(growable: false);
    }
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createExpense({
    String? vehicleId,
    required double amount,
    String? note,
    Uint8List? receiptBytes,
    String? receiptFilename,
  }) async {
    final Map<String, dynamic> row = PrototypeSampleData.instance.addExpense(
      vehicleId: vehicleId,
      amount: amount,
      note: note,
      receiptFilename: receiptFilename,
      hasReceipt: receiptBytes != null && receiptBytes.isNotEmpty,
    );
    return <String, dynamic>{'item': row};
  }

  Future<void> deleteExpense(String id) async {
    if (!PrototypeSampleData.instance.deleteExpense(id)) {
      throw ApiException('Expense not found', code: 'NOT_FOUND');
    }
  }

  Future<Map<String, dynamic>> listReturns({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.instance.returns, page: page, limit: limit);

  Future<Map<String, dynamic>> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) async {
    try {
      final Map<String, dynamic> row = PrototypeSampleData.instance.addReturn(
        vehicleLoadId: vehicleLoadId,
        quantityReturned: quantityReturned,
      );
      return <String, dynamic>{'item': row};
    } on StateError catch (e) {
      switch (e.message) {
        case 'LOAD_NOT_FOUND':
          throw ApiException('Vehicle load not found', code: 'NOT_FOUND');
        case 'LOAD_CLOSED':
          throw ApiException('Load is closed', code: 'LOAD_CLOSED');
        case 'FORBIDDEN':
          throw ApiException('Forbidden', code: 'FORBIDDEN');
        case 'INSUFFICIENT_REMAINING':
          throw ApiException(
            'Returned quantity exceeds remaining on load',
            code: 'INSUFFICIENT_STOCK',
          );
        case 'INVALID_QUANTITY':
          throw ApiException('Invalid quantity', code: 'VALIDATION');
        default:
          rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> reportsInventory() async =>
      PrototypeSampleData.instance.reportsInventory();

  Future<Map<String, dynamic>> reportsSalesWorkingDays() async =>
      PrototypeSampleData.instance.reportsSalesWorkingDays();

  Future<Map<String, dynamic>> reportsProfitLoss({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async =>
      PrototypeSampleData.instance.reportsProfitLoss(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<Map<String, dynamic>> reportsProfitLossMonthly() async =>
      PrototypeSampleData.instance.reportsProfitLossMonthly();

  Future<Map<String, dynamic>> reportsSalesMonthly({
    int? year,
    int? month,
  }) async =>
      PrototypeSampleData.instance.reportsSalesMonthly(year: year, month: month);

  Future<Map<String, dynamic>> getDashboardSuperAdmin() async =>
      PrototypeSampleData.instance.getDashboardSuperAdmin();

  Future<Map<String, dynamic>> getSuperAdminCartonSummary({
    int? year,
    int? month,
  }) async =>
      PrototypeSampleData.instance.getSuperAdminCartonSummary(year: year, month: month);

  Future<Map<String, dynamic>> getDashboardAdmin() async =>
      PrototypeSampleData.instance.getDashboardAdmin();

  Future<Map<String, dynamic>> getDashboardDriver() async {
    final UserEntity? user = PrototypeSession.current;
    if (user?.role != 'driver') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    return PrototypeSampleData.instance.getDashboardDriver();
  }

  Future<List<Map<String, dynamic>>> listStaffNoteRecipients() async {
    if (!PrototypeSession.isSignedIn) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    return PrototypeSampleData.instance.staffNoteRecipientOptions();
  }

  Future<List<Map<String, dynamic>>> createStaffNotes({
    required String message,
    required String recipientKind,
    String? driverUserId,
  }) async {
    if (!PrototypeSession.isSignedIn) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    final String? senderId = PrototypeSession.current?.id;
    if (senderId == null || senderId.isEmpty) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    try {
      return PrototypeSampleData.instance.createStaffNotes(
        senderUserId: senderId,
        message: message,
        recipientKind: recipientKind,
        driverUserId: driverUserId,
      );
    } on StateError catch (e) {
      final String code = switch (e.message) {
        'EMPTY_MESSAGE' => 'EMPTY_MESSAGE',
        'MISSING_DRIVER' => 'MISSING_DRIVER',
        'NO_RECIPIENTS' => 'NO_RECIPIENTS',
        _ => 'INVALID',
      };
      throw ApiException('Invalid staff note', code: code);
    }
  }

  Future<Map<String, dynamic>?> getPendingStaffNoteForMe() async {
    if (!PrototypeSession.isSignedIn) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    final String? userId = PrototypeSession.current?.id;
    if (userId == null) {
      return null;
    }
    return PrototypeSampleData.instance.firstUnreadStaffNoteForUser(userId);
  }

  Stream<Map<String, dynamic>?> watchPendingStaffNoteForMe() async* {
    while (PrototypeSession.isSignedIn) {
      yield await getPendingStaffNoteForMe();
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    yield null;
  }

  Future<void> markStaffNoteRead(String noteId) async {
    if (!PrototypeSession.isSignedIn) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    final String? userId = PrototypeSession.current?.id;
    if (userId == null) {
      return;
    }
    PrototypeSampleData.instance.markStaffNoteRead(noteId: noteId, userId: userId);
  }

  Future<Map<String, dynamic>> getStationCashBalance() async {
    await PrototypeSampleData.instance.ensureLoaded();
    final List<Map<String, dynamic>> entries =
        PrototypeSampleData.instance.stationCashEntries;
    final double yesterday = entries.isEmpty
        ? 0.0
        : (entries.first['previousAmount'] as num?)?.toDouble() ?? 0.0;
    return <String, dynamic>{
      'amount': PrototypeSampleData.instance.stationCashAmount,
      'yesterdayAmount': yesterday,
    };
  }

  Future<Map<String, dynamic>> listStationCashEntries({
    int page = 1,
    int limit = 50,
  }) async {
    await PrototypeSampleData.instance.ensureLoaded();
    return _paginate(
      PrototypeSampleData.instance.stationCashEntries,
      page: page,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> setStationCashBalance({
    required double amount,
    String? note,
  }) async {
    await PrototypeSampleData.instance.ensureLoaded();
    if (amount < 0) {
      throw ApiException('Amount cannot be negative', code: 'INVALID_AMOUNT');
    }
    PrototypeSampleData.instance.setStationCashAmount(amount: amount, note: note);
    return <String, dynamic>{'amount': amount};
  }

  Future<Map<String, dynamic>> getDriverCashBalance() async {
    await PrototypeSampleData.instance.ensureLoaded();
    final String driverId = _requirePrototypeDriverId();
    final List<Map<String, dynamic>> entries =
        PrototypeSampleData.instance.driverCashEntriesFor(driverId);
    final double yesterday = entries.isEmpty
        ? 0.0
        : (entries.first['previousAmount'] as num?)?.toDouble() ?? 0.0;
    return <String, dynamic>{
      'amount': PrototypeSampleData.instance.driverCashAmountFor(driverId),
      'yesterdayAmount': yesterday,
      'driverId': driverId,
    };
  }

  Future<Map<String, dynamic>> listDriverCashEntries({
    int page = 1,
    int limit = 50,
  }) async {
    await PrototypeSampleData.instance.ensureLoaded();
    final String driverId = _requirePrototypeDriverId();
    return _paginate(
      PrototypeSampleData.instance.driverCashEntriesFor(driverId),
      page: page,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> setDriverCashBalance({
    required double amount,
    String? note,
  }) async {
    await PrototypeSampleData.instance.ensureLoaded();
    if (amount < 0) {
      throw ApiException('Amount cannot be negative', code: 'INVALID_AMOUNT');
    }
    final String driverId = _requirePrototypeDriverId();
    PrototypeSampleData.instance.setDriverCashAmount(
      driverId: driverId,
      amount: amount,
      note: note,
    );
    return <String, dynamic>{'amount': amount, 'driverId': driverId};
  }
}
