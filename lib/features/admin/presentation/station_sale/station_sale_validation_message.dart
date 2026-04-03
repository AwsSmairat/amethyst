import 'package:amethyst/l10n/app_localizations.dart';

import 'station_sale_validation.dart';

String stationSaleValidationMessage(
  StationSaleValidationError error,
  AppLocalizations l10n,
) {
  switch (error) {
    case StationSaleValidationError.needLine:
      return l10n.vehicleLoadNeedOneLine;
    case StationSaleValidationError.invalidRow:
      return l10n.vehicleLoadInvalidRow;
    case StationSaleValidationError.checkPrice:
      return l10n.checkQtyPrice;
  }
}
