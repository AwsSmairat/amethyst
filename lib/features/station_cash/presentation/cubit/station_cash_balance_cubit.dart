import 'package:amethyst/features/station_cash/domain/entities/station_cash_balance_snapshot.dart';
import 'package:amethyst/features/station_cash/domain/usecases/get_station_cash_snapshot_usecase.dart';
import 'package:amethyst/features/station_cash/domain/usecases/list_station_cash_entries_usecase.dart';
import 'package:amethyst/features/station_cash/domain/usecases/set_station_cash_balance_usecase.dart';
import 'package:amethyst/features/station_cash/presentation/cubit/station_cash_balance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class StationCashBalanceCubit extends Cubit<StationCashBalanceState> {
  StationCashBalanceCubit({
    required GetStationCashSnapshotUseCase getSnapshot,
    required ListStationCashEntriesUseCase listEntries,
    required SetStationCashBalanceUseCase setBalance,
  })  : _getSnapshot = getSnapshot,
        _listEntries = listEntries,
        _setBalance = setBalance,
        super(const StationCashBalanceInitial());

  final GetStationCashSnapshotUseCase _getSnapshot;
  final ListStationCashEntriesUseCase _listEntries;
  final SetStationCashBalanceUseCase _setBalance;

  Future<void> load() async {
    emit(const StationCashBalanceLoading());
    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _getSnapshot(),
        _listEntries(),
      ]);
      final StationCashBalanceSnapshot snapshot =
          results[0] as StationCashBalanceSnapshot;
      emit(
        StationCashBalanceLoaded(
          amount: snapshot.todayAmount,
          yesterdayAmount: snapshot.yesterdayAmount,
          entries: results[1] as List<Map<String, dynamic>>,
        ),
      );
    } on Object catch (e) {
      emit(StationCashBalanceFailure(e.toString()));
    }
  }

  Future<bool> submit({
    required double amount,
    String? note,
  }) async {
    final StationCashBalanceState current = state;
    if (current is! StationCashBalanceLoaded) {
      return false;
    }
    emit(
      StationCashBalanceSubmitting(
        amount: current.amount,
        yesterdayAmount: current.yesterdayAmount,
        entries: current.entries,
      ),
    );
    try {
      await _setBalance(amount: amount, note: note);
      await load();
      return true;
    } on Object catch (e) {
      emit(StationCashBalanceFailure(e.toString()));
      return false;
    }
  }
}
