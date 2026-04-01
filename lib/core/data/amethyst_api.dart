import 'package:amethyst/core/network/dio_client.dart';
import 'package:dio/dio.dart';

/// Central HTTP facade for Amethyst REST endpoints (data layer only).
final class AmethystApi {
  AmethystApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: <String, dynamic>{'email': email, 'password': password},
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> getDashboardSuperAdmin() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard/super-admin');
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> getDashboardAdmin() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard/admin');
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> getDashboardDriver() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard/driver');
      final map = DioClient.unwrapMap(res);
      return _flattenDriverDashboard(map);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> listProducts({int page = 1, int limit = 100}) =>
      _getPaginated('/products', page: page, limit: limit);

  Future<Map<String, dynamic>> listVehicles({int page = 1, int limit = 100}) =>
      _getPaginated('/vehicles', page: page, limit: limit);

  Future<Map<String, dynamic>> listUsers({int page = 1, int limit = 100}) =>
      _getPaginated('/users', page: page, limit: limit);

  Future<Map<String, dynamic>> listVehicleLoads({
    int page = 1,
    int limit = 100,
    String? status,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/vehicle-loads',
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
      return DioClient.unwrapPaginated(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> driverCurrentLoad() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/vehicle-loads/driver/current');
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/vehicle-loads',
        data: <String, dynamic>{
          'vehicleId': vehicleId,
          'driverId': driverId,
          'productId': productId,
          'quantityLoaded': quantityLoaded,
          'loadDate': loadDate,
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> listStationSales({int page = 1, int limit = 100}) =>
      _getPaginated('/station-sales', page: page, limit: limit);

  Future<Map<String, dynamic>> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/station-sales',
        data: <String, dynamic>{
          'productId': productId,
          'quantity': quantity,
          'unitPrice': unitPrice,
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> listVehicleSales({int page = 1, int limit = 100}) =>
      _getPaginated('/vehicle-sales', page: page, limit: limit);

  Future<Map<String, dynamic>> createVehicleSale({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/vehicle-sales',
        data: <String, dynamic>{
          'vehicleId': vehicleId,
          'productId': productId,
          'quantity': quantity,
          'unitPrice': unitPrice,
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> listExpenses({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses',
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          if (dateFrom != null) 'dateFrom': dateFrom,
          if (dateTo != null) 'dateTo': dateTo,
        },
      );
      return DioClient.unwrapPaginated(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> createExpense({
    String? vehicleId,
    required double amount,
    String? note,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expenses',
        data: <String, dynamic>{
          if (vehicleId != null) 'vehicleId': vehicleId,
          'amount': amount,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> listReturns({int page = 1, int limit = 100}) =>
      _getPaginated('/returns', page: page, limit: limit);

  Future<Map<String, dynamic>> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/returns',
        data: <String, dynamic>{
          'vehicleLoadId': vehicleLoadId,
          'quantityReturned': quantityReturned,
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> reportsInventory() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/reports/inventory');
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  /// Days with at least one station or vehicle sale (for super admin history).
  Future<Map<String, dynamic>> reportsSalesWorkingDays() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/reports/sales/working-days');
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> reportsProfitLoss({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/reports/profit-loss',
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          if (dateFrom != null) 'dateFrom': dateFrom,
          if (dateTo != null) 'dateTo': dateTo,
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  /// Station + vehicle sales for a calendar month (current month by default).
  Future<Map<String, dynamic>> reportsSalesMonthly({
    int? year,
    int? month,
  }) async {
    try {
      final DateTime n = DateTime.now();
      final res = await _dio.get<Map<String, dynamic>>(
        '/reports/sales/monthly',
        queryParameters: <String, dynamic>{
          'year': year ?? n.year,
          'month': month ?? n.month,
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> _getPaginated(
    String path, {
    required int page,
    required int limit,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: <String, dynamic>{'page': page, 'limit': limit},
      );
      return DioClient.unwrapPaginated(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }
}

/// `/dashboard/driver` is normalized to `{ role, metrics, details }` on the
/// server. Call sites expect the former flat payload (e.g. `assignedVehicle`).
Map<String, dynamic> _flattenDriverDashboard(Map<String, dynamic> root) {
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
