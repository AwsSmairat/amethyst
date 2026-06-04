import 'package:flutter/foundation.dart';

/// تحديث عرض الملاحظات الواردة بعد إرسال ملاحظة جديدة.
class StaffNoteInboxRefresh {
  StaffNoteInboxRefresh._();

  static VoidCallback? onRefreshRequested;

  static void request() => onRefreshRequested?.call();
}
