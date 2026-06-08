// تمييز دين المحطة عن دين المركبة في القوائم والسداد.

import 'package:amethyst/core/station_debt/station_debt_entry_utils.dart';

export 'package:amethyst/core/station_debt/station_debt_entry_utils.dart';

bool isStationDebtEntry(Map<String, dynamic> entry) {
  if (entry['vehicleSaleId'] != null) {
    return false;
  }
  return !isVehicleDebtEntry(entry);
}
