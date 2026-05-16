import 'dart:typed_data';

import 'package:amethyst/core/firebase/amethyst_firebase_backend.dart';
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

  final AmethystFirebaseBackend _backend;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) =>
      _backend.login(email: email, password: password);

  Future<Map<String, dynamic>> me() => _backend.me();

  Future<Map<String, dynamic>> getDashboardSuperAdmin() async {
    final map = await _backend.getDashboardSuperAdmin();
    return flattenSuperAdminDashboard(map);
  }

  Future<Map<String, dynamic>> getSuperAdminCartonSummary({
    int? year,
    int? month,
  }) =>
      _backend.getSuperAdminCartonSummary(year: year, month: month);

  Future<Map<String, dynamic>> getDashboardAdmin() => _backend.getDashboardAdmin();

  Future<Map<String, dynamic>> getDashboardDriver() async {
    final map = await _backend.getDashboardDriver();
    return flattenDriverDashboard(map);
  }

  Future<Map<String, dynamic>> listProducts({int page = 1, int limit = 100}) =>
      _backend.listProducts(page: page, limit: limit);

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String unitType,
    required double price,
    int stationStock = 0,
  }) =>
      _backend.createProduct(
        name: name,
        unitType: unitType,
        price: price,
        stationStock: stationStock,
      );

  Future<void> patchProductStationStock({
    required String id,
    required int stationStock,
  }) =>
      _backend.patchProductStationStock(id: id, stationStock: stationStock);

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    double? price,
  }) =>
      _backend.updateProduct(id: id, price: price);

  Future<void> deleteProduct(String id) => _backend.deleteProduct(id);

  Future<Map<String, dynamic>> listVehicles({int page = 1, int limit = 100}) =>
      _backend.listVehicles(page: page, limit: limit);

  Future<Map<String, dynamic>> createVehicle({
    required String vehicleNumber,
    String? driverId,
    String? notes,
  }) =>
      _backend.createVehicle(
        vehicleNumber: vehicleNumber,
        driverId: driverId,
        notes: notes,
      );

  Future<void> deleteVehicle(String id) => _backend.deleteVehicle(id);

  Future<Map<String, dynamic>> listUsers({int page = 1, int limit = 100}) =>
      _backend.listUsers(page: page, limit: limit);

  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) =>
      _backend.createUser(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );

  Future<void> deleteUser(String id) => _backend.deleteUser(id);

  Future<Map<String, dynamic>> listVehicleLoads({
    int page = 1,
    int limit = 100,
    String? status,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) =>
      _backend.listVehicleLoads(
        page: page,
        limit: limit,
        status: status,
        vehicleId: vehicleId,
        driverId: driverId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<Map<String, dynamic>> driverCurrentLoad() => _backend.driverCurrentLoad();

  Future<Map<String, dynamic>> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
  }) =>
      _backend.createVehicleLoad(
        vehicleId: vehicleId,
        driverId: driverId,
        productId: productId,
        quantityLoaded: quantityLoaded,
        loadDate: loadDate,
      );

  Future<Map<String, dynamic>> listStationSales({int page = 1, int limit = 100}) =>
      _backend.listStationSales(page: page, limit: limit);

  Future<Map<String, dynamic>> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
  }) =>
      _backend.createStationSale(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        fillingSale: fillingSale,
        fillingLineSlot: fillingLineSlot,
        note: note,
      );

  Future<void> createStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) =>
      _backend.createStationDebtEntries(debtorName: debtorName, lines: lines);

  Future<Map<String, dynamic>> listStationDebtEntries({
    int page = 1,
    int limit = 100,
  }) =>
      _backend.listStationDebtEntries(page: page, limit: limit);

  Future<Map<String, dynamic>> repayStationDebt({required String debtorName}) =>
      _backend.repayStationDebt(debtorName: debtorName);

  Future<Map<String, dynamic>> repayStationDebtFromVehicle({
    required String debtorName,
  }) =>
      _backend.repayStationDebtFromVehicle(debtorName: debtorName);

  Future<Map<String, dynamic>> listVehicleSales({
    int page = 1,
    int limit = 100,
    String? vehicleId,
    String? driverId,
    String? dateFrom,
    String? dateTo,
  }) =>
      _backend.listVehicleSales(
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
  }) =>
      _backend.createVehicleSale(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        saleDestination: saleDestination,
      );

  Future<Map<String, dynamic>> listExpenses({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) =>
      _backend.listExpenses(
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
      _backend.createExpense(
        vehicleId: vehicleId,
        amount: amount,
        note: note,
        receiptBytes: receiptBytes,
        receiptFilename: receiptFilename,
      );

  Future<Map<String, dynamic>> listReturns({int page = 1, int limit = 100}) =>
      _backend.listReturns(page: page, limit: limit);

  Future<Map<String, dynamic>> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) =>
      _backend.createReturn(
        vehicleLoadId: vehicleLoadId,
        quantityReturned: quantityReturned,
      );

  Future<Map<String, dynamic>> reportsInventory() => _backend.reportsInventory();

  Future<Map<String, dynamic>> reportsSalesWorkingDays() =>
      _backend.reportsSalesWorkingDays();

  Future<Map<String, dynamic>> reportsProfitLoss({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) =>
      _backend.reportsProfitLoss(
        page: page,
        limit: limit,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<Map<String, dynamic>> reportsSalesMonthly({
    int? year,
    int? month,
  }) =>
      _backend.reportsSalesMonthly(year: year, month: month);
}

extension AmethystApiErrors on AmethystApi {
  static ApiException wrap(Object e) {
    if (e is ApiException) {
      return e;
    }
    return ApiException(e.toString());
  }
}
