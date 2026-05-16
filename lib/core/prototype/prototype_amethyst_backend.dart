import 'dart:typed_data';

import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/prototype/prototype_sample_data.dart';
import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';

/// UI-only backend: static sample reads, writes show [kUiOnlyMessage].
final class PrototypeAmethystBackend {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return PrototypeSampleData.meFromSession();
  }

  Future<Map<String, dynamic>> me() async {
    if (!PrototypeSession.isSignedIn) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    return PrototypeSampleData.meFromSession();
  }

  Future<Map<String, dynamic>> listProducts({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.products, page: page, limit: limit);

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String unitType,
    required double price,
    int stationStock = 0,
  }) async {
    throwUiOnlyWrite();
  }

  Future<void> patchProductStationStock({
    required String id,
    required int stationStock,
  }) async {
    throwUiOnlyWrite();
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    double? price,
  }) async {
    throwUiOnlyWrite();
  }

  Future<void> deleteProduct(String id) async {
    throwUiOnlyWrite();
  }

  Future<Map<String, dynamic>> listVehicles({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.vehicles, page: page, limit: limit);

  Future<Map<String, dynamic>> createVehicle({
    required String vehicleNumber,
    String? driverId,
    String? notes,
  }) async {
    throwUiOnlyWrite();
  }

  Future<void> deleteVehicle(String id) async {
    throwUiOnlyWrite();
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
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> driverCurrentLoad() async =>
      PrototypeSampleData.driverCurrentLoad();

  Future<Map<String, dynamic>> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
  }) async {
    throwUiOnlyWrite();
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
    throwUiOnlyWrite();
  }

  Future<void> createStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) async {
    throwUiOnlyWrite();
  }

  Future<Map<String, dynamic>> listStationDebtEntries({
    int page = 1,
    int limit = 100,
  }) async =>
      _paginate(PrototypeSampleData.stationDebtEntries, page: page, limit: limit);

  Future<Map<String, dynamic>> repayStationDebt({required String debtorName}) async {
    throwUiOnlyWrite();
  }

  Future<Map<String, dynamic>> repayStationDebtFromVehicle({
    required String debtorName,
  }) async {
    throwUiOnlyWrite();
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
    return _paginate(items, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createVehicleSale({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String saleDestination = 'home',
  }) async {
    throwUiOnlyWrite();
  }

  Future<Map<String, dynamic>> listExpenses({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async =>
      _paginate(PrototypeSampleData.expenses, page: page, limit: limit);

  Future<Map<String, dynamic>> createExpense({
    String? vehicleId,
    required double amount,
    String? note,
    Uint8List? receiptBytes,
    String? receiptFilename,
  }) async {
    throwUiOnlyWrite();
  }

  Future<Map<String, dynamic>> listReturns({int page = 1, int limit = 100}) async =>
      _paginate(PrototypeSampleData.returns, page: page, limit: limit);

  Future<Map<String, dynamic>> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) async {
    throwUiOnlyWrite();
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
      PrototypeSampleData.reportsSalesMonthly();

  Future<Map<String, dynamic>> getDashboardSuperAdmin() async =>
      PrototypeSampleData.getDashboardSuperAdmin();

  Future<Map<String, dynamic>> getSuperAdminCartonSummary({
    int? year,
    int? month,
  }) async =>
      PrototypeSampleData.getSuperAdminCartonSummary();

  Future<Map<String, dynamic>> getDashboardAdmin() async =>
      PrototypeSampleData.getDashboardAdmin();

  Future<Map<String, dynamic>> getDashboardDriver() async {
    final UserEntity? user = PrototypeSession.current;
    if (user?.role != 'driver') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
    return PrototypeSampleData.getDashboardDriver();
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
