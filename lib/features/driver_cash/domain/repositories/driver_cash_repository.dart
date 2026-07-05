import 'package:amethyst/features/driver_cash/domain/entities/driver_cash_balance_snapshot.dart';

abstract class DriverCashRepository {
  Future<DriverCashBalanceSnapshot> getBalanceSnapshot();

  Future<void> setBalance({
    required double amount,
    String? note,
  });
}
