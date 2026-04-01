import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef JsonListFetcher = Future<Map<String, dynamic>> Function();

/// Loads `items` from a paginated API response `{ items, pagination }`.
final class JsonListCubit extends Cubit<ListLoadState> {
  JsonListCubit(this._fetch) : super(const ListLoadInitial());

  final JsonListFetcher _fetch;

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
      emit(ListLoadFailure(e.toString()));
    }
  }
}
