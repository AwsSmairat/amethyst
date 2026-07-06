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

double _readMoneyValue(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  if (raw is Map) {
    return _readMoneyValue(raw['amount']);
  }
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

double _expenseAmount(Map<String, dynamic> expense) =>
    _readMoneyValue(expense['amount']);

List<Map<String, dynamic>> _coerceMapRows(Iterable<dynamic> rows) {
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final dynamic row in rows) {
    if (row is Map<String, dynamic>) {
      out.add(row);
      continue;
    }
    if (row is Map) {
      out.add(Map<String, dynamic>.from(row));
    }
  }
  return out;
}

List<Map<String, dynamic>> _coerceExpenseRows(Iterable<dynamic> expenses) =>
    _coerceMapRows(expenses);

Map<String, double> _coerceVehicleSalesGrossById(Object? raw) {
  if (raw is! Map) {
    return const <String, double>{};
  }
  final Map<String, double> out = <String, double>{};
  for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
    final String? vehicleId = entry.key?.toString();
    if (vehicleId == null || vehicleId.isEmpty) {
      continue;
    }
    out[vehicleId] = _readMoneyValue(entry.value);
  }
  return out;
}

double _coerceStationSalesGross(Object? raw) => _readMoneyValue(raw);

Map<String, double> _coerceDayAmountMap(Object? raw) {
  if (raw is! Map) {
    return const <String, double>{};
  }
  final Map<String, double> out = <String, double>{};
  for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
    final String? key = entry.key?.toString();
    if (key == null || key.isEmpty) {
      continue;
    }
    final Object? value = entry.value;
    if (value is num) {
      out[key] = value.toDouble();
    }
  }
  return out;
}

/// مجموع المحطة = مبيعات المحطة − مصاريف المحطة + رصيد أموال المحطة.
double computeStationNetTotal({
  required double stationSales,
  required double stationExpenses,
  required double stationCashBalance,
}) =>
    stationSales - stationExpenses + stationCashBalance;

/// المجموع الكلي = مجموع المحطة + صافي جميع المركبات.
double computeProfitGrandTotal({
  required double stationNetTotal,
  required double vehiclesNetTotal,
}) =>
    stationNetTotal + vehiclesNetTotal;

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
  Iterable<dynamic> cashEntries,
) {
  final Map<String, double> out = <String, double>{};
  for (final Map<String, dynamic> entry in _coerceMapRows(cashEntries)) {
    final String? dayYmd = profitRowLocalYmd(entry['createdAt']);
    if (dayYmd == null) {
      continue;
    }
    out[dayYmd] = _readMoneyValue(entry['amount']);
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
  required Object? stationSalesGross,
  required Object? vehicleSalesGrossById,
  required Iterable<dynamic> expenseRows,
  required double stationCashBalance,
  required Map<String, String> vehicleIdToNumber,
  required Map<String, String> vehicleIdToDriverId,
  required Map<String, String> driverIdToVehicleId,
  required Map<String, double> driverCashTodayByDriverId,
  required Map<String, double> driverCashYesterdayByDriverId,
  required Map<String, Map<String, double>> driverCashRecordedOnDayByDriverId,
  String? dayYmd,
  String? todayYmd,
  String? yesterdayYmd,
  int? cashMonthYear,
  int? cashMonth,
  int? cashCurrentYear,
  int? cashCurrentMonth,
  Map<String, Map<String, double>>? driverCashRecordedByMonthByDriverId,
}) {
  final double stationSalesGrossValue =
      _coerceStationSalesGross(stationSalesGross);
  final Map<String, double> vehicleSalesById =
      _coerceVehicleSalesGrossById(vehicleSalesGrossById);
  final List<Map<String, dynamic>> safeExpenseRows =
      _coerceExpenseRows(expenseRows);
  var expenseTotalGross = 0.0;
  for (final Map<String, dynamic> row in safeExpenseRows) {
    expenseTotalGross += _expenseAmount(row);
  }
  final Map<String, double> operatingByVehicle =
      computeVehicleOperatingExpensesByVehicleId(
    expenses: safeExpenseRows,
    driverIdToVehicleId: driverIdToVehicleId,
  );
  var operatingTotal = 0.0;
  for (final double amount in operatingByVehicle.values) {
    operatingTotal += amount;
  }
  final double stationExpenses = expenseTotalGross - operatingTotal;
  final double stationNetTotal = computeStationNetTotal(
    stationSales: stationSalesGrossValue,
    stationExpenses: stationExpenses,
    stationCashBalance: stationCashBalance,
  );

  final List<String> vehicleIds = vehicleIdToNumber.keys.toList()
    ..sort(
      (String a, String b) =>
          (vehicleIdToNumber[a] ?? '').compareTo(vehicleIdToNumber[b] ?? ''),
    );

  final List<Map<String, dynamic>> vehicles = <Map<String, dynamic>>[];
  var vehiclesNetTotal = 0.0;
  var busSalesNet = 0.0;
  var bingoSalesNet = 0.0;

  for (final String vehicleId in vehicleIds) {
    final double sales = vehicleSalesById[vehicleId] ?? 0;
    final double operatingExpenses = operatingByVehicle[vehicleId] ?? 0;
    final String driverId = vehicleIdToDriverId[vehicleId] ?? '';
    final double cashBalance = cashMonthYear != null &&
            cashMonth != null &&
            cashCurrentYear != null &&
            cashCurrentMonth != null &&
            driverCashRecordedByMonthByDriverId != null
        ? resolveDriverCashBalanceForMonth(
            driverId,
            cashMonthYear,
            cashMonth,
            currentYear: cashCurrentYear,
            currentMonth: cashCurrentMonth,
            todayByDriverId: driverCashTodayByDriverId,
            recordedByMonthByDriverId: driverCashRecordedByMonthByDriverId,
          )
        : resolveDriverCashBalanceForDay(
            driverId,
            dayYmd ?? todayYmd ?? '',
            todayYmd: todayYmd ?? dayYmd ?? '',
            yesterdayYmd: yesterdayYmd ?? dayYmd ?? '',
            todayByDriverId: driverCashTodayByDriverId,
            yesterdayByDriverId: driverCashYesterdayByDriverId,
            recordedOnDayByDriverId: driverCashRecordedOnDayByDriverId,
          );
    final double netTotal = sales - operatingExpenses + cashBalance;
    vehiclesNetTotal += netTotal;
    final String vehicleNumber = vehicleIdToNumber[vehicleId] ?? vehicleId;
    switch (vehicleSalesBucketForNumber(vehicleNumber)) {
      case VehicleSalesBucket.bus:
        busSalesNet += netTotal;
      case VehicleSalesBucket.bingo:
        bingoSalesNet += netTotal;
      case VehicleSalesBucket.other:
        break;
    }
    vehicles.add(<String, dynamic>{
      'vehicleId': vehicleId,
      'vehicleNumber': vehicleNumber,
      'sales': sales,
      'operatingExpenses': operatingExpenses,
      'cashBalance': cashBalance,
      'netTotal': netTotal,
    });
  }

  final double total = computeProfitGrandTotal(
    stationNetTotal: stationNetTotal,
    vehiclesNetTotal: vehiclesNetTotal,
  );
  return <String, dynamic>{
    'stationSales': stationSalesGrossValue,
    'stationExpenses': stationExpenses,
    'stationNetTotal': stationNetTotal,
    'vehicles': vehicles,
    'busSales': busSalesNet,
    'bingoSales': bingoSalesNet,
    'expenses': stationExpenses,
    'stationCashBalance': stationCashBalance,
    'total': total,
    'revenue': stationSalesGrossValue +
        vehicleSalesById.values.fold<double>(0, (double a, double b) => a + b),
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
      read('stationCashBalance') != 0 ||
      _vehiclesHaveActivity(day['vehicles']);
}

bool _vehiclesHaveActivity(Object? raw) {
  if (raw is! List) {
    return false;
  }
  for (final Object? item in raw) {
    if (item is! Map) {
      continue;
    }
    final Map<String, dynamic> vehicle = Map<String, dynamic>.from(item);
    double read(String key) {
      final Object? value = vehicle[key];
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    if (read('sales') != 0 ||
        read('operatingExpenses') != 0 ||
        read('cashBalance') != 0) {
      return true;
    }
  }
  return false;
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
            vehicleSalesGrossById: const <String, double>{},
            expenseRows: const <Map<String, dynamic>>[],
            stationCashBalance: 0,
            vehicleIdToNumber: const <String, String>{},
            vehicleIdToDriverId: const <String, String>{},
            driverIdToVehicleId: const <String, String>{},
            driverCashTodayByDriverId: const <String, double>{},
            driverCashYesterdayByDriverId: const <String, double>{},
            driverCashRecordedOnDayByDriverId: const <String, Map<String, double>>{},
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
            vehicleSalesGrossById: const <String, double>{},
            expenseRows: const <Map<String, dynamic>>[],
            stationCashBalance: 0,
            vehicleIdToNumber: const <String, String>{},
            vehicleIdToDriverId: const <String, String>{},
            driverIdToVehicleId: const <String, String>{},
            driverCashTodayByDriverId: const <String, double>{},
            driverCashYesterdayByDriverId: const <String, double>{},
            driverCashRecordedOnDayByDriverId: const <String, Map<String, double>>{},
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
