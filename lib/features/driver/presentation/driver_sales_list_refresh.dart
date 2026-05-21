import 'package:flutter/foundation.dart';

/// يُستدعى عند اختيار تبويب «المبيعات» في شريط السائق لتحديث القائمة.
class DriverSalesListRefresh {
  DriverSalesListRefresh._();

  static VoidCallback? onSalesTabSelected;

  static void request() => onSalesTabSelected?.call();
}
