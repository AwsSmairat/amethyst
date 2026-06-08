import 'package:flutter/foundation.dart';

/// تحديث قوائم مبيعات المركبة بعد سداد دين أو بيع جديد.
class VehicleSalesListRefresh {
  VehicleSalesListRefresh._();

  static VoidCallback? onRefreshRequested;
  static VoidCallback? onDebtListRefresh;

  static void request() {
    onRefreshRequested?.call();
    onDebtListRefresh?.call();
  }
}
