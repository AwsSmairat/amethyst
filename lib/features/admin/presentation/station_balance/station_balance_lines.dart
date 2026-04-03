export 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/l10n/app_localizations.dart';

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
      return l10n.stationBalanceField9;
    case 9:
      return l10n.stationBalanceField10;
    case 10:
      return l10n.stationBalanceField11;
    case 11:
      return l10n.stationBalanceField12;
    case 12:
      return l10n.stationBalanceField13Optional;
    default:
      return '';
  }
}
