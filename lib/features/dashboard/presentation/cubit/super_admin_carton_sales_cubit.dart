import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SuperAdminCartonSalesCubit extends Cubit<DashboardLoadState> {
  SuperAdminCartonSalesCubit(this._api) : super(const DashboardLoadInitial());

  final AmethystApi _api;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get selectedMonth => _selectedMonth;

  Future<void> load({DateTime? month}) async {
    if (month != null) {
      _selectedMonth = DateTime(month.year, month.month);
    }
    emit(const DashboardLoadLoading());
    try {
      final Map<String, dynamic> data = await _api.getSuperAdminCartonSummary(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );
      emit(DashboardLoadSuccess(<String, dynamic>{
        ...data,
        '_selectedYear': _selectedMonth.year,
        '_selectedMonth': _selectedMonth.month,
      }));
    } on Object catch (e) {
      emit(DashboardLoadFailure(e.toString()));
    }
  }

  Future<void> selectCurrentMonth() => load(month: DateTime.now());

  Future<void> selectPreviousMonth() {
    final DateTime prev =
        DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    return load(month: prev);
  }

  /// أي شهر تقويمي (بما فيه أشهر مستقبلية إن رغبت بالمقارنة).
  Future<void> selectCalendarMonth(DateTime month) =>
      load(month: DateTime(month.year, month.month));
}
