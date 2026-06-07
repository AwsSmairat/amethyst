import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/features/station_cash/domain/entities/station_cash_balance_snapshot.dart';
import 'package:amethyst/features/station_cash/domain/repositories/station_cash_repository.dart';

final class StationCashRepositoryImpl implements StationCashRepository {
  StationCashRepositoryImpl(this._api);

  final AmethystApi _api;

  @override
  Future<double> getBalanceAmount() async {
    final StationCashBalanceSnapshot snapshot = await getBalanceSnapshot();
    return snapshot.todayAmount;
  }

  @override
  Future<StationCashBalanceSnapshot> getBalanceSnapshot() async {
    final Map<String, dynamic> data = await _api.getStationCashBalance();
    return StationCashBalanceSnapshot(
      todayAmount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      yesterdayAmount: (data['yesterdayAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listEntries({int limit = 50}) async {
    final Map<String, dynamic> page = await _api.listStationCashEntries(
      limit: limit,
    );
    final Object? items = page['items'];
    if (items is! List) {
      return const <Map<String, dynamic>>[];
    }
    return items.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<void> setBalance({
    required double amount,
    String? note,
  }) async {
    await _api.setStationCashBalance(amount: amount, note: note);
  }
}
