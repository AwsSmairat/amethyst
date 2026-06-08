import 'package:flutter/foundation.dart';

/// تحديث شاشة حمولة السيارة بعد بيع أو دين من المركبة.
class DriverLoadsListRefresh {
  DriverLoadsListRefresh._();

  static VoidCallback? onRefreshRequested;

  static void request() => onRefreshRequested?.call();
}
