import 'package:amethyst/core/firebase/date_range_utils.dart';
import 'package:amethyst/core/vehicle/vehicle_kind_match.dart';

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

/// يحدد باص/بينقو لمصروف سائق (ديزل أو تصليح) حسب المركبة أو السائق.
VehicleSalesBucket? vehicleBucketForDriverOperatingExpense(
  Map<String, dynamic> expense, {
  required Map<String, String> vehicleIdToNumber,
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

  for (final Map<String, dynamic> expense in expenses) {
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

double _expenseAmount(Map<String, dynamic> expense) {
  final Object? raw = expense['amount'];
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

/// مجموع المحطة = مبيعات المحطة − مصاريف المحطة + رصيد أموال المحطة.
double computeStationNetTotal({
  required double stationSales,
  required double stationExpenses,
  required double stationCashBalance,
}) =>
    stationSales - stationExpenses + stationCashBalance;

/// المجموع الكلي = مجموع المحطة + صافي الباص + صافي البينقو.
double computeProfitGrandTotal({
  required double stationNetTotal,
  required double busSalesNet,
  required double bingoSalesNet,
}) =>
    stationNetTotal + busSalesNet + bingoSalesNet;

String? profitRowLocalYmd(Object? createdAt) {
  DateTime? at;
  if (createdAt is DateTime) {
    at = createdAt;
  } else if (createdAt != null) {
    at = DateTime.tryParse(createdAt.toString());
  }
  if (at == null) {
    return null;
  }
  final DateTime local = at.toLocal();
  return ymd(DateTime(local.year, local.month, local.day));
}

void profitAccumulateByDay(
  Map<String, double> map,
  String? dayYmd,
  double amount,
) {
  profitAccumulateByKey(map, dayYmd, amount);
}

void profitAccumulateByKey(
  Map<String, double> map,
  String? key,
  double amount,
) {
  if (key == null || key.isEmpty || amount == 0) {
    return;
  }
  map[key] = (map[key] ?? 0) + amount;
}

void profitAppendExpenseByKey(
  Map<String, List<Map<String, dynamic>>> map,
  String? key,
  Map<String, dynamic> expense,
) {
  if (key == null || key.isEmpty) {
    return;
  }
  map.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(expense);
}

void profitAppendExpenseByDay(
  Map<String, List<Map<String, dynamic>>> map,
  String? dayYmd,
  Map<String, dynamic> expense,
) {
  profitAppendExpenseByKey(map, dayYmd, expense);
}

String profitMonthKey(int year, int month) =>
    '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

String? profitRowLocalMonthKey(Object? createdAt) {
  final String? dayYmd = profitRowLocalYmd(createdAt);
  if (dayYmd == null || dayYmd.length < 7) {
    return null;
  }
  return dayYmd.substring(0, 7);
}

({int y, int m}) profitCalendarPreviousMonth(int year, int month) {
  if (month == 1) {
    return (y: year - 1, m: 12);
  }
  return (y: year, m: month - 1);
}

Map<String, double> buildStationCashRecordedByMonth(
  Iterable<Map<String, dynamic>> cashEntries,
) {
  final Map<String, double> out = <String, double>{};
  for (final Map<String, dynamic> entry in cashEntries) {
    final String? monthKey = profitRowLocalMonthKey(entry['createdAt']);
    if (monthKey == null) {
      continue;
    }
    final Object? raw = entry['amount'];
    final double amount = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '') ?? 0;
    out[monthKey] = amount;
  }
  return out;
}

double resolveStationCashBalanceForMonth(
  int year,
  int month, {
  required int currentYear,
  required int currentMonth,
  required double currentBalance,
  required Map<String, double> cashRecordedByMonth,
}) {
  if (year == currentYear && month == currentMonth) {
    return currentBalance;
  }
  return cashRecordedByMonth[profitMonthKey(year, month)] ?? 0;
}

Map<String, double> buildStationCashRecordedOnDay(
  Iterable<Map<String, dynamic>> cashEntries,
) {
  final Map<String, double> out = <String, double>{};
  for (final Map<String, dynamic> entry in cashEntries) {
    final String? dayYmd = profitRowLocalYmd(entry['createdAt']);
    if (dayYmd == null) {
      continue;
    }
    final Object? raw = entry['amount'];
    final double amount = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '') ?? 0;
    out[dayYmd] = amount;
  }
  return out;
}

double resolveStationCashBalanceForDay(
  String dayYmd, {
  required String todayYmd,
  required String yesterdayYmd,
  required double currentBalance,
  required double yesterdayBalance,
  required Map<String, double> cashRecordedOnDay,
}) {
  if (dayYmd == todayYmd) {
    return currentBalance;
  }
  if (dayYmd == yesterdayYmd) {
    return cashRecordedOnDay[yesterdayYmd] ?? yesterdayBalance;
  }
  return cashRecordedOnDay[dayYmd] ?? 0;
}

Map<String, dynamic> computeProfitDaySnapshot({
  required double stationSalesGross,
  required double busSalesGross,
  required double bingoSalesGross,
  required List<Map<String, dynamic>> expenseRows,
  required double stationCashBalance,
  required Map<String, String> vehicleIdToNumber,
  required Map<String, String> driverIdToVehicleId,
}) {
  var expenseTotalGross = 0.0;
  for (final Map<String, dynamic> row in expenseRows) {
    expenseTotalGross += _expenseAmount(row);
  }
  final ({
    double busSalesNet,
    double bingoSalesNet,
    double expensesExcludingVehicleOperating,
  }) netted = applyDriverOperatingExpenseDeductions(
    busSalesGross: busSalesGross,
    bingoSalesGross: bingoSalesGross,
    expensesGross: expenseTotalGross,
    expenses: expenseRows,
    vehicleIdToNumber: vehicleIdToNumber,
    driverIdToVehicleId: driverIdToVehicleId,
  );
  final double stationExpenses = netted.expensesExcludingVehicleOperating;
  final double stationNetTotal = computeStationNetTotal(
    stationSales: stationSalesGross,
    stationExpenses: stationExpenses,
    stationCashBalance: stationCashBalance,
  );
  final double busSales = netted.busSalesNet;
  final double bingoSales = netted.bingoSalesNet;
  final double total = computeProfitGrandTotal(
    stationNetTotal: stationNetTotal,
    busSalesNet: busSales,
    bingoSalesNet: bingoSales,
  );
  return <String, dynamic>{
    'stationSales': stationSalesGross,
    'stationExpenses': stationExpenses,
    'stationNetTotal': stationNetTotal,
    'busSales': busSales,
    'bingoSales': bingoSales,
    'expenses': stationExpenses,
    'stationCashBalance': stationCashBalance,
    'total': total,
    'revenue': stationSalesGross + busSales + bingoSales,
    'net': total,
  };
}

bool profitDayHasActivity(Map<String, dynamic> day) {
  double read(String key) {
    final Object? raw = day[key];
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  return read('stationSales') > 0 ||
      read('busSales') != 0 ||
      read('bingoSales') != 0 ||
      read('stationExpenses') > 0 ||
      read('stationCashBalance') != 0;
}

/// اليوم والأمس دائماً؛ أيام أقدم تظهر فقط إن فيها بيانات ربح.
List<Map<String, dynamic>> buildProfitDayCardsPayload(
  Map<String, Map<String, dynamic>> byDay,
  DateTime now,
) {
  final DateTime todayDate = DateTime(now.year, now.month, now.day);
  final String todayYmd = ymd(todayDate);
  final String yesterdayYmd =
      ymd(todayDate.subtract(const Duration(days: 1)));

  Map<String, dynamic> payloadFor(String dayYmd) {
    return <String, dynamic>{
      'date': dayYmd,
      ...byDay[dayYmd] ??
          computeProfitDaySnapshot(
            stationSalesGross: 0,
            busSalesGross: 0,
            bingoSalesGross: 0,
            expenseRows: const <Map<String, dynamic>>[],
            stationCashBalance: 0,
            vehicleIdToNumber: const <String, String>{},
            driverIdToVehicleId: const <String, String>{},
          ),
    };
  }

  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[
    payloadFor(todayYmd),
    payloadFor(yesterdayYmd),
  ];

  final List<String> keys = byDay.keys.toList()
    ..sort((String a, String b) => b.compareTo(a));
  for (final String key in keys) {
    if (key == todayYmd || key == yesterdayYmd) {
      continue;
    }
    final Map<String, dynamic>? day = byDay[key];
    if (day != null && profitDayHasActivity(day)) {
      out.add(<String, dynamic>{'date': key, ...day});
    }
  }
  return out;
}

bool profitPeriodHasActivity(Map<String, dynamic> period) =>
    profitDayHasActivity(period);

/// الشهر الحالي والسابق دائماً؛ أشهر أقدم تظهر فقط إن فيها بيانات ربح.
List<Map<String, dynamic>> buildProfitMonthCardsPayload(
  Map<String, Map<String, dynamic>> byMonth,
  DateTime now,
) {
  final ({int y, int m}) prev = profitCalendarPreviousMonth(now.year, now.month);
  final String currentKey = profitMonthKey(now.year, now.month);
  final String previousKey = profitMonthKey(prev.y, prev.m);

  Map<String, dynamic> payloadFor(int year, int month, String monthKey) {
    return <String, dynamic>{
      'year': year,
      'month': month,
      ...byMonth[monthKey] ??
          computeProfitDaySnapshot(
            stationSalesGross: 0,
            busSalesGross: 0,
            bingoSalesGross: 0,
            expenseRows: const <Map<String, dynamic>>[],
            stationCashBalance: 0,
            vehicleIdToNumber: const <String, String>{},
            driverIdToVehicleId: const <String, String>{},
          ),
    };
  }

  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[
    payloadFor(now.year, now.month, currentKey),
    payloadFor(prev.y, prev.m, previousKey),
  ];

  final List<String> keys = byMonth.keys.toList()
    ..sort((String a, String b) => b.compareTo(a));
  for (final String key in keys) {
    if (key == currentKey || key == previousKey) {
      continue;
    }
    final Map<String, dynamic>? month = byMonth[key];
    if (month != null && profitPeriodHasActivity(month)) {
      final List<String> parts = key.split('-');
      if (parts.length != 2) {
        continue;
      }
      final int? year = int.tryParse(parts[0]);
      final int? monthNum = int.tryParse(parts[1]);
      if (year == null || monthNum == null) {
        continue;
      }
      out.add(<String, dynamic>{
        'year': year,
        'month': monthNum,
        ...month,
      });
    }
  }
  return out;
}
