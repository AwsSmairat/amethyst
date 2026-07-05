import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/features/driver_cash/domain/entities/driver_cash_balance_snapshot.dart';
import 'package:amethyst/features/driver_cash/domain/repositories/driver_cash_repository.dart';

final class DriverCashRepositoryImpl implements DriverCashRepository {
  DriverCashRepositoryImpl(this._api);

  final AmethystApi _api;

  @override
  Future<DriverCashBalanceSnapshot> getBalanceSnapshot() async {
    final Map<String, dynamic> data = await _api.getDriverCashBalance();
    return DriverCashBalanceSnapshot(
      todayAmount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      yesterdayAmount: (data['yesterdayAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<void> setBalance({
    required double amount,
    String? note,
  }) async {
    await _api.setDriverCashBalance(amount: amount, note: note);
  }
}
