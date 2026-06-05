import 'dart:async';
import 'dart:typed_data';

import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/prototype/prototype_sample_data.dart';
import 'package:amethyst/core/utils/parse_api_datetime.dart';
import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';

/// Prototype backend backed by local sample data and persistence.
final class PrototypeAmethystBackend {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await PrototypeSampleData.ensureLoaded();
    final UserEntity? user = PrototypeSampleData.authenticate(
      email: email,
      password: password,
    );
    if (user == null) {
      throw ApiException(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        code: 'INVALID_CREDENTIALS',
      );
    }
    await PrototypeSession.signIn(user);
    return PrototypeSampleData.meFromSession();
  }

  Future<Map<String, dynamic>> me() async {
    if (!PrototypeSession.isSignedIn) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    return PrototypeSampleData.meFromSession();
  }

  Future<Map<String, dynamic>> listProducts({int page = 1, int limit = 100}) async {
    PrototypeSampleData.ensurePricingCatalogProducts();
    return _paginate(PrototypeSampleData.products, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String unitType,
    required double price,
    int stationStock = 0,
  }) async {
    final String id = 'p_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> p = <String, dynamic>{
      'id': id,
      'name': name,
      'unitType': unitType,
      'type': unitType,
      'price': price,
      'stationStock': stationStock,
      'stock': stationStock,
      'isActive': true,
    };
    PrototypeSampleData.addProduct(p);
    return Map<String, dynamic>.from(p);
  }

  Future<void> patchProductStationStock({
    required String id,
    required int stationStock,
  }) async {
    if (!PrototypeSampleData.setStationStock(id, stationStock)) {
      throw ApiException('Product not found', code: 'NOT_FOUND');
    }
  }

  Future<void> deductStationStockForSale({
    required String productId,
    required int quantity,
  }) async {
    try {
      PrototypeSampleData.deductStationStockForSale(
        productId: productId,
        quantity: quantity,
      );
    } on StateError catch (e) {
      if (e.message == 'INSUFFICIENT_STOCK') {
        throw ApiException('Insufficient stock', code: 'INSUFFICIENT_STOCK');
      }
      rethrow;
    }
  }

  Future<void> upsertStationBalanceRowStock({
    required int rowIndex,
    required int stationStock,
  }) async {
    PrototypeSampleData.upsertStationBalanceRow(
      rowIndex: rowIndex,
      stationStock: stationStock,
    );
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    double? price,
  }) async {
    if (price != null && !PrototypeSampleData.setProductPrice(id, price)) {
      throw ApiException('Product not found', code: 'NOT_FOUND');
    }
    return PrototypeSampleData.productById(id);
  }

  Future<void> deleteProduct(String id) async {
    await PrototypeSampleData.ensureLoaded();
    if (!PrototypeSampleData.deleteProduct(id)) {
      throw ApiException('Product not found', code: 'NOT_FOUND');
    }
  }

  Future<Map<String, dynamic>> listVehicles({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.vehicles, page: page, limit: limit);

  Future<Map<String, dynamic>> createVehicle({
    required String vehicleNumber,
    String? driverId,
    String? notes,
  }) async {
    await PrototypeSampleData.ensureLoaded();
    final Map<String, dynamic> row = PrototypeSampleData.createVehicle(
      vehicleNumber: vehicleNumber,
      driverId: driverId,
      notes: notes,
    );
    return row;
  }

  Future<void> deleteVehicle(String id) async {
    await PrototypeSampleData.ensureLoaded();
    try {
      PrototypeSampleData.deleteVehicle(id);
    } on StateError catch (e) {
      switch (e.message) {
        case 'VEHICLE_HAS_OPEN_LOAD':
          throw ApiException(
            'Cannot delete vehicle with open load',
            code: 'VEHICLE_HAS_OPEN_LOAD',
          );
        case 'NOT_FOUND':
          throw ApiException('Vehicle not found', code: 'NOT_FOUND');
        default:
          rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> listUsers({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.users, page: page, limit: limit);

  Future<Map<String, dynamic>> listVehicleLoads({
    int page = 1,
    int limit = 100,
    String? status,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) async {
    List<Map<String, dynamic>> items = PrototypeSampleData.vehicleLoads;
    if (vehicleId != null && vehicleId.isNotEmpty) {
      items = items
          .where((Map<String, dynamic> l) => l['vehicleId'] == vehicleId)
          .toList(growable: false);
    }
    if (driverId != null && driverId.isNotEmpty) {
      items = items
          .where((Map<String, dynamic> l) => l['driverId'] == driverId)
          .toList(growable: false);
    }
    if (dateFrom != null || dateTo != null) {
      items = items
          .where(
            (Map<String, dynamic> l) => apiDateMatchesRange(
              createdAt: l['loadDate'] ?? l['createdAt'],
              dateFrom: dateFrom,
              dateTo: dateTo,
            ),
          )
          .toList(growable: false);
    }
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> driverCurrentLoad() async =>
      PrototypeSampleData.driverCurrentLoad();

  Future<String?> driverAssignedVehicleId() async =>
      PrototypeSampleData.vehicleIdForSessionDriver();

  Future<Map<String, dynamic>> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
    String? loadBatchId,
  }) async {
    final Map<String, dynamic> row = PrototypeSampleData.addVehicleLoad(
      vehicleId: vehicleId,
      driverId: driverId,
      productId: productId,
      quantityLoaded: quantityLoaded,
      loadDate: loadDate,
      loadBatchId: loadBatchId,
    );
    return <String, dynamic>{'item': row};
  }

  Future<Map<String, dynamic>> listStationSales({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.stationSales, page: page, limit: limit);

  Future<Map<String, dynamic>> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
  }) async {
    final bool skipStock = fillingSale &&
        fillingLineSlot != null &&
        kStationFillingSkipStockColumnIndices.contains(fillingLineSlot);
    try {
      final Map<String, dynamic> row = PrototypeSampleData.addStationSale(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        note: note,
        skipStockDeduction: skipStock,
      );
      return <String, dynamic>{'item': row};
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

  Future<void> createStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) async {
    PrototypeSampleData.addStationDebtEntries(
      debtorName: debtorName,
      lines: lines,
    );
  }

  Future<Map<String, dynamic>> listStationDebtEntries({
    int page = 1,
    int limit = 100,
  }) async =>
      _paginate(
        PrototypeSampleData.openStationDebtEntries,
        page: page,
        limit: limit,
      );

  Future<Map<String, dynamic>> repayStationDebt({required String debtorName}) async {
    final int n = PrototypeSampleData.repayStationDebtForDebtor(
      debtorName: debtorName,
    );
    if (n <= 0) {
      throw ApiException('No unpaid station debt', code: 'NOT_FOUND');
    }
    return <String, dynamic>{'repaidCount': n};
  }

  Future<Map<String, dynamic>> repayStationDebtFromVehicle({
    required String debtorName,
  }) async {
    final int n = PrototypeSampleData.repayVehicleDebtForDebtor(
      debtorName: debtorName,
    );
    if (n <= 0) {
      throw ApiException('No unpaid vehicle debt', code: 'NOT_FOUND');
    }
    return <String, dynamic>{'repaidCount': n};
  }

  Future<Map<String, dynamic>> listVehicleSales({
    int page = 1,
    int limit = 100,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) async {
    List<Map<String, dynamic>> items = PrototypeSampleData.vehicleSales;
    if (vehicleId != null && vehicleId.isNotEmpty) {
      items = items
          .where((Map<String, dynamic> s) => s['vehicleId'] == vehicleId)
          .toList(growable: false);
    }
    if (dateFrom != null || dateTo != null) {
      items = items
          .where(
            (Map<String, dynamic> s) => apiDateMatchesRange(
              createdAt: s['createdAt'],
              dateFrom: dateFrom,
              dateTo: dateTo,
            ),
          )
          .toList(growable: false);
    }
    return _paginate(items, page: page, limit: limit);
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
    final Map<String, dynamic> row = PrototypeSampleData.addVehicleSale(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      unitPrice: unitPrice,
      saleDestination: saleDestination,
      stockProductId: stockProductId,
      debtorName: debtorName,
      isDebt: isDebt,
      skipLoadDeduction: skipLoadDeduction,
    );
    return <String, dynamic>{'item': row};
  }

  Future<Map<String, dynamic>> listExpenses({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    List<Map<String, dynamic>> items = PrototypeSampleData.expenses;
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
    final Map<String, dynamic> row = PrototypeSampleData.addExpense(
      vehicleId: vehicleId,
      amount: amount,
      note: note,
      receiptFilename: receiptFilename,
      hasReceipt: receiptBytes != null && receiptBytes.isNotEmpty,
    );
    return <String, dynamic>{'item': row};
  }

  Future<Map<String, dynamic>> listReturns({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.returns, page: page, limit: limit);

  Future<Map<String, dynamic>> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) async {
    try {
      final Map<String, dynamic> row = PrototypeSampleData.addReturn(
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
      PrototypeSampleData.reportsInventory();

  Future<Map<String, dynamic>> reportsSalesWorkingDays() async =>
      PrototypeSampleData.reportsSalesWorkingDays();

  Future<Map<String, dynamic>> reportsProfitLoss({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async =>
      PrototypeSampleData.reportsProfitLoss();

  Future<Map<String, dynamic>> reportsSalesMonthly({
    int? year,
    int? month,
  }) async =>
      PrototypeSampleData.reportsSalesMonthly(year: year, month: month);

  Future<Map<String, dynamic>> getDashboardSuperAdmin() async =>
      PrototypeSampleData.getDashboardSuperAdmin();

  Future<Map<String, dynamic>> getSuperAdminCartonSummary({
    int? year,
    int? month,
  }) async =>
      PrototypeSampleData.getSuperAdminCartonSummary(year: year, month: month);

  Future<Map<String, dynamic>> getDashboardAdmin() async =>
      PrototypeSampleData.getDashboardAdmin();

  Future<Map<String, dynamic>> getDashboardDriver() async {
    final UserEntity? user = PrototypeSession.current;
    if (user?.role != 'driver') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    return PrototypeSampleData.getDashboardDriver();
  }

  Future<List<Map<String, dynamic>>> listStaffNoteRecipients() async {
    if (!PrototypeSession.isSignedIn) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    return PrototypeSampleData.staffNoteRecipientOptions();
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
      return PrototypeSampleData.createStaffNotes(
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
    return PrototypeSampleData.firstUnreadStaffNoteForUser(userId);
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
    PrototypeSampleData.markStaffNoteRead(noteId: noteId, userId: userId);
  }

  Map<String, dynamic> _paginate(
    List<Map<String, dynamic>> all, {
    required int page,
    required int limit,
  }) {
    final int safeLimit = limit.clamp(1, 100);
    final int safePage = page < 1 ? 1 : page;
    final int start = (safePage - 1) * safeLimit;
    final int end = start + safeLimit;
    final List<Map<String, dynamic>> slice = start >= all.length
        ? <Map<String, dynamic>>[]
        : all.sublist(start, end > all.length ? all.length : end);
    return <String, dynamic>{
      'items': slice,
      'total': all.length,
      'page': safePage,
      'limit': safeLimit,
    };
  }
}
