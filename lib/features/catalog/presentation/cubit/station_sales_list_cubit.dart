import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/data/api_list_fetch.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/di/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// مبيعات المحطة + ديون المحطة (لملخص يومي يفصل الدين عن إجمالي المبيعات).
final class StationSalesListCubit extends Cubit<ListLoadState> {
  StationSalesListCubit({AmethystApi? api})
      : _api = api ?? sl<AmethystApi>(),
        super(const ListLoadInitial());

  final AmethystApi _api;

  Future<void> load() async {
    if (isClosed) {
      return;
    }
    final bool keepVisible = state is StationSalesListLoaded;
    if (!keepVisible) {
      emit(const ListLoadLoading());
    }
    try {
      final String from = operationalLookbackDateFromYmd();
      final String to = operationalTodayYmd();
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        fetchAllStationSales(_api, dateFrom: from, dateTo: to),
        fetchAllStationDebtSummaryEntries(_api),
        fetchAllExpensesInRange(_api, dateFrom: from, dateTo: to),
      ]);
      if (isClosed) {
        return;
      }
      emit(
        StationSalesListLoaded(
          sales: results[0] as List<Map<String, dynamic>>,
          debtEntries: results[1] as List<Map<String, dynamic>>,
          expenses: results[2] as List<Map<String, dynamic>>,
        ),
      );
    } on Object catch (e) {
      if (isClosed) {
        return;
      }
      emit(ListLoadFailure(e.toString()));
    }
  }
}
