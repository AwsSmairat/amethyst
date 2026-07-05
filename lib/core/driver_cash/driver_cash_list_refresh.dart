import 'package:flutter/foundation.dart';

/// تحديث عرض رصيد أموال السائق بعد التسجيل.
class DriverCashListRefresh {
  DriverCashListRefresh._();

  static VoidCallback? onRefreshRequested;

  static void request() => onRefreshRequested?.call();
}
