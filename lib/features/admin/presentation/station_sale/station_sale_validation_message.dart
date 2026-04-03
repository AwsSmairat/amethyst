import 'package:amethyst/l10n/app_localizations.dart';

import 'station_sale_validation.dart';

String stationSaleValidationMessage(
  StationSaleValidationError error,
  AppLocalizations l10n,
) {
  switch (error) {
    case StationSaleValidationError.needLine:
      return l10n.stationSaleValidationNeedLine;
    case StationSaleValidationError.invalidRow:
      return l10n.stationSaleValidationInvalidRow;
    case StationSaleValidationError.checkPrice:
      return l10n.stationSaleValidationCheckPrice;
    case StationSaleValidationError.insufficientStock:
      return l10n.stationSaleValidationInsufficientStock;
  }
}
