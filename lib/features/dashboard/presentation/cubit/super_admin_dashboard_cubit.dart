import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SuperAdminDashboardCubit extends Cubit<DashboardLoadState> {
  SuperAdminDashboardCubit(this._api) : super(const DashboardLoadInitial());

  final AmethystApi _api;
  bool _inFlight = false;
  Map<String, dynamic>? _cached;

  /// [showLoading]: false يحدّث البيانات في الخلفية دون إخفاء اللوحة (مهم للويب).
  Future<void> load({bool showLoading = true, bool forceRefresh = false}) async {
    if (isClosed || _inFlight) {
      return;
    }
    _inFlight = true;
    final bool hasCache = _cached != null;
    final bool showSpinner = showLoading && !hasCache;
    if (showSpinner) {
      emit(const DashboardLoadLoading());
    } else if (hasCache) {
      emit(DashboardLoadLoading(previousData: _cached));
    }
    try {
      final data = await _api
          .getDashboardSuperAdmin(
            forceRefresh: forceRefresh,
            onPartial: (Map<String, dynamic> partial) {
              if (isClosed || hasCache) {
                return;
              }
              _cached = partial;
              emit(DashboardLoadSuccess(partial));
            },
          )
          .timeout(const Duration(seconds: 45));
      if (!isClosed) {
        _cached = data;
        emit(DashboardLoadSuccess(data));
      }
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(DashboardLoadFailure(e.message));
      }
    } on Object catch (e) {
      if (!isClosed) {
        emit(DashboardLoadFailure(e.toString()));
      }
    } finally {
      _inFlight = false;
    }
  }

  void reset() {
    _cached = null;
    _inFlight = false;
    emit(const DashboardLoadInitial());
  }
}
