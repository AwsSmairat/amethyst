import 'dart:typed_data';

import 'package:amethyst/core/network/api_exception.dart';

Map<String, dynamic> flattenSuperAdminDashboard(Map<String, dynamic> root) {
  final Object? details = root['details'];
  final Object? metrics = root['metrics'];
  if (details is! Map<String, dynamic> || metrics is! Map<String, dynamic>) {
    return root;
  }
  final Object? counts = details['counts'];
  final Map<String, dynamic> c =
      counts is Map<String, dynamic> ? counts : <String, dynamic>{};
  return <String, dynamic>{
    ...root,
    ...metrics,
    'totalUsers': c['users'] ?? root['totalUsers'] ?? 0,
    'totalAdmins': c['admins'] ?? root['totalAdmins'] ?? 0,
    'totalDrivers': c['drivers'] ?? root['totalDrivers'] ?? 0,
    'totalVehicles': c['vehicles'] ?? root['totalVehicles'] ?? 0,
    'totalProducts': c['products'] ?? root['totalProducts'] ?? 0,
    'productsWithPrice': c['pricedProducts'] ?? root['productsWithPrice'] ?? 0,
  };
}

Map<String, dynamic> flattenDriverDashboard(Map<String, dynamic> root) {
  final Object? details = root['details'];
  final Object? metrics = root['metrics'];
  if (details is! Map<String, dynamic> || metrics is! Map<String, dynamic>) {
    return root;
  }
  return <String, dynamic>{
    ...root,
    'assignedVehicle': details['assignedVehicle'],
    'remainingQuantities': details['remainingQuantities'],
    'notesSummary': details['notesSummary'],
    'productsLoadedToday': details['productsLoadedToday'],
    'soldQuantitiesToday': details['soldQuantitiesToday'],
    'returnedQuantitiesToday': details['returnedQuantitiesToday'],
    'totalExpensesToday': metrics['totalExpensesToday'],
    'vehicleSalesAmountToday': metrics['vehicleSalesToday'],
    'remainingOnVehicle': metrics['remainingOnVehicle'],
  };
}

final class AmethystApi {
  AmethystApi(this._backend);

  /// [PrototypeAmethystBackend] — static sample data for UI preview.
  final Object _backend;

  dynamic get _b => _backend;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) =>
      _b.login(email: email, password: password);

  Future<Map<String, dynamic>> me() => _b.me();

  Future<Map<String, dynamic>> getDashboardSuperAdmin({
    void Function(Map<String, dynamic> partial)? onPartial,
    bool forceRefresh = false,
  }) async {
    final map = await _b.getDashboardSuperAdmin(
      onPartial: onPartial == null
          ? null
          : (Map<String, dynamic> partial) =>
              onPartial(flattenSuperAdminDashboard(partial)),
      forceRefresh: forceRefresh,
    );
    return flattenSuperAdminDashboard(map);
  }

  Future<Map<String, dynamic>> getSuperAdminCartonSummary({
    int? year,
    int? month,
  }) =>
      _b.getSuperAdminCartonSummary(year: year, month: month);

  Future<Map<String, dynamic>> getDashboardAdmin() => _b.getDashboardAdmin();

  Future<Map<String, dynamic>> getDashboardDriver() async {
    final map = await _b.getDashboardDriver();
    return flattenDriverDashboard(map);
  }

  Future<Map<String, dynamic>> listProducts({int page = 1, int limit = 100}) =>
      _b.listProducts(page: page, limit: limit);

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String unitType,
    required double price,
    int stationStock = 0,
  }) =>
      _b.createProduct(
        name: name,
        unitType: unitType,
        price: price,
        stationStock: stationStock,
      );

  Future<void> patchProductStationStock({
    required String id,
    required int stationStock,
  }) =>
      _b.patchProductStationStock(id: id, stationStock: stationStock);

  Future<void> deductStationStockForSale({
    required String productId,
    required int quantity,
  }) =>
      _b.deductStationStockForSale(
        productId: productId,
        quantity: quantity,
      );

  Future<void> upsertStationBalanceRowStock({
    required int rowIndex,
    required int stationStock,
  }) =>
      _b.upsertStationBalanceRowStock(
        rowIndex: rowIndex,
        stationStock: stationStock,
      );

  Future<void> saveStationBalanceRows({
    required List<Map<String, dynamic>> rows,
  }) =>
      _b.saveStationBalanceRows(rows: rows);

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    double? price,
  }) =>
      _b.updateProduct(id: id, price: price);

  Future<void> deleteProduct(String id) => _b.deleteProduct(id);

  Future<Map<String, dynamic>> listVehicles({int page = 1, int limit = 100}) =>
      _b.listVehicles(page: page, limit: limit);

  Future<Map<String, dynamic>> createVehicle({
    required String vehicleNumber,
    String? driverId,
    String? notes,
  }) =>
      _b.createVehicle(
        vehicleNumber: vehicleNumber,
        driverId: driverId,
        notes: notes,
      );

  Future<void> deleteVehicle(String id) => _b.deleteVehicle(id);

  Future<Map<String, dynamic>> listUsers({int page = 1, int limit = 100}) =>
      _b.listUsers(page: page, limit: limit);

  Future<Map<String, dynamic>> listVehicleLoads({
    int page = 1,
    int limit = 100,
    String? status,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) =>
      _b.listVehicleLoads(
        page: page,
        limit: limit,
        status: status,
        vehicleId: vehicleId,
        driverId: driverId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<Map<String, dynamic>> driverCurrentLoad() => _b.driverCurrentLoad();

  Future<String?> driverAssignedVehicleId() => _b.driverAssignedVehicleId();

  Future<Map<String, dynamic>> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
    String? loadBatchId,
  }) =>
      _b.createVehicleLoad(
        vehicleId: vehicleId,
        driverId: driverId,
        productId: productId,
        quantityLoaded: quantityLoaded,
        loadDate: loadDate,
        loadBatchId: loadBatchId,
      );

  Future<void> createVehicleLoadsBatch({
    required String vehicleId,
    required String driverId,
    required String loadDate,
    required List<Map<String, dynamic>> lines,
    String? loadBatchId,
  }) =>
      _b.createVehicleLoadsBatch(
        vehicleId: vehicleId,
        driverId: driverId,
        loadDate: loadDate,
        lines: lines,
        loadBatchId: loadBatchId,
      );

  Future<Map<String, dynamic>> listStationSales({int page = 1, int limit = 100}) =>
      _b.listStationSales(page: page, limit: limit);

  Future<Map<String, dynamic>> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
  }) =>
      _b.createStationSale(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        fillingSale: fillingSale,
        fillingLineSlot: fillingLineSlot,
        note: note,
      );

  Future<void> createStationSalesBatch({
    required List<Map<String, dynamic>> lines,
    bool fillingSale = false,
  }) =>
      _b.createStationSalesBatch(lines: lines, fillingSale: fillingSale);

  Future<void> createStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) =>
      _b.createStationDebtEntries(debtorName: debtorName, lines: lines);

  Future<Map<String, dynamic>> listStationDebtEntries({
    int page = 1,
    int limit = 100,
  }) =>
      _b.listStationDebtEntries(page: page, limit: limit);

  Future<Map<String, dynamic>> repayStationDebt({required String debtorName}) =>
      _b.repayStationDebt(debtorName: debtorName);

  Future<Map<String, dynamic>> repayStationDebtFromVehicle({
    required String debtorName,
  }) =>
      _b.repayStationDebtFromVehicle(debtorName: debtorName);

  Future<Map<String, dynamic>> listVehicleSales({
    int page = 1,
    int limit = 100,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) =>
      _b.listVehicleSales(
        page: page,
        limit: limit,
        vehicleId: vehicleId,
        driverId: driverId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

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
  }) =>
      _b.createVehicleSale(
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

  Future<void> createVehicleSalesBatch({
    required String vehicleId,
    required List<Map<String, dynamic>> lines,
    String saleDestination = 'home',
  }) =>
      _b.createVehicleSalesBatch(
        vehicleId: vehicleId,
        lines: lines,
        saleDestination: saleDestination,
      );

  Future<Map<String, dynamic>> listExpenses({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) =>
      _b.listExpenses(
        page: page,
        limit: limit,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<Map<String, dynamic>> createExpense({
    String? vehicleId,
    required double amount,
    String? note,
    Uint8List? receiptBytes,
    String? receiptFilename,
  }) =>
      _b.createExpense(
        vehicleId: vehicleId,
        amount: amount,
        note: note,
        receiptBytes: receiptBytes,
        receiptFilename: receiptFilename,
      );

  Future<Map<String, dynamic>> listReturns({int page = 1, int limit = 100}) =>
      _b.listReturns(page: page, limit: limit);

  Future<Map<String, dynamic>> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) =>
      _b.createReturn(
        vehicleLoadId: vehicleLoadId,
        quantityReturned: quantityReturned,
      );

  Future<Map<String, dynamic>> reportsInventory() => _b.reportsInventory();

  Future<Map<String, dynamic>> reportsSalesWorkingDays() =>
      _b.reportsSalesWorkingDays();

  Future<Map<String, dynamic>> reportsProfitLoss({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) =>
      _b.reportsProfitLoss(
        page: page,
        limit: limit,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<Map<String, dynamic>> reportsSalesMonthly({
    int? year,
    int? month,
  }) =>
      _b.reportsSalesMonthly(year: year, month: month);

  Future<List<Map<String, dynamic>>> listStaffNoteRecipients() =>
      _b.listStaffNoteRecipients();

  Future<List<Map<String, dynamic>>> createStaffNotes({
    required String message,
    required String recipientKind,
    String? driverUserId,
  }) =>
      _b.createStaffNotes(
        message: message,
        recipientKind: recipientKind,
        driverUserId: driverUserId,
      );

  Future<Map<String, dynamic>?> getPendingStaffNoteForMe() =>
      _b.getPendingStaffNoteForMe();

  Stream<Map<String, dynamic>?> watchPendingStaffNoteForMe() =>
      _b.watchPendingStaffNoteForMe();

  Future<void> markStaffNoteRead(String noteId) => _b.markStaffNoteRead(noteId);
}

extension AmethystApiErrors on AmethystApi {
  static ApiException wrap(Object e) {
    if (e is ApiException) {
      return e;
    }
    return ApiException(e.toString());
  }
}
