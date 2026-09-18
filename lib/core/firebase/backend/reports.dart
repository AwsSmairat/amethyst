part of '../amethyst_firebase_backend.dart';

mixin _FirebaseReportsOps on _FirebaseReportsCoreOps {
  Future<Map<String, dynamic>> reportsProfitLoss({
    int page = 1,
    int limit = 100,
    String? dateFrom,
    String? dateTo,
  }) async {
    await _requireStaff();
    final DateTime now = DateTime.now();
    final DateTime start = parseYmd(dateFrom) != null
        ? startOfDay(parseYmd(dateFrom)!)
        : startOfDay(now);
    final DateTime end =
        parseYmd(dateTo) != null ? endOfDay(parseYmd(dateTo)!) : endOfDay(now);
    final String todayYmd = ymd(startOfDay(now));
    final String yesterdayYmd =
        ymd(startOfDay(now).subtract(const Duration(days: 1)));

    final QuerySnapshot<Map<String, dynamic>> vehiclesSnap =
        await _db.collection(FirestorePaths.vehicles).get();
    final Map<String, String> vehicleIdToNumber = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['vehicleNumber']?.toString() ?? '',
    };
    final Map<String, String> vehicleIdToDriverId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['driverId']?.toString() ?? '',
    };
    final Map<String, String> driverIdToVehicleId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        if ((doc.data()['driverId']?.toString() ?? '').isNotEmpty)
          doc.data()['driverId']!.toString(): doc.id,
    };

    final Map<String, double> stationSalesByDay = <String, double>{};
    final Map<String, Map<String, double>> vehicleGrossByDay =
        <String, Map<String, double>>{};
    final Map<String, List<Map<String, dynamic>>> expensesByDay =
        <String, List<Map<String, dynamic>>>{};

    final QuerySnapshot<Map<String, dynamic>> stationSnap = await _db
        .collection(FirestorePaths.stationSales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in stationSnap.docs) {
      profitAccumulateByDay(
        stationSalesByDay,
        profitRowLocalYmd(timestampToDate(doc.data()['createdAt'])),
        _num(doc.data()['totalAmount']),
      );
    }

    final QuerySnapshot<Map<String, dynamic>> vehicleSnap = await _db
        .collection(FirestorePaths.vehicleSales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in vehicleSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      if (!isCashVehicleSaleRow(data)) {
        continue;
      }
      final double amount = _num(data['totalAmount']);
      final String? vehicleId = data['vehicleId']?.toString();
      final String? dayYmd =
          profitRowLocalYmd(timestampToDate(data['createdAt']));
      profitAccumulateVehicleSalesByKey(
        vehicleGrossByDay,
        dayYmd,
        vehicleId,
        amount,
      );
    }

    final QuerySnapshot<Map<String, dynamic>> expensesSnap = await _db
        .collection(FirestorePaths.expenses)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in expensesSnap.docs) {
      final Map<String, dynamic> row = mapExpenseDoc(doc);
      profitAppendExpenseByDay(
        expensesByDay,
        profitRowLocalYmd(row['createdAt']),
        row,
      );
    }

    final ({double today, double yesterday}) cashSnapshot =
        await _stationCashBalanceSnapshot();
    final QuerySnapshot<Map<String, dynamic>> cashEntriesSnap = await _db
        .collection(FirestorePaths.stationCashEntries)
        .orderBy('createdAt')
        .get();
    final Map<String, double> cashRecordedOnDay = buildStationCashRecordedOnDay(
      cashEntriesSnap.docs.map(mapStationCashEntryDoc),
    );
    final ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    }) driverCash = await _driverCashProfitContext();

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
      byDay[dayYmd] = computeProfitDaySnapshot(
        stationSalesGross: stationSalesByDay[dayYmd] ?? 0,
        vehicleSalesGrossById:
            vehicleGrossByDay[dayYmd] ?? const <String, double>{},
        expenseRows: expensesByDay[dayYmd] ?? const <Map<String, dynamic>>[],
        stationCashBalance: resolveStationCashBalanceForDay(
          dayYmd,
          todayYmd: todayYmd,
          yesterdayYmd: yesterdayYmd,
          currentBalance: cashSnapshot.today,
          yesterdayBalance: cashSnapshot.yesterday,
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
      'from': start.toIso8601String(),
      'to': end.toIso8601String(),
      'profitDays': profitDays,
      'today': todayPayload,
    };
  }

  Future<Map<String, dynamic>> reportsProfitLossMonthly() async {
    await _requireStaff();
    final DateTime now = DateTime.now();
    final DateTime rangeStart = DateTime(now.year, now.month - 11, 1);
    final DateTime rangeEnd = endOfDay(DateTime(now.year, now.month + 1, 0));

    final QuerySnapshot<Map<String, dynamic>> vehiclesSnap =
        await _db.collection(FirestorePaths.vehicles).get();
    final Map<String, String> vehicleIdToNumber = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['vehicleNumber']?.toString() ?? '',
    };
    final Map<String, String> vehicleIdToDriverId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['driverId']?.toString() ?? '',
    };
    final Map<String, String> driverIdToVehicleId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        if ((doc.data()['driverId']?.toString() ?? '').isNotEmpty)
          doc.data()['driverId']!.toString(): doc.id,
    };

    final Map<String, double> stationSalesByMonth = <String, double>{};
    final Map<String, Map<String, double>> vehicleGrossByMonth =
        <String, Map<String, double>>{};
    final Map<String, List<Map<String, dynamic>>> expensesByMonth =
        <String, List<Map<String, dynamic>>>{};

    final QuerySnapshot<Map<String, dynamic>> stationSnap = await _db
        .collection(FirestorePaths.stationSales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in stationSnap.docs) {
      profitAccumulateByKey(
        stationSalesByMonth,
        profitRowLocalMonthKey(timestampToDate(doc.data()['createdAt'])),
        _num(doc.data()['totalAmount']),
      );
    }

    final QuerySnapshot<Map<String, dynamic>> vehicleSnap = await _db
        .collection(FirestorePaths.vehicleSales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in vehicleSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      if (!isCashVehicleSaleRow(data)) {
        continue;
      }
      final double amount = _num(data['totalAmount']);
      final String? vehicleId = data['vehicleId']?.toString();
      final String? monthKey =
          profitRowLocalMonthKey(timestampToDate(data['createdAt']));
      profitAccumulateVehicleSalesByKey(
        vehicleGrossByMonth,
        monthKey,
        vehicleId,
        amount,
      );
    }

    final QuerySnapshot<Map<String, dynamic>> expensesSnap = await _db
        .collection(FirestorePaths.expenses)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in expensesSnap.docs) {
      final Map<String, dynamic> row = mapExpenseDoc(doc);
      profitAppendExpenseByKey(
        expensesByMonth,
        profitRowLocalMonthKey(row['createdAt']),
        row,
      );
    }

    final ({double today, double yesterday}) cashSnapshot =
        await _stationCashBalanceSnapshot();
    final QuerySnapshot<Map<String, dynamic>> cashEntriesSnap = await _db
        .collection(FirestorePaths.stationCashEntries)
        .orderBy('createdAt')
        .get();
    final Map<String, double> cashRecordedByMonth = buildStationCashRecordedByMonth(
      cashEntriesSnap.docs.map(mapStationCashEntryDoc),
    );

    final Set<String> monthKeys = <String>{
      profitMonthKey(now.year, now.month),
      profitMonthKey(
        profitCalendarPreviousMonth(now.year, now.month).y,
        profitCalendarPreviousMonth(now.year, now.month).m,
      ),
      ...stationSalesByMonth.keys,
      ...vehicleGrossByMonth.keys,
      ...expensesByMonth.keys,
      ...cashRecordedByMonth.keys,
    };

    final ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    }) driverCash = await _driverCashProfitContext();

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
          currentBalance: cashSnapshot.today,
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

  Future<({double today, double month})> _profitKpiTotalsForDashboard({
    required DateTime dayStart,
    required DateTime dayEnd,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    final DateTime now = DateTime.now();
    final String todayYmd = ymd(startOfDay(now));
    final String yesterdayYmd =
        ymd(startOfDay(now).subtract(const Duration(days: 1)));

    final List<Object> snaps = await Future.wait<Object>(<Future<Object>>[
      _db.collection(FirestorePaths.vehicles).get(),
      _driverCashProfitContext(createdFrom: monthStart),
      _stationCashBalanceSnapshot(),
      _db
          .collection(FirestorePaths.stationCashEntries)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(monthEnd),
          )
          .get(),
      _db
          .collection(FirestorePaths.stationSales)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get(),
      _db
          .collection(FirestorePaths.vehicleSales)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get(),
      _db
          .collection(FirestorePaths.expenses)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get(),
    ]);

    final QuerySnapshot<Map<String, dynamic>> vehiclesSnap =
        snaps[0] as QuerySnapshot<Map<String, dynamic>>;
    final ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    }) driverCash = snaps[1] as ({
      Map<String, double> todayByDriverId,
      Map<String, double> yesterdayByDriverId,
      Map<String, Map<String, double>> recordedOnDayByDriverId,
      Map<String, Map<String, double>> recordedByMonthByDriverId,
    });
    final ({double today, double yesterday}) cashSnapshot =
        snaps[2] as ({double today, double yesterday});
    final QuerySnapshot<Map<String, dynamic>> cashEntriesSnap =
        snaps[3] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> stationSnap =
        snaps[4] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> vehicleSnap =
        snaps[5] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> expensesSnap =
        snaps[6] as QuerySnapshot<Map<String, dynamic>>;

    final Map<String, String> vehicleIdToNumber = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['vehicleNumber']?.toString() ?? '',
    };
    final Map<String, String> vehicleIdToDriverId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        doc.id: doc.data()['driverId']?.toString() ?? '',
    };
    final Map<String, String> driverIdToVehicleId = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in vehiclesSnap.docs)
        if ((doc.data()['driverId']?.toString() ?? '').isNotEmpty)
          doc.data()['driverId']!.toString(): doc.id,
    };

    final List<Map<String, dynamic>> cashEntries = cashEntriesSnap.docs
        .map(mapStationCashEntryDoc)
        .toList(growable: false);
    final Map<String, double> cashRecordedOnDay =
        buildStationCashRecordedOnDay(cashEntries);
    final Map<String, double> cashRecordedByMonth =
        buildStationCashRecordedByMonth(cashEntries);

    var stationSalesDay = 0.0;
    var stationSalesMonth = 0.0;
    final Map<String, double> vehicleSalesDay = <String, double>{};
    final Map<String, double> vehicleSalesMonth = <String, double>{};
    final List<Map<String, dynamic>> expenseRowsDay = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> expenseRowsMonth =
        <Map<String, dynamic>>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in stationSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      final DateTime? created = timestampToDate(data['createdAt']);
      final double amount = _num(data['totalAmount']);
      if (isInRange(created, monthStart, monthEnd)) {
        stationSalesMonth += amount;
      }
      if (isInRange(created, dayStart, dayEnd)) {
        stationSalesDay += amount;
      }
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in vehicleSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      if (!isCashVehicleSaleRow(data)) {
        continue;
      }
      final DateTime? created = timestampToDate(data['createdAt']);
      final double amount = _num(data['totalAmount']);
      final String? vehicleId = data['vehicleId']?.toString();
      if (vehicleId == null || vehicleId.isEmpty) {
        continue;
      }
      if (isInRange(created, monthStart, monthEnd)) {
        vehicleSalesMonth[vehicleId] =
            (vehicleSalesMonth[vehicleId] ?? 0) + amount;
      }
      if (isInRange(created, dayStart, dayEnd)) {
        vehicleSalesDay[vehicleId] = (vehicleSalesDay[vehicleId] ?? 0) + amount;
      }
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in expensesSnap.docs) {
      final Map<String, dynamic> row = mapExpenseDoc(doc);
      final DateTime? created = timestampToDate(row['createdAt']);
      if (isInRange(created, monthStart, monthEnd)) {
        expenseRowsMonth.add(row);
      }
      if (isInRange(created, dayStart, dayEnd)) {
        expenseRowsDay.add(row);
      }
    }

    final Map<String, dynamic> todaySnapshot = computeProfitDaySnapshot(
      stationSalesGross: stationSalesDay,
      vehicleSalesGrossById: vehicleSalesDay,
      expenseRows: expenseRowsDay,
      stationCashBalance: resolveStationCashBalanceForDay(
        todayYmd,
        todayYmd: todayYmd,
        yesterdayYmd: yesterdayYmd,
        currentBalance: cashSnapshot.today,
        yesterdayBalance: cashSnapshot.yesterday,
        cashRecordedOnDay: cashRecordedOnDay,
      ),
      vehicleIdToNumber: vehicleIdToNumber,
      vehicleIdToDriverId: vehicleIdToDriverId,
      driverIdToVehicleId: driverIdToVehicleId,
      driverCashTodayByDriverId: driverCash.todayByDriverId,
      driverCashYesterdayByDriverId: driverCash.yesterdayByDriverId,
      driverCashRecordedOnDayByDriverId: driverCash.recordedOnDayByDriverId,
      dayYmd: todayYmd,
      todayYmd: todayYmd,
      yesterdayYmd: yesterdayYmd,
    );
    final Map<String, dynamic> monthSnapshot = computeProfitDaySnapshot(
      stationSalesGross: stationSalesMonth,
      vehicleSalesGrossById: vehicleSalesMonth,
      expenseRows: expenseRowsMonth,
      stationCashBalance: resolveStationCashBalanceForMonth(
        monthStart.year,
        monthStart.month,
        currentYear: now.year,
        currentMonth: now.month,
        currentBalance: cashSnapshot.today,
        cashRecordedByMonth: cashRecordedByMonth,
      ),
      vehicleIdToNumber: vehicleIdToNumber,
      vehicleIdToDriverId: vehicleIdToDriverId,
      driverIdToVehicleId: driverIdToVehicleId,
      driverCashTodayByDriverId: driverCash.todayByDriverId,
      driverCashYesterdayByDriverId: const <String, double>{},
      driverCashRecordedOnDayByDriverId: const <String, Map<String, double>>{},
      cashMonthYear: monthStart.year,
      cashMonth: monthStart.month,
      cashCurrentYear: now.year,
      cashCurrentMonth: now.month,
      driverCashRecordedByMonthByDriverId:
          driverCash.recordedByMonthByDriverId,
      includeCashBalance: false,
    );

    return (
      today: _num(todaySnapshot['total']),
      month: _num(monthSnapshot['total']),
    );
  }

  Future<Map<String, dynamic>> reportsSalesMonthly({
    int? year,
    int? month,
  }) async {
    await _requireStaff();
    final DateTime n = DateTime.now();
    final int y = year ?? n.year;
    final int m = month ?? n.month;
    final ({DateTime start, DateTime end}) range = businessMonthRangeFor(y, m);
    final List<Object> snaps = await Future.wait<Object>(<Future<Object>>[
      _db
          .collection(FirestorePaths.stationSales)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(range.end),
          )
          .get(),
      _db
          .collection(FirestorePaths.vehicleSales)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(range.end),
          )
          .get(),
    ]);
    final QuerySnapshot<Map<String, dynamic>> stationSnap =
        snaps[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> vehicleSnap =
        snaps[1] as QuerySnapshot<Map<String, dynamic>>;

    final List<Object> hydrated = await Future.wait<Object>(<Future<Object>>[
      _mapStationSalesBatch(stationSnap.docs),
      _mapVehicleSalesBatch(vehicleSnap.docs),
    ]);
    final List<Map<String, dynamic>> stationSales =
        hydrated[0] as List<Map<String, dynamic>>;
    final List<Map<String, dynamic>> vehicleSales =
        hydrated[1] as List<Map<String, dynamic>>;

    double stationAmount = 0;
    double vehicleAmount = 0;
    for (final Map<String, dynamic> s in stationSales) {
      stationAmount += _num(s['totalAmount']);
    }
    for (final Map<String, dynamic> s in vehicleSales) {
      if (!isCashVehicleSaleRow(s)) {
        continue;
      }
      vehicleAmount += _num(s['totalAmount']);
    }
    return <String, dynamic>{
      'year': y,
      'month': m,
      'stationSales': stationSales,
      'vehicleSales': vehicleSales,
      'totals': <String, dynamic>{
        'stationAmount': stationAmount,
        'vehicleAmount': vehicleAmount,
      },
    };
  }
}
