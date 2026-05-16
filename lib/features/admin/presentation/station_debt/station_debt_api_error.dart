import 'package:amethyst/core/network/api_exception.dart';

/// يُستبدَل في الواجهة برسالة `stationSaleSubmitInsufficientStock`.
const String kStationDebtInsufficientStockSubmitMarker =
    'STATION_DEBT_INSUFFICIENT_STOCK';

const String kStationDebtApiRouteMissingMarker = 'STATION_DEBT_API_ROUTE_MISSING';

const String kStationDebtForbiddenMarker = 'STATION_DEBT_FORBIDDEN';

String mapStationDebtApiException(ApiException e) {
  if (e.code == 'INSUFFICIENT_STOCK') {
    return kStationDebtInsufficientStockSubmitMarker;
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
  if (error is ApiException) {
    return mapStationDebtApiException(error);
  }
  return error.toString();
}
