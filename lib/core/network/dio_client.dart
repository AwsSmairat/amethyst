import 'package:amethyst/core/config/api_config.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/network/platform_socket_exception.dart';
import 'package:amethyst/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef UnauthorizedCallback = void Function();

final class DioClient {
  DioClient({
    required TokenStorage tokenStorage,
    UnauthorizedCallback? onUnauthorized,
  })  : _tokenStorage = tokenStorage,
        _onUnauthorized = onUnauthorized {
    if (!ApiConfig.isValidConfiguration) {
      throw ApiException(
        ApiConfig.configurationBlockReason ??
            'Cannot connect to server. API_BASE_URL is not configured.',
      );
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.resolvedBaseUrl,
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

  /// True when Dio on web wraps an XHR that never received a response (CORS,
  /// mixed content, DNS, offline, cold hosting, etc.).
  ///
  /// On some builds the long text lives on [DioException.error], not [DioException.message].
  static bool _looksLikeBrowserTransportFailure(DioException e) {
    final Iterable<String?> chunks = <String?>[
      e.message,
      e.error?.toString(),
    ];
    for (final String? chunk in chunks) {
      if (chunk == null || chunk.isEmpty) continue;
      final String lower = chunk.toLowerCase();
      if (lower.contains('xmlhttprequest') ||
          lower.contains('connection errored') ||
          lower.contains('failed to fetch') ||
          lower.contains('networkerror') ||
          lower.contains('clientexception')) {
        return true;
      }
    }
    return false;
  }

  static Never _throwWebCannotConnect() {
    final String base = ApiConfig.resolvedBaseUrl;
    throw ApiException(
      'Cannot connect to the server from this browser. '
      'Check: (1) API CORS allows your Firebase domain, (2) API_BASE_URL is HTTPS and ends with /api, '
      '(3) the Railway service is running. '
      'تعذّر الاتصال بالخادم من المتصفح — تحقق من CORS وعنوان الـ API وخدمة Railway. '
      '(API: $base)',
    );
  }

  Never throwFromDio(DioException e) {
    if (ApiConfig.debugNetwork || (kDebugMode && kIsWeb)) {
      debugPrint(
        '[dio] ${e.requestOptions.method} uri=${e.requestOptions.uri} '
        'type=${e.type} status=${e.response?.statusCode} message=${e.message} '
        'error=${e.error}',
      );
    }
    final res = e.response;
    if (res?.data is Map<String, dynamic>) {
      final m = res!.data as Map<String, dynamic>;
      final String base = m['message']?.toString() ?? e.message ?? 'Network error';
      final Object? rawErrors = m['errors'];
      String detail = base;
      if (rawErrors is List<dynamic> && rawErrors.isNotEmpty) {
        final Object? first = rawErrors.first;
        if (first is Map<String, dynamic>) {
          final String path = first['path']?.toString() ?? '';
          final String msg = first['message']?.toString() ?? '';
          if (path.isNotEmpty && msg.isNotEmpty) {
            detail = '$base: $path — $msg';
          } else if (msg.isNotEmpty) {
            detail = '$base: $msg';
          }
        }
      }
      throw ApiException(
        detail,
        statusCode: res.statusCode,
        code: m['code']?.toString(),
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw ApiException('Cannot connect to server. Please try again.');
    }
    // Flutter web often surfaces failed XHR as `unknown` (sometimes `connectionError`)
    // with the long "XMLHttpRequest onError" text on [error] or [message].
    final bool webTransportFailure =
        kIsWeb && res == null && _looksLikeBrowserTransportFailure(e);
    if (e.type == DioExceptionType.connectionError || webTransportFailure) {
      final String base = ApiConfig.resolvedBaseUrl;
      final String hint = kIsWeb
          ? 'If you are using the web app, this can be caused by CORS or mixed-content (http vs https).'
          : 'Check your internet connection and server URL.';
      throw ApiException(
        'Cannot connect to server. $hint${base.isNotEmpty ? ' (API: $base)' : ''}',
        statusCode: res?.statusCode,
      );
    }
    final err = e.error;
    if (isPlatformSocketException(err)) {
      throw ApiException('Cannot connect to server. Check your internet connection and server URL.');
    }
    // Any other web failure with no HTTP response (e.g. unusual DioExceptionType).
    if (kIsWeb && res == null) {
      _throwWebCannotConnect();
    }
    throw ApiException(e.message ?? 'Network error', statusCode: res?.statusCode);
  }
}
