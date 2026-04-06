import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef JsonListFetcher = Future<Map<String, dynamic>> Function();

/// يُحوّل أي خطأ من [load] إلى نص يُعرض في الواجهة (مثلاً تعريب أخطاء الـ API).
typedef JsonListErrorMapper = String Function(Object error);

/// Loads `items` from a paginated API response `{ items, pagination }`.
final class JsonListCubit extends Cubit<ListLoadState> {
  JsonListCubit(
    this._fetch, {
    this.mapLoadError,
  }) : super(const ListLoadInitial());

  final JsonListFetcher _fetch;
  final JsonListErrorMapper? mapLoadError;

  Future<void> load() async {
    emit(const ListLoadLoading());
    try {
      final data = await _fetch();
      final raw = data['items'];
      final items = <Map<String, dynamic>>[];
      if (raw is List<dynamic>) {
        for (final dynamic e in raw) {
          if (e is Map<String, dynamic>) {
            items.add(e);
          }
        }
      }
      emit(ListLoadLoaded(items));
    } on Object catch (e) {
      final String msg = mapLoadError?.call(e) ?? e.toString();
      emit(ListLoadFailure(msg));
    }
  }
}
