import 'package:amethyst/core/network/api_exception.dart';

/// يُستبدَل في الواجهة برسالة `stationSaleSubmitInsufficientStock`.
const String kStationDebtInsufficientStockSubmitMarker =
    'STATION_DEBT_INSUFFICIENT_STOCK';

/// استجابة 404 «Not found» من `app.js` — المسار غير مسجّل على الخادم (غالباً نشر قديم).
const String kStationDebtApiRouteMissingMarker = 'STATION_DEBT_API_ROUTE_MISSING';

String mapStationDebtApiException(ApiException e) {
  if (e.code == 'INSUFFICIENT_STOCK') {
    return kStationDebtInsufficientStockSubmitMarker;
  }
  final String msg = e.message.trim();
  final String lower = msg.toLowerCase();
  /// 404 عام من Express بدون مسار (مثل POST /repay غير منشور على الخادم).
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
