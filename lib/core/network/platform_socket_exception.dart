import 'platform_socket_exception_stub.dart'
    if (dart.library.io) 'platform_socket_exception_io.dart';

/// Cross-platform helper to detect `SocketException` without importing `dart:io`
/// on the web.
bool isPlatformSocketException(Object? error) => isSocketExceptionImpl(error);

