import 'package:amethyst/features/station_cash/domain/entities/station_cash_balance_snapshot.dart';

abstract class StationCashRepository {
  Future<double> getBalanceAmount();

  Future<StationCashBalanceSnapshot> getBalanceSnapshot();

  Future<List<Map<String, dynamic>>> listEntries({int limit = 50});

  Future<void> setBalance({
    required double amount,
    String? note,
  });
}
