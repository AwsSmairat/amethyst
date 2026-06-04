import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/l10n/app_localizations.dart';

export 'package:amethyst/core/station_balance/station_balance_catalog.dart';

/// عنوان بطاقة التسعير (رصيد المحطة + تعبئة + بيع متجر).
String productPricingRowLabel(AppLocalizations l10n, int rowIndex) {
  final String store = superAdminStorePricingRowLabel(rowIndex);
  if (store.isNotEmpty) {
    return store;
  }
  final String emptyWithFilling =
      superAdminEmptySaleWithFillingPricingRowLabel(rowIndex);
  if (emptyWithFilling.isNotEmpty) {
    return emptyWithFilling;
  }
  return switch (rowIndex) {
    kSuperAdminFillingGallonPricingExtraSlot => l10n.stationSaleProductGallon,
    kSuperAdminFillingBottlePricingExtraSlot => l10n.stationSaleProductBottle,
    kSuperAdminFillingSmallGallonPricingExtraSlot =>
      l10n.stationSaleProductSmallGallon,
    kSuperAdminFillingSmallBottlePricingExtraSlot =>
      l10n.stationSaleProductSmallBottle,
    _ => stationBalanceRowLabel(l10n, rowIndex),
  };
}

/// تسمية الصف كما في [AppLocalizations] (مطابقة لنموذج تسجيل الرصيد).
String stationBalanceRowLabel(AppLocalizations l10n, int index) {
  switch (index) {
    case 0:
      return l10n.stationBalanceField1;
    case 1:
      return l10n.stationBalanceField2;
    case 2:
      return l10n.stationBalanceField3;
    case 3:
      return l10n.stationBalanceField4;
    case 4:
      return l10n.stationBalanceField5;
    case 5:
      return l10n.stationBalanceField6;
    case 6:
      return l10n.stationBalanceField7;
    case 7:
      return l10n.stationBalanceField8;
    case 8:
      return l10n.stationBalanceField10;
    case 9:
      return l10n.stationBalanceField11;
    case 10:
      return l10n.stationBalanceField12;
    case 11:
      return l10n.stationBalanceField13;
    case 12:
      return l10n.stationBalanceField14;
    case 13:
      return l10n.stationBalanceField15;
    case 14:
      return l10n.stationBalanceField16;
    case 15:
      return l10n.stationBalanceFieldOptional;
    default:
      return '';
  }
}
