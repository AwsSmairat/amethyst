import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SuperAdminProductPricesCubit extends Cubit<ListLoadState> {
  SuperAdminProductPricesCubit(this._api) : super(const ListLoadInitial());

  final AmethystApi _api;

  Future<void> load() async {
    emit(const ListLoadLoading());
    await Future<void>.delayed(Duration.zero);
    emit(const ListLoadLoaded(<Map<String, dynamic>>[]));
  }

  Future<String?> updatePrice(String productId, double price) async {
    try {
      await _api.updateProduct(id: productId, price: price);
      await load();
      return null;
    } on Object catch (e) {
      return errorMessageFrom(e);
    }
  }

  Future<String?> createProduct({
    required String name,
    required String unitType,
    required double price,
  }) async {
    try {
      await _api.createProduct(
        name: name,
        unitType: unitType,
        price: price,
      );
      await load();
      return null;
    } on Object catch (e) {
      return errorMessageFrom(e);
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      await _api.deleteProduct(id);
      await load();
      return null;
    } on Object catch (e) {
      return errorMessageFrom(e);
    }
  }
}
