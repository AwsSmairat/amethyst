import 'package:flutter/foundation.dart';

/// تحديث عرض رصيد الأموال بعد التسجيل.
class StationCashListRefresh {
  StationCashListRefresh._();

  static VoidCallback? onRefreshRequested;

  static void request() => onRefreshRequested?.call();
}
