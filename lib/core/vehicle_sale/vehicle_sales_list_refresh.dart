import 'package:flutter/foundation.dart';

/// تحديث قوائم مبيعات المركبة بعد سداد دين أو بيع جديد.
class VehicleSalesListRefresh {
  VehicleSalesListRefresh._();

  static VoidCallback? onRefreshRequested;

  static void request() => onRefreshRequested?.call();
}
