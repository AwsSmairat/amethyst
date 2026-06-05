import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/prototype/ui_only.dart';

/// يُستبدَل في الواجهة برسالة `stationSaleSubmitInsufficientStock`.
const String kStationDebtInsufficientStockSubmitMarker =
    'STATION_DEBT_INSUFFICIENT_STOCK';

const String kStationDebtApiRouteMissingMarker = 'STATION_DEBT_API_ROUTE_MISSING';

const String kStationDebtForbiddenMarker = 'STATION_DEBT_FORBIDDEN';

String mapStationDebtApiException(ApiException e) {
  final String? uiOnly = uiOnlyErrorMessage(e);
  if (uiOnly != null) {
    return uiOnly;
  }
  if (e.code == 'INSUFFICIENT_STOCK') {
    return kStationDebtInsufficientStockSubmitMarker;
  }
  if (e.code == 'PERMISSION-DENIED') {
    return kStationDebtForbiddenMarker;
  }
  final String msg = e.message.trim();
  final String lower = msg.toLowerCase();
  if (e.statusCode == 403 &&
      (e.code == 'FORBIDDEN' || lower == 'forbidden')) {
    return kStationDebtForbiddenMarker;
  }
  if (e.statusCode == 404) {
    final bool isGenericNotFound = lower == 'not found' ||
        (lower.startsWith('not found') &&
            lower.length < 80 &&
            !lower.contains('unpaid') &&
            !lower.contains('product'));
    if (e.code == 'NOT_FOUND' && isGenericNotFound) {
      return kStationDebtApiRouteMissingMarker;
    }
    if (e.code == null && isGenericNotFound) {
      return kStationDebtApiRouteMissingMarker;
    }
  }
  return e.message;
}

/// لتحميل القوائم ([JsonListCubit]) عند فشل الطلب.
String mapStationDebtListLoadError(Object error) {
  return mapStationDebtSubmitError(error);
}

/// أخطاء إرسال نموذج تسجيل الدين.
String mapStationDebtSubmitError(Object error) {
  if (error is ApiException) {
    return mapStationDebtApiException(error);
  }
  return errorMessageFrom(error);
}
