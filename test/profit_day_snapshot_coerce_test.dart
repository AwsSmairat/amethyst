import 'package:amethyst/core/expenses/profit_vehicle_expense_deduction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computeProfitDaySnapshot tolerates mixed expense rows', () {
    final Map<String, dynamic> snapshot = computeProfitDaySnapshot(
      stationSalesGross: 100,
      vehicleSalesGrossById: const <String, double>{'v1': 50},
      expenseRows: <dynamic>[
        <String, dynamic>{'amount': 10},
        5.0,
        <String, dynamic>{'amount': 3},
      ],
      stationCashBalance: 0,
      vehicleIdToNumber: const <String, String>{'v1': 'باص 1'},
      vehicleIdToDriverId: const <String, String>{'v1': 'd1'},
      driverIdToVehicleId: const <String, String>{'d1': 'v1'},
      driverCashTodayByDriverId: const <String, double>{},
      driverCashYesterdayByDriverId: const <String, double>{},
      driverCashRecordedOnDayByDriverId: const <String, Map<String, double>>{},
      dayYmd: '2026-05-21',
      todayYmd: '2026-05-21',
      yesterdayYmd: '2026-05-20',
    );

    expect(snapshot['stationSales'], 100);
    expect(snapshot['stationExpenses'], 13);
    expect(snapshot['total'], isA<num>());
  });

  test('computeProfitDaySnapshot tolerates malformed vehicle sales map', () {
    final Map<String, dynamic> snapshot = computeProfitDaySnapshot(
      stationSalesGross: 0,
      vehicleSalesGrossById: 99.0,
      expenseRows: const <Map<String, dynamic>>[],
      stationCashBalance: 0,
      vehicleIdToNumber: const <String, String>{'v1': 'باص 1'},
      vehicleIdToDriverId: const <String, String>{'v1': 'd1'},
      driverIdToVehicleId: const <String, String>{'d1': 'v1'},
      driverCashTodayByDriverId: const <String, double>{},
      driverCashYesterdayByDriverId: const <String, double>{},
      driverCashRecordedOnDayByDriverId: const <String, Map<String, double>>{},
      dayYmd: '2026-05-21',
      todayYmd: '2026-05-21',
      yesterdayYmd: '2026-05-20',
    );

    expect(snapshot['total'], isA<num>());
    final List<dynamic> vehicles = snapshot['vehicles'] as List<dynamic>;
    expect(vehicles, isNotEmpty);
    expect(vehicles.first['sales'], 0);
  });
}
