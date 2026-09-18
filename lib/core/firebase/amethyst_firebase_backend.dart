import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:amethyst/core/catalog/carton_product_match.dart';
import 'package:amethyst/core/firebase/date_range_utils.dart';
import 'package:amethyst/core/firebase/firebase_auth_service.dart';
import 'package:amethyst/core/firebase/firebase_storage_service.dart';
import 'package:amethyst/core/firebase/firestore_mappers.dart';
import 'package:amethyst/core/firebase/firestore_paths.dart';
import 'package:amethyst/core/firebase/station_stock_skip.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/expenses/profit_vehicle_expense_deduction.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sales_aggregates.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_aggregates.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_product_columns.dart';
import 'package:amethyst/core/station_debt/station_debt_entry_utils.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'backend/helpers.dart';
part 'backend/catalog.dart';
part 'backend/station_sales.dart';
part 'backend/vehicle_sales.dart';
part 'backend/debt.dart';
part 'backend/expenses_cash.dart';
part 'backend/reports_core.dart';
part 'backend/reports.dart';
part 'backend/dashboard_super_admin.dart';
part 'backend/dashboard_staff.dart';
part 'backend/staff_notes.dart';

const Duration _dashboardCacheTtl = Duration(minutes: 3);
const Duration _catalogCacheTtl = Duration(seconds: 90);

abstract class _AmethystFirebaseBackendBase {
  _AmethystFirebaseBackendBase({
    FirebaseAuthService? authService,
    FirebaseStorageService? storageService,
    FirebaseFirestore? firestore,
  })  : _auth = authService ?? FirebaseAuthService(),
        _storage = storageService ?? FirebaseStorageService(),
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuthService _auth;
  final FirebaseStorageService _storage;
  final FirebaseFirestore _db;
  Map<String, dynamic>? _dashboardCache;
  DateTime? _dashboardCachedAt;
  Map<String, dynamic>? _adminDashboardCache;
  DateTime? _adminDashboardCachedAt;
  Map<String, dynamic>? _driverDashboardCache;
  DateTime? _driverDashboardCachedAt;
  String? _driverDashboardCacheUserId;
  List<Map<String, dynamic>>? _activeProductsCache;
  DateTime? _activeProductsCachedAt;
  Map<String, Map<String, dynamic>>? _allProductsLookupCache;
  DateTime? _allProductsLookupCachedAt;
  Map<String, Map<String, dynamic>>? _vehiclesLookupCache;
  DateTime? _vehiclesLookupCachedAt;
  final Map<String, Map<String, dynamic>> _userBriefMemCache =
      <String, Map<String, dynamic>>{};
  List<Map<String, dynamic>>? _hydratedStationSalesCache;
  DateTime? _hydratedStationSalesCachedAt;
  List<Map<String, dynamic>>? _stationDebtSummaryCache;
  DateTime? _stationDebtSummaryCachedAt;
  List<Map<String, dynamic>>? _hydratedExpensesCache;
  DateTime? _hydratedExpensesCachedAt;
  List<Map<String, dynamic>>? _hydratedVehicleSalesCache;
  DateTime? _hydratedVehicleSalesCachedAt;
  String? _hydratedVehicleSalesScopeKey;
  List<Map<String, dynamic>>? _hydratedVehicleLoadsCache;
  DateTime? _hydratedVehicleLoadsCachedAt;
  String? _hydratedVehicleLoadsScopeKey;
  List<Map<String, dynamic>>? _openDebtListCache;
  DateTime? _openDebtListCachedAt;
  String? _openDebtListScopeKey;
  final Map<String, List<Map<String, dynamic>>> _vehicleSalesQueryCache =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, DateTime> _vehicleSalesQueryCachedAt =
      <String, DateTime>{};
  final Map<String, Future<List<Map<String, dynamic>>>>
      _vehicleSalesQueryInFlight =
      <String, Future<List<Map<String, dynamic>>>>{};
  Future<List<Map<String, dynamic>>>? _hydratedVehicleSalesInFlight;
  String? _hydratedVehicleSalesInFlightKey;
  Future<List<Map<String, dynamic>>>? _hydratedExpensesInFlight;
  Future<List<Map<String, dynamic>>>? _hydratedStationSalesInFlight;
  final Map<String, List<Map<String, dynamic>>> _rangeListCache =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, DateTime> _rangeListCachedAt = <String, DateTime>{};
  final Map<String, Future<List<Map<String, dynamic>>>> _rangeListInFlight =
      <String, Future<List<Map<String, dynamic>>>>{};

  FirebaseAuthService get authService => _auth;

  void clearDashboardCache() {
    _dashboardCache = null;
    _dashboardCachedAt = null;
    _adminDashboardCache = null;
    _adminDashboardCachedAt = null;
    _driverDashboardCache = null;
    _driverDashboardCachedAt = null;
    _driverDashboardCacheUserId = null;
  }

  void clearCatalogCache() {
    _activeProductsCache = null;
    _activeProductsCachedAt = null;
    _allProductsLookupCache = null;
    _allProductsLookupCachedAt = null;
    _vehiclesLookupCache = null;
    _vehiclesLookupCachedAt = null;
    _userBriefMemCache.clear();
    _clearListCaches();
    clearDashboardCache();
  }

  void _clearListCaches() {
    _hydratedStationSalesCache = null;
    _hydratedStationSalesCachedAt = null;
    _stationDebtSummaryCache = null;
    _stationDebtSummaryCachedAt = null;
    _hydratedExpensesCache = null;
    _hydratedExpensesCachedAt = null;
    _hydratedVehicleSalesCache = null;
    _hydratedVehicleSalesCachedAt = null;
    _hydratedVehicleSalesScopeKey = null;
    _hydratedVehicleLoadsCache = null;
    _hydratedVehicleLoadsCachedAt = null;
    _hydratedVehicleLoadsScopeKey = null;
    _openDebtListCache = null;
    _openDebtListCachedAt = null;
    _openDebtListScopeKey = null;
    _vehicleSalesQueryCache.clear();
    _vehicleSalesQueryCachedAt.clear();
    _vehicleSalesQueryInFlight.clear();
    _hydratedVehicleSalesInFlight = null;
    _hydratedVehicleSalesInFlightKey = null;
    _hydratedExpensesInFlight = null;
    _hydratedStationSalesInFlight = null;
    _rangeListCache.clear();
    _rangeListCachedAt.clear();
    _rangeListInFlight.clear();
  }

  Future<List<Map<String, dynamic>>> _cachedRangeList(
    String key,
    Future<List<Map<String, dynamic>>> Function() load,
  ) async {
    final List<Map<String, dynamic>>? cached = _rangeListCache[key];
    final DateTime? cachedAt = _rangeListCachedAt[key];
    if (cached != null && _catalogCacheFresh(cachedAt)) {
      return cached;
    }
    final Future<List<Map<String, dynamic>>>? inFlight =
        _rangeListInFlight[key];
    if (inFlight != null) {
      return inFlight;
    }
    final Future<List<Map<String, dynamic>>> future = () async {
      try {
        final List<Map<String, dynamic>> items = await load();
        _rangeListCache[key] = items;
        _rangeListCachedAt[key] = DateTime.now();
        return items;
      } finally {
        _rangeListInFlight.remove(key);
      }
    }();
    _rangeListInFlight[key] = future;
    return future;
  }

  bool _catalogCacheFresh(DateTime? cachedAt) =>
      cachedAt != null &&
      DateTime.now().difference(cachedAt) < _catalogCacheTtl;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final UserEntity user = await _auth.login(email: email, password: password);
    return <String, dynamic>{
      'user': <String, dynamic>{
        'id': user.id,
        'email': user.email,
        'fullName': user.fullName,
        'role': user.role,
        'phone': user.phone,
        'isActive': user.isActive,
      },
    };
  }

  Future<Map<String, dynamic>> me() async {
    final UserEntity user = await _auth.loadCurrentUser();
    return <String, dynamic>{
      'id': user.id,
      'email': user.email,
      'fullName': user.fullName,
      'role': user.role,
      'phone': user.phone,
      'isActive': user.isActive,
    };
  }
}

final class AmethystFirebaseBackend extends _AmethystFirebaseBackendBase
    with
        _FirebaseBackendHelpers,
        _FirebaseCatalogOps,
        _FirebaseStationSalesOps,
        _FirebaseVehicleSalesOps,
        _FirebaseDebtOps,
        _FirebaseExpensesCashOps,
        _FirebaseReportsCoreOps,
        _FirebaseReportsOps,
        _FirebaseSuperAdminDashboardOps,
        _FirebaseStaffDashboardsOps,
        _FirebaseStaffNotesOps {
  AmethystFirebaseBackend({
    super.authService,
    super.storageService,
    super.firestore,
  });
}

final class _StationSaleBatchLine {
  const _StationSaleBatchLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.fillingLineSlot,
    this.note,
  });

  final String productId;
  final int quantity;
  final double unitPrice;
  final int? fillingLineSlot;
  final String? note;
}

final class _VehicleSaleBatchLine {
  const _VehicleSaleBatchLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.stockProductId,
    this.debtorName,
    this.isDebt = false,
    this.skipLoadDeduction = false,
    this.deductStationStock = false,
  });

  final String productId;
  final int quantity;
  final double unitPrice;
  final String? stockProductId;
  final String? debtorName;
  final bool isDebt;
  final bool skipLoadDeduction;
  final bool deductStationStock;
}

final class _MutableVehicleLoadRow {
  _MutableVehicleLoadRow({
    required this.ref,
    required this.loaded,
    required this.returned,
    required int quantitySold,
  })  : initialSold = quantitySold,
        sold = quantitySold;

  final DocumentReference<Map<String, dynamic>> ref;
  final int loaded;
  final int returned;
  final int initialSold;
  int sold;

  int get available => loaded - sold - returned;
}

final class _VehicleLoadAllocationRow {
  const _VehicleLoadAllocationRow({
    required this.row,
    required this.productId,
    required this.productName,
  });

  final _MutableVehicleLoadRow row;
  final String productId;
  final String productName;
}
