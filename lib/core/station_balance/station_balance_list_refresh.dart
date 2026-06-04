import 'package:flutter/foundation.dart';

/// تحديث شاشة رصيد المحطة بعد بيع أو تسجيل رصيد.
class StationBalanceListRefresh {
  StationBalanceListRefresh._();

  static VoidCallback? onRefreshRequested;

  static void request() => onRefreshRequested?.call();
}
