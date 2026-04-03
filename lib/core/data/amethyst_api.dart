import 'package:amethyst/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'dart:math';
import 'dart:typed_data';

/// Satisfies older APIs that still validate `phone` on POST /users (e.g. production
/// before deploy). Current server Zod strips unknown keys and stores `null` in DB.
String _syntheticPhoneForUserCreate() {
  final int n = Random().nextInt(90000000) + 10000000;
  return '+1000$n';
}

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
      final map = DioClient.unwrapMap(res);
      return _flattenSuperAdminDashboard(map);
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

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String unitType,
    required double price,
    int stationStock = 0,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/products',
        data: <String, dynamic>{
          'name': name,
          'unitType': unitType,
          'price': price,
          'stationStock': stationStock,
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<void> patchProductStationStock({
    required String id,
    required int stationStock,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/products/$id/stock',
        data: <String, dynamic>{'stationStock': stationStock},
      );
      DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    double? price,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/products/$id',
        data: <String, dynamic>{
          if (price != null) 'price': price,
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>('/products/$id');
      DioClient.unwrapData(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> listVehicles({int page = 1, int limit = 100}) =>
      _getPaginated('/vehicles', page: page, limit: limit);

  Future<Map<String, dynamic>> createVehicle({
    required String vehicleNumber,
    String? driverId,
    String? notes,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/vehicles',
        data: <String, dynamic>{
          'vehicleNumber': vehicleNumber,
          if (driverId != null && driverId.isNotEmpty) 'driverId': driverId,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>('/vehicles/$id');
      DioClient.unwrapData(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  /// `limit` must be ≤ 100 (API query validation).
  Future<Map<String, dynamic>> listUsers({int page = 1, int limit = 100}) =>
      _getPaginated('/users', page: page, limit: limit);

  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/users',
        data: <String, dynamic>{
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
          'phone': _syntheticPhoneForUserCreate(),
        },
      );
      return DioClient.unwrapMap(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>('/users/$id');
      DioClient.unwrapData(res);
    } on DioException catch (e) {
      _client.throwFromDio(e);
    }
  }

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
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
  }) async {
    try {
      final Map<String, dynamic> data = <String, dynamic>{
        'productId': productId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'fillingSale': fillingSale,
      };
      // تعبئة: يجب إرسال فهرس العمود دائماً (٠ و١ = بدون خصم مخزون). القيمة ٠ صالحة.
      if (fillingSale) {
        final int slot = fillingLineSlot!;
        data['fillingLineSlot'] = slot;
        // احتياط إن وُجد وسيط يتعامل مع snake_case فقط
        data['filling_slot'] = slot;
      }
      // ملاحظة «كوبون» لبيع التعبئة (جالون/قارورة بسعر 0) — نرسلها حتى لو ضاعت في طبقة أخرى.
      String? noteOut;
      if (note != null && note.trim().isNotEmpty) {
        noteOut = note.trim();
      } else if (fillingSale &&
          fillingLineSlot != null &&
          fillingLineSlot < 2 &&
          unitPrice == 0) {
        noteOut = 'كوبون';
      }
      if (noteOut != null && noteOut.isNotEmpty) {
        data['note'] = noteOut;
      }
      final res = await _dio.post<Map<String, dynamic>>(
        '/station-sales',
        data: data,
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

  /// `limit` على الخادم بحد أقصى 100 ([listQuerySchema]).
  Future<Map<String, dynamic>> listExpenses({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    final int safeLimit = limit.clamp(1, 100);
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses',
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': safeLimit,
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
    Uint8List? receiptBytes,
    String? receiptFilename,
  }) async {
    try {
      final data = receiptBytes == null
          ? <String, dynamic>{
              if (vehicleId != null) 'vehicleId': vehicleId,
              'amount': amount,
              if (note != null && note.isNotEmpty) 'note': note,
            }
          : FormData.fromMap(<String, dynamic>{
              if (vehicleId != null) 'vehicleId': vehicleId,
              'amount': amount,
              if (note != null && note.isNotEmpty) 'note': note,
              'receipt': MultipartFile.fromBytes(
                receiptBytes,
                filename: receiptFilename ?? 'receipt.jpg',
              ),
            });
      final res = await _dio.post<Map<String, dynamic>>(
        '/expenses',
        data: data,
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

/// `/dashboard/super-admin` uses the same envelope as other roles; KPI widgets
/// expect flat keys (`totalSalesToday`, `totalUsers`, …).
Map<String, dynamic> _flattenSuperAdminDashboard(Map<String, dynamic> root) {
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
    'totalUsers': c['users'] ?? 0,
    'totalAdmins': c['admins'] ?? 0,
    'totalDrivers': c['drivers'] ?? 0,
    'totalVehicles': c['vehicles'] ?? 0,
    'totalProducts': c['products'] ?? 0,
    'productsWithPrice': c['pricedProducts'] ?? 0,
  };
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
