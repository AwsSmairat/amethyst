import 'package:amethyst/l10n/app_localizations.dart';

import 'station_sale_entry_kind.dart';

String stationSaleProductLabel(
  StationSaleEntryKind kind,
  int index,
  AppLocalizations l10n,
) {
  if (kind == StationSaleEntryKind.emptySale) {
    return switch (index) {
      0 => l10n.stationBalanceField6,
      1 => l10n.stationBalanceField7,
      2 => l10n.stationBalanceField8,
      _ => '',
    };
  }
  switch (index) {
    case 0:
      return l10n.stationSaleProductGallon;
    case 1:
      return l10n.stationSaleProductBottle;
    case 2:
      return l10n.stationSaleProductMahdi;
    case 3:
      return l10n.stationBalanceField12;
    case 4:
      return l10n.stationBalanceField13;
    case 5:
      return l10n.stationBalanceField14;
    default:
      return '';
  }
}
