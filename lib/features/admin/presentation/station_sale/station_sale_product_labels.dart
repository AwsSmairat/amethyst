import 'package:amethyst/l10n/app_localizations.dart';

import 'station_sale_entry_kind.dart';

String stationSaleProductLabel(
  StationSaleEntryKind kind,
  int index,
  AppLocalizations l10n,
) {
  if (kind == StationSaleEntryKind.emptySale) {
    return index == 0
        ? l10n.stationSaleProductGallon
        : l10n.stationSaleProductBottle;
  }
  switch (index) {
    case 0:
      return l10n.stationSaleProductGallon;
    case 1:
      return l10n.stationSaleProductBottle;
    case 2:
      return l10n.stationSaleProductMahdi;
    case 3:
      return l10n.couponProduct;
    default:
      return '';
  }
}
