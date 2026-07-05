import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/data/api_list_fetch.dart';
import 'package:amethyst/core/firebase/date_range_utils.dart';
import 'package:amethyst/core/utils/parse_api_datetime.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_lines.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_sections.dart';
import 'package:amethyst/features/station_cash/domain/entities/station_cash_balance_snapshot.dart';
import 'package:amethyst/features/station_cash/domain/usecases/get_station_cash_snapshot_usecase.dart';

final class AdminBalanceRow {
  const AdminBalanceRow({required this.rowIndex, required this.stock});

  final int rowIndex;
  final int stock;
}

final class AdminDailyReportData {
  const AdminDailyReportData({
    required this.day,
    required this.cashToday,
    required this.cashYesterday,
    required this.balanceSummary,
    required this.balanceRows,
    required this.stationSalesToday,
    required this.vehicleSalesToday,
    required this.remainingStationStock,
    required this.remainingOnVehicles,
    required this.stationSales,
    required this.vehicleSales,
    required this.debtEntriesToday,
  });

  final DateTime day;
  final double cashToday;
  final double cashYesterday;
  final StationBalanceSummary balanceSummary;
  final List<AdminBalanceRow> balanceRows;
  final double stationSalesToday;
  final double vehicleSalesToday;
  final int remainingStationStock;
  final int remainingOnVehicles;
  final List<Map<String, dynamic>> stationSales;
  final List<Map<String, dynamic>> vehicleSales;
  final List<Map<String, dynamic>> debtEntriesToday;

  double get totalSalesToday => stationSalesToday + vehicleSalesToday;

  double get debtTotalToday {
    var total = 0.0;
    for (final Map<String, dynamic> entry in debtEntriesToday) {
      final Object? raw = entry['totalAmount'];
      if (raw is num) {
        total += raw.toDouble();
      } else {
        total += double.tryParse(raw?.toString() ?? '') ?? 0;
      }
    }
    return total;
  }
}

Future<AdminDailyReportData> loadAdminDailyReportData() async {
  final AmethystApi api = sl<AmethystApi>();
  final DateTime now = DateTime.now();
  final ({DateTime start, DateTime end}) dayRange = businessDayRange(now);

  final List<Object> results = await Future.wait<Object>(<Future<Object>>[
    api.getDashboardAdmin(),
    sl<GetStationCashSnapshotUseCase>()(),
    fetchAllProducts(api),
    fetchAllListItems(
      ({required int page, required int limit}) =>
          api.listStationSales(page: page, limit: limit),
    ),
    fetchAllListItems(
      ({required int page, required int limit}) =>
          api.listVehicleSales(page: page, limit: limit),
    ),
    fetchAllStationDebtEntries(api),
  ]);

  final Map<String, dynamic> dash = results[0] as Map<String, dynamic>;
  final StationCashBalanceSnapshot cash =
      results[1] as StationCashBalanceSnapshot;
  final List<Map<String, dynamic>> products =
      results[2] as List<Map<String, dynamic>>;
  final List<Map<String, dynamic>> allStationSales =
      results[3] as List<Map<String, dynamic>>;
  final List<Map<String, dynamic>> allVehicleSales =
      results[4] as List<Map<String, dynamic>>;
  final List<Map<String, dynamic>> allDebtEntries =
      results[5] as List<Map<String, dynamic>>;

  bool isToday(dynamic createdAt) {
    final DateTime? dt = parseApiDateTime(createdAt);
    return isInRange(dt, dayRange.start, dayRange.end);
  }

  final List<Map<String, dynamic>> stationSalesToday = allStationSales
      .where((Map<String, dynamic> s) => isToday(s['createdAt']))
      .toList(growable: false);
  final List<Map<String, dynamic>> vehicleSalesToday = allVehicleSales
      .where((Map<String, dynamic> s) => isToday(s['createdAt']))
      .toList(growable: false);
  final List<Map<String, dynamic>> debtEntriesToday = allDebtEntries
      .where((Map<String, dynamic> e) => isToday(e['createdAt']))
      .toList(growable: false);

  final StationBalanceSummary summary =
      computeStationBalanceSummary(products: products);
  final List<AdminBalanceRow> balanceRows = <AdminBalanceRow>[];
  for (var i = 0; i <= kStationBalanceLastFixedRowIndex; i++) {
    final Map<String, dynamic>? match = resolveStationBalanceProduct(
      products: products,
      rowIndex: i,
    );
    if (match == null) {
      continue;
    }
    balanceRows.add(
      AdminBalanceRow(
        rowIndex: i,
        stock: stationStockForBalanceRow(products: products, rowIndex: i),
      ),
    );
  }

  return AdminDailyReportData(
    day: dayRange.start,
    cashToday: cash.todayAmount,
    cashYesterday: cash.yesterdayAmount,
    balanceSummary: summary,
    balanceRows: balanceRows,
    stationSalesToday: (dash['stationSalesToday'] as num?)?.toDouble() ?? 0,
    vehicleSalesToday: (dash['vehicleSalesToday'] as num?)?.toDouble() ?? 0,
    remainingStationStock:
        (dash['remainingStationStock'] as num?)?.toInt() ?? 0,
    remainingOnVehicles: (dash['remainingOnVehicles'] as num?)?.toInt() ?? 0,
    stationSales: stationSalesToday,
    vehicleSales: vehicleSalesToday,
    debtEntriesToday: debtEntriesToday,
  );
}
