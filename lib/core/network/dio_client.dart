import 'package:amethyst/core/config/api_config.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';

typedef UnauthorizedCallback = void Function();

final class DioClient {
  DioClient({
    required TokenStorage tokenStorage,
    UnauthorizedCallback? onUnauthorized,
  })  : _tokenStorage = tokenStorage,
        _onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: <String, dynamic>{
          Headers.acceptHeader: 'application/json',
          Headers.contentTypeHeader: 'application/json',
        },
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode == 401) {
            await _tokenStorage.deleteToken();
            _onUnauthorized?.call();
          }
          return handler.next(err);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final UnauthorizedCallback? _onUnauthorized;
  late final Dio _dio;

  Dio get dio => _dio;

  static dynamic unwrapData(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected response shape');
    }
    if (data['success'] != true) {
      throw ApiException(
        data['message']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
        code: data['code']?.toString(),
      );
    }
    return data['data'];
  }

  static Map<String, dynamic> unwrapMap(Response<dynamic> response) {
    final data = unwrapData(response);
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected data shape');
    }
    return data;
  }

  static List<dynamic> unwrapList(Response<dynamic> response) {
    final data = unwrapData(response);
    if (data is! List<dynamic>) {
      throw ApiException('Unexpected list shape');
    }
    return data;
  }

  static Map<String, dynamic> unwrapPaginated(Response<dynamic> response) {
    final data = unwrapData(response);
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected paginated shape');
    }
    return data;
  }

  Never throwFromDio(DioException e) {
    final res = e.response;
    if (res?.data is Map<String, dynamic>) {
      final m = res!.data as Map<String, dynamic>;
      throw ApiException(
        m['message']?.toString() ?? e.message ?? 'Network error',
        statusCode: res.statusCode,
        code: m['code']?.toString(),
      );
    }
    throw ApiException(e.message ?? 'Network error', statusCode: res?.statusCode);
  }
}
