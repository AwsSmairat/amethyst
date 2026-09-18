import 'package:amethyst/core/firebase/date_range_utils.dart';
import 'package:amethyst/core/vehicle/vehicle_kind_match.dart';

part 'profit_vehicle_expense_totals.dart';


/// بادئات ملاحظات مصاريف السائق — تطابق نصوص [AppLocalizations].
const String kGasolineExpenseNoteTitle = 'مصاريف ديزل';
const String kCarRepairExpenseNoteTitle = 'مصاريف تصليح السيارة';

bool expenseNoteIsDriverVehicleOperatingCost(String note) {
  return _expenseNoteHasCategoryPrefix(note, kGasolineExpenseNoteTitle) ||
      _expenseNoteHasCategoryPrefix(note, kCarRepairExpenseNoteTitle);
}

bool _expenseNoteHasCategoryPrefix(String note, String prefix) {
  final String n = note.trim();
  return n == prefix || n.startsWith('$prefix —') || n.startsWith('$prefix:');
}

/// يحدد مركبة مصروف ديزل/تصليح السائق.
String? vehicleIdForDriverOperatingExpense(
  Map<String, dynamic> expense, {
  required Map<String, String> driverIdToVehicleId,
}) {
  final String note = expense['note']?.toString() ?? '';
  if (!expenseNoteIsDriverVehicleOperatingCost(note)) {
    return null;
  }
  String? vehicleId = expense['vehicleId']?.toString();
  if (vehicleId == null || vehicleId.isEmpty) {
    final String? driverId = expense['driverId']?.toString();
    if (driverId != null && driverId.isNotEmpty) {
      vehicleId = driverIdToVehicleId[driverId];
    }
  }
  if (vehicleId == null || vehicleId.isEmpty) {
    return null;
  }
  return vehicleId;
}

/// يحدد باص/بينقو لمصروف سائق (ديزل أو تصليح) حسب المركبة أو السائق.
VehicleSalesBucket? vehicleBucketForDriverOperatingExpense(
  Map<String, dynamic> expense, {
  required Map<String, String> vehicleIdToNumber,
  required Map<String, String> driverIdToVehicleId,
}) {
  final String? vehicleId = vehicleIdForDriverOperatingExpense(
    expense,
    driverIdToVehicleId: driverIdToVehicleId,
  );
  if (vehicleId == null) {
    return null;
  }
  final String vehicleNumber = vehicleIdToNumber[vehicleId] ?? '';
  switch (vehicleSalesBucketForNumber(vehicleNumber)) {
    case VehicleSalesBucket.bus:
      return VehicleSalesBucket.bus;
    case VehicleSalesBucket.bingo:
      return VehicleSalesBucket.bingo;
    case VehicleSalesBucket.other:
      return null;
  }
}

Map<String, double> computeVehicleOperatingExpensesByVehicleId({
  required Iterable<Map<String, dynamic>> expenses,
  required Map<String, String> driverIdToVehicleId,
}) {
  final Map<String, double> byVehicle = <String, double>{};
  for (final Map<String, dynamic> expense in _coerceExpenseRows(expenses)) {
    final double amount = _expenseAmount(expense);
    if (amount <= 0) {
      continue;
    }
    final String? vehicleId = vehicleIdForDriverOperatingExpense(
      expense,
      driverIdToVehicleId: driverIdToVehicleId,
    );
    if (vehicleId == null) {
      continue;
    }
    byVehicle[vehicleId] = (byVehicle[vehicleId] ?? 0) + amount;
  }
  return byVehicle;
}

void profitAccumulateVehicleSalesByKey(
  Map<String, Map<String, double>> map,
  String? key,
  String? vehicleId,
  double amount,
) {
  if (key == null ||
      key.isEmpty ||
      vehicleId == null ||
      vehicleId.isEmpty ||
      amount == 0) {
    return;
  }
  final Map<String, double> bucket =
      map.putIfAbsent(key, () => <String, double>{});
  bucket[vehicleId] = (bucket[vehicleId] ?? 0) + amount;
}

Map<String, Map<String, double>> buildDriverCashRecordedOnDayByDriver(
  Iterable<dynamic> entries,
) {
  final Map<String, Map<String, double>> out = <String, Map<String, double>>{};
  for (final Map<String, dynamic> entry in _coerceMapRows(entries)) {
    final String? driverId = entry['driverId']?.toString();
    final String? dayYmd = profitRowLocalYmd(entry['createdAt']);
    if (driverId == null || driverId.isEmpty || dayYmd == null) {
      continue;
    }
    final double amount = _expenseAmount(entry);
    out.putIfAbsent(driverId, () => <String, double>{})[dayYmd] = amount;
  }
  return out;
}

Map<String, Map<String, double>> buildDriverCashRecordedByMonthByDriver(
  Iterable<dynamic> entries,
) {
  final Map<String, Map<String, double>> out = <String, Map<String, double>>{};
  for (final Map<String, dynamic> entry in _coerceMapRows(entries)) {
    final String? driverId = entry['driverId']?.toString();
    final String? monthKey = profitRowLocalMonthKey(entry['createdAt']);
    if (driverId == null || driverId.isEmpty || monthKey == null) {
      continue;
    }
    final double amount = _expenseAmount(entry);
    out.putIfAbsent(driverId, () => <String, double>{})[monthKey] = amount;
  }
  return out;
}

Map<String, double> buildDriverCashYesterdayByDriver(
  Iterable<dynamic> entries,
) {
  final Map<String, double> out = <String, double>{};
  final Map<String, DateTime?> latestAt = <String, DateTime?>{};
  for (final Map<String, dynamic> entry in _coerceMapRows(entries)) {
    final String? driverId = entry['driverId']?.toString();
    if (driverId == null || driverId.isEmpty) {
      continue;
    }
    final DateTime? createdAt = entry['createdAt'] is DateTime
        ? entry['createdAt'] as DateTime
        : DateTime.tryParse(entry['createdAt']?.toString() ?? '');
    final DateTime? previous = latestAt[driverId];
    if (previous == null ||
        (createdAt != null && createdAt.isAfter(previous))) {
      latestAt[driverId] = createdAt;
      out[driverId] = _readMoneyValue(entry['previousAmount']);
    }
  }
  return out;
}

double resolveDriverCashBalanceForDay(
  String driverId,
  String dayYmd, {
  required String todayYmd,
  required String yesterdayYmd,
  required Map<String, double> todayByDriverId,
  required Map<String, double> yesterdayByDriverId,
  required Map<String, Map<String, double>> recordedOnDayByDriverId,
}) {
  if (driverId.isEmpty) {
    return 0;
  }
  return resolveStationCashBalanceForDay(
    dayYmd,
    todayYmd: todayYmd,
    yesterdayYmd: yesterdayYmd,
    currentBalance: todayByDriverId[driverId] ?? 0,
    yesterdayBalance: yesterdayByDriverId[driverId] ?? 0,
    cashRecordedOnDay: _coerceDayAmountMap(recordedOnDayByDriverId[driverId]),
  );
}

double resolveDriverCashBalanceForMonth(
  String driverId,
  int year,
  int month, {
  required int currentYear,
  required int currentMonth,
  required Map<String, double> todayByDriverId,
  required Map<String, Map<String, double>> recordedByMonthByDriverId,
}) {
  if (driverId.isEmpty) {
    return 0;
  }
  return resolveStationCashBalanceForMonth(
    year,
    month,
    currentYear: currentYear,
    currentMonth: currentMonth,
    currentBalance: todayByDriverId[driverId] ?? 0,
    cashRecordedByMonth:
        _coerceDayAmountMap(recordedByMonthByDriverId[driverId]),
  );
}

/// يخصم مصاريف ديزل/تصليح السائق من مبيعات الباص والبينقو ويستبعدها من إجمالي المصاريف.
({
  double busSalesNet,
  double bingoSalesNet,
  double expensesExcludingVehicleOperating,
}) applyDriverOperatingExpenseDeductions({
  required double busSalesGross,
  required double bingoSalesGross,
  required double expensesGross,
  required Iterable<Map<String, dynamic>> expenses,
  required Map<String, String> vehicleIdToNumber,
  required Map<String, String> driverIdToVehicleId,
}) {
  var busDeduction = 0.0;
  var bingoDeduction = 0.0;
  var excludedFromExpenses = 0.0;

  for (final Map<String, dynamic> expense in _coerceExpenseRows(expenses)) {
    final double amount = _expenseAmount(expense);
    if (amount <= 0) {
      continue;
    }
    final VehicleSalesBucket? bucket = vehicleBucketForDriverOperatingExpense(
      expense,
      vehicleIdToNumber: vehicleIdToNumber,
      driverIdToVehicleId: driverIdToVehicleId,
    );
    if (bucket == null) {
      continue;
    }
    excludedFromExpenses += amount;
    switch (bucket) {
      case VehicleSalesBucket.bus:
        busDeduction += amount;
      case VehicleSalesBucket.bingo:
        bingoDeduction += amount;
      case VehicleSalesBucket.other:
        break;
    }
  }

  return (
    busSalesNet: busSalesGross - busDeduction,
    bingoSalesNet: bingoSalesGross - bingoDeduction,
    expensesExcludingVehicleOperating: expensesGross - excludedFromExpenses,
  );
}

