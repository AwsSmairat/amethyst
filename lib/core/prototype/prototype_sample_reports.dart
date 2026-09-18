part of 'prototype_sample_data.dart';

mixin _PrototypeSampleReports on _PrototypeSampleDash {
  Map<String, dynamic> reportsInventory() {
    var openLoadLines = 0;
    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (load['status']?.toString() != 'closed') {
        openLoadLines++;
      }
    }
    return <String, dynamic>{
      'stationProducts': products,
      'openLoadLines': openLoadLines,
      'estimatedUnitsOnVehicles': _totalRemainingOnVehicles(),
    };
  }

  Map<String, dynamic> reportsSalesWorkingDays() {
    final Map<String, double> byDate = <String, double>{};
    void addSale(Map<String, dynamic> row) {
      final DateTime? dt = _rowDateOnly(row);
      if (dt == null) {
        return;
      }
      final String key =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      byDate[key] = (byDate[key] ?? 0) + _rowMoney(row);
    }

    for (final Map<String, dynamic> s in _stationSales) {
      addSale(s);
    }
    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (_isCashVehicleSale(vs)) {
        addSale(vs);
      }
    }

    final List<Map<String, dynamic>> days = byDate.entries
        .map(
          (MapEntry<String, double> e) => <String, dynamic>{
            'date': e.key,
            'combined': e.value,
          },
        )
        .toList(growable: false)
      ..sort(
        (Map<String, dynamic> a, Map<String, dynamic> b) =>
            (b['date'] as String).compareTo(a['date'] as String),
      );
    return <String, dynamic>{'days': days};
  }

  Map<String, dynamic> reportsProfitLoss({
    String? dateFrom,
    String? dateTo,
  }) {
    final DateTime now = _now;
    final DateTime startDay = parseYmd(dateFrom) != null
        ? startOfDay(parseYmd(dateFrom)!)
        : _today;
    final DateTime endDay =
        parseYmd(dateTo) != null ? startOfDay(parseYmd(dateTo)!) : _today;
    final String todayYmd = ymd(_today);
    final String yesterdayYmd = ymd(_today.subtract(const Duration(days: 1)));

    final Map<String, String> vehicleIdToNumber = <String, String>{
      for (final Map<String, dynamic> v in vehicles)
        v['id']?.toString() ?? '': v['vehicleNumber']?.toString() ?? '',
    };
    final Map<String, String> vehicleIdToDriverId = <String, String>{
      for (final Map<String, dynamic> v in vehicles)
        v['id']?.toString() ?? '': v['driverId']?.toString() ?? '',
    };
    final Map<String, String> driverIdToVehicleId = <String, String>{
      for (final Map<String, dynamic> v in vehicles)
        if ((v['driverId']?.toString() ?? '').isNotEmpty)
          v['driverId']!.toString(): v['id']?.toString() ?? '',
    };

    final Map<String, double> stationSalesByDay = <String, double>{};
    final Map<String, Map<String, double>> vehicleGrossByDay =
        <String, Map<String, double>>{};
    final Map<String, List<Map<String, dynamic>>> expensesByDay =
        <String, List<Map<String, dynamic>>>{};

    bool inRange(DateTime? day) {
      if (day == null) {
        return false;
      }
      final DateTime key = DateTime(day.year, day.month, day.day);
      return !key.isBefore(startDay) && !key.isAfter(endDay);
    }

    for (final Map<String, dynamic> s in _stationSales) {
      final DateTime? day = _rowDateOnly(s);
      if (!inRange(day)) {
        continue;
      }
      profitAccumulateByDay(
        stationSalesByDay,
        profitRowLocalYmd(day),
        _rowMoney(s),
      );
    }

    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (!_isCashVehicleSale(vs)) {
        continue;
      }
      final DateTime? day = _rowDateOnly(vs);
      if (!inRange(day)) {
        continue;
      }
      final double amount = _rowMoney(vs);
      final String vehicleId = vs['vehicleId']?.toString() ?? '';
      final String? dayYmd = profitRowLocalYmd(day);
      profitAccumulateVehicleSalesByKey(
        vehicleGrossByDay,
        dayYmd,
        vehicleId.isEmpty ? null : vehicleId,
        amount,
      );
    }

    for (final Map<String, dynamic> e in _expenses) {
      final DateTime? day = _rowDateOnly(e);
      if (!inRange(day)) {
        continue;
      }
      profitAppendExpenseByDay(
        expensesByDay,
        profitRowLocalYmd(day),
        Map<String, dynamic>.from(e),
      );
    }

    final List<Map<String, dynamic>> cashEntries = stationCashEntries;
    final double cashYesterday = cashEntries.isEmpty
        ? 0.0
        : (cashEntries.first['previousAmount'] as num?)?.toDouble() ?? 0.0;
    final Map<String, double> cashRecordedOnDay =
        buildStationCashRecordedOnDay(cashEntries);
    final ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    }) driverCash = driverCashProfitContext();

    final Set<String> dayKeys = <String>{
      todayYmd,
      yesterdayYmd,
      ...stationSalesByDay.keys,
      ...vehicleGrossByDay.keys,
      ...expensesByDay.keys,
      ...cashRecordedOnDay.keys,
    };

    final Map<String, Map<String, dynamic>> byDay =
        <String, Map<String, dynamic>>{};
    for (final String dayYmd in dayKeys) {
      if (dayYmd != todayYmd && dayYmd != yesterdayYmd) {
        final DateTime? parsed = parseYmd(dayYmd);
        if (parsed == null || !inRange(parsed)) {
          continue;
        }
      }
      byDay[dayYmd] = computeProfitDaySnapshot(
        stationSalesGross: stationSalesByDay[dayYmd] ?? 0,
        vehicleSalesGrossById:
            vehicleGrossByDay[dayYmd] ?? const <String, double>{},
        expenseRows: expensesByDay[dayYmd] ?? const <Map<String, dynamic>>[],
        stationCashBalance: resolveStationCashBalanceForDay(
          dayYmd,
          todayYmd: todayYmd,
          yesterdayYmd: yesterdayYmd,
          currentBalance: stationCashAmount,
          yesterdayBalance: cashYesterday,
          cashRecordedOnDay: cashRecordedOnDay,
        ),
        vehicleIdToNumber: vehicleIdToNumber,
        vehicleIdToDriverId: vehicleIdToDriverId,
        driverIdToVehicleId: driverIdToVehicleId,
        driverCashTodayByDriverId: driverCash.todayByDriverId,
        driverCashYesterdayByDriverId: driverCash.yesterdayByDriverId,
        driverCashRecordedOnDayByDriverId: driverCash.recordedOnDayByDriverId,
        dayYmd: dayYmd,
        todayYmd: todayYmd,
        yesterdayYmd: yesterdayYmd,
      );
    }

    final List<Map<String, dynamic>> profitDays =
        buildProfitDayCardsPayload(byDay, now);
    final Map<String, dynamic> todayPayload =
        byDay[todayYmd] ?? profitDays.first;

    return <String, dynamic>{
      'from': startDay.toIso8601String(),
      'to': endDay.toIso8601String(),
      'profitDays': profitDays,
      'today': todayPayload,
    };
  }

  Map<String, dynamic> reportsProfitLossMonthly() {
    final DateTime now = _now;
    final DateTime rangeStart = DateTime(now.year, now.month - 11, 1);
    final DateTime rangeEnd = DateTime(now.year, now.month + 1, 0);

    final Map<String, String> vehicleIdToNumber = <String, String>{
      for (final Map<String, dynamic> v in vehicles)
        v['id']?.toString() ?? '': v['vehicleNumber']?.toString() ?? '',
    };
    final Map<String, String> vehicleIdToDriverId = <String, String>{
      for (final Map<String, dynamic> v in vehicles)
        v['id']?.toString() ?? '': v['driverId']?.toString() ?? '',
    };
    final Map<String, String> driverIdToVehicleId = <String, String>{
      for (final Map<String, dynamic> v in vehicles)
        if ((v['driverId']?.toString() ?? '').isNotEmpty)
          v['driverId']!.toString(): v['id']?.toString() ?? '',
    };

    final Map<String, double> stationSalesByMonth = <String, double>{};
    final Map<String, Map<String, double>> vehicleGrossByMonth =
        <String, Map<String, double>>{};
    final Map<String, List<Map<String, dynamic>>> expensesByMonth =
        <String, List<Map<String, dynamic>>>{};

    bool inRange(DateTime? day) {
      if (day == null) {
        return false;
      }
      final DateTime key = DateTime(day.year, day.month, day.day);
      final DateTime start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      final DateTime end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
      return !key.isBefore(start) && !key.isAfter(end);
    }

    for (final Map<String, dynamic> s in _stationSales) {
      final DateTime? day = _rowDateOnly(s);
      if (!inRange(day)) {
        continue;
      }
      profitAccumulateByKey(
        stationSalesByMonth,
        profitRowLocalMonthKey(day),
        _rowMoney(s),
      );
    }

    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (!_isCashVehicleSale(vs)) {
        continue;
      }
      final DateTime? day = _rowDateOnly(vs);
      if (!inRange(day)) {
        continue;
      }
      final double amount = _rowMoney(vs);
      final String vehicleId = vs['vehicleId']?.toString() ?? '';
      final String? monthKey = profitRowLocalMonthKey(day);
      profitAccumulateVehicleSalesByKey(
        vehicleGrossByMonth,
        monthKey,
        vehicleId.isEmpty ? null : vehicleId,
        amount,
      );
    }

    for (final Map<String, dynamic> e in _expenses) {
      final DateTime? day = _rowDateOnly(e);
      if (!inRange(day)) {
        continue;
      }
      profitAppendExpenseByKey(
        expensesByMonth,
        profitRowLocalMonthKey(day),
        Map<String, dynamic>.from(e),
      );
    }

    final List<Map<String, dynamic>> cashEntries = stationCashEntries;
    final Map<String, double> cashRecordedByMonth =
        buildStationCashRecordedByMonth(cashEntries);
    final ({int y, int m}) prevMonth =
        profitCalendarPreviousMonth(now.year, now.month);

    final ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    }) driverCash = driverCashProfitContext();

    final Set<String> monthKeys = <String>{
      profitMonthKey(now.year, now.month),
      profitMonthKey(prevMonth.y, prevMonth.m),
      ...stationSalesByMonth.keys,
      ...vehicleGrossByMonth.keys,
      ...expensesByMonth.keys,
      ...cashRecordedByMonth.keys,
    };

    final Map<String, Map<String, dynamic>> byMonth =
        <String, Map<String, dynamic>>{};
    for (final String monthKey in monthKeys) {
      final List<String> parts = monthKey.split('-');
      if (parts.length != 2) {
        continue;
      }
      final int? year = int.tryParse(parts[0]);
      final int? month = int.tryParse(parts[1]);
      if (year == null || month == null) {
        continue;
      }
      byMonth[monthKey] = computeProfitDaySnapshot(
        stationSalesGross: stationSalesByMonth[monthKey] ?? 0,
        vehicleSalesGrossById:
            vehicleGrossByMonth[monthKey] ?? const <String, double>{},
        expenseRows:
            expensesByMonth[monthKey] ?? const <Map<String, dynamic>>[],
        stationCashBalance: resolveStationCashBalanceForMonth(
          year,
          month,
          currentYear: now.year,
          currentMonth: now.month,
          currentBalance: stationCashAmount,
          cashRecordedByMonth: cashRecordedByMonth,
        ),
        vehicleIdToNumber: vehicleIdToNumber,
        vehicleIdToDriverId: vehicleIdToDriverId,
        driverIdToVehicleId: driverIdToVehicleId,
        driverCashTodayByDriverId: driverCash.todayByDriverId,
        driverCashYesterdayByDriverId: const <String, double>{},
        driverCashRecordedOnDayByDriverId: const <String, Map<String, double>>{},
        cashMonthYear: year,
        cashMonth: month,
        cashCurrentYear: now.year,
        cashCurrentMonth: now.month,
        driverCashRecordedByMonthByDriverId:
            driverCash.recordedByMonthByDriverId,
        includeCashBalance: false,
      );
    }

    final List<Map<String, dynamic>> profitMonths =
        buildProfitMonthCardsPayload(byMonth, now);
    final String currentKey = profitMonthKey(now.year, now.month);
    final Map<String, dynamic> currentPayload =
        byMonth[currentKey] ?? profitMonths.first;

    return <String, dynamic>{
      'from': rangeStart.toIso8601String(),
      'to': rangeEnd.toIso8601String(),
      'profitMonths': profitMonths,
      'year': now.year,
      'month': now.month,
      'current': currentPayload,
    };
  }

  Map<String, dynamic> _profitSnapshotForToday() {
    return reportsProfitLoss(
      dateFrom: ymd(_today),
      dateTo: ymd(_today),
    );
  }

  Map<String, dynamic> _profitSnapshotForCurrentMonth() {
    return reportsProfitLossMonthly();
  }

  Map<String, dynamic> reportsSalesMonthly({int? year, int? month}) {
    final DateTime ref = year != null && month != null
        ? DateTime(year, month, 1)
        : DateTime(_now.year, _now.month, 1);
    final List<Map<String, dynamic>> stationRows = _stationSales
        .where(
          (Map<String, dynamic> s) =>
              _isSameCalendarMonth(_rowDateOnly(s), ref),
        )
        .map((Map<String, dynamic> s) => Map<String, dynamic>.from(s))
        .toList(growable: false);
    final List<Map<String, dynamic>> vehicleRows = _vehicleSales
        .where(
          (Map<String, dynamic> vs) =>
              _isCashVehicleSale(vs) &&
              _isSameCalendarMonth(_rowDateOnly(vs), ref),
        )
        .map((Map<String, dynamic> vs) => Map<String, dynamic>.from(vs))
        .toList(growable: false);
    var stationAmount = 0.0;
    for (final Map<String, dynamic> s in stationRows) {
      stationAmount += _rowMoney(s);
    }
    var vehicleAmount = 0.0;
    for (final Map<String, dynamic> vs in vehicleRows) {
      vehicleAmount += _rowMoney(vs);
    }
    return <String, dynamic>{
      'year': ref.year,
      'month': ref.month,
      'stationSales': stationRows,
      'vehicleSales': vehicleRows,
      'totals': <String, dynamic>{
        'stationAmount': stationAmount,
        'vehicleAmount': vehicleAmount,
      },
    };
  }
}
