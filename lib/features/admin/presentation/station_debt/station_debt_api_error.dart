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
  if (e.statusCode == 404 &&
      e.code == 'NOT_FOUND' &&
      (msg == 'Not found' || msg == 'Not Found')) {
    return kStationDebtApiRouteMissingMarker;
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
