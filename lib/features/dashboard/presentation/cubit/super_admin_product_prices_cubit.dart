import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/prototype/prototype_sample_data.dart';
import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// صف تسعير سوبر أدمن: بند ثابت من [kStationPricingBalanceRowIndices] + منتج مربوط.
typedef SuperAdminPricingRow = ({
  int rowIndex,
  Map<String, dynamic>? product,
});

final class SuperAdminProductPricesCubit extends Cubit<ListLoadState> {
  SuperAdminProductPricesCubit(this._api) : super(const ListLoadInitial());

  final AmethystApi _api;

  Future<void> load() async {
    emit(const ListLoadLoading());
    try {
      PrototypeSampleData.ensurePricingCatalogProducts();
      final List<Map<String, dynamic>> catalog = await _fetchAllProducts();
      final List<SuperAdminPricingRow> rows = <SuperAdminPricingRow>[
        for (final int slot in kSuperAdminFillingSalePricingExtraSlots)
          (
            rowIndex: slot,
            product: switch (slot) {
              kSuperAdminFillingGallonPricingExtraSlot =>
                resolveFillingGallonProduct(products: catalog),
              kSuperAdminFillingBottlePricingExtraSlot =>
                resolveFillingBottleProduct(products: catalog),
              kSuperAdminFillingSmallGallonPricingExtraSlot =>
                resolveWaterSmallGallonProduct(products: catalog),
              kSuperAdminFillingSmallBottlePricingExtraSlot =>
                resolveWaterSmallBottleProduct(products: catalog),
              _ => null,
            },
          ),
        for (final int slot in kSuperAdminEmptySaleWithFillingPricingExtraSlots)
          (
            rowIndex: slot,
            product: switch (slot) {
              kSuperAdminEmptySaleWithFillingRow1PricingExtraSlot =>
                resolveEmptySaleWithFillingRow1Product(products: catalog),
              kSuperAdminEmptySaleWithFillingRow2PricingExtraSlot =>
                resolveEmptySaleWithFillingRow2Product(products: catalog),
              _ => null,
            },
          ),
        for (final int rowIndex in kStationPricingBalanceRowIndices)
          (
            rowIndex: rowIndex,
            product: resolveStationBalanceProduct(
              products: catalog,
              rowIndex: rowIndex,
            ),
          ),
        for (final int slot in kSuperAdminStoreSalePricingExtraSlots)
          (
            rowIndex: slot,
            product: switch (slot) {
              kSuperAdminStoreGallonPricingExtraSlot =>
                resolveStoreGallonSaleProduct(products: catalog),
              kSuperAdminStoreBottlePricingExtraSlot =>
                resolveStoreBottleSaleProduct(products: catalog),
              kSuperAdminStoreMahdiPricingExtraSlot =>
                resolveStoreMahdiSaleProduct(products: catalog),
              _ => null,
            },
          ),
      ];
      emit(ListLoadLoaded(_rowsToItems(rows)));
    } on Object catch (e) {
      emit(ListLoadFailure(errorMessageFrom(e)));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllProducts() async {
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    var page = 1;
    const int limit = 100;
    while (true) {
      final Map<String, dynamic> res =
          await _api.listProducts(page: page, limit: limit);
      final List<Map<String, dynamic>> items =
          (res['items'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      all.addAll(items);
      final int total = switch (res['total']) {
        final int t => t,
        final num t => t.toInt(),
        _ => all.length,
      };
      if (items.length < limit || all.length >= total) {
        break;
      }
      page++;
    }
    return all;
  }

  List<Map<String, dynamic>> _rowsToItems(List<SuperAdminPricingRow> rows) {
    return rows
        .map(
          (SuperAdminPricingRow r) => <String, dynamic>{
            'rowIndex': r.rowIndex,
            'product': r.product,
          },
        )
        .toList(growable: false);
  }

  Future<String?> linkPricingRow(int rowIndex) async {
    try {
      switch (rowIndex) {
        case kSuperAdminFillingGallonPricingExtraSlot:
          PrototypeSampleData.ensureFillingGallonProduct();
          break;
        case kSuperAdminFillingBottlePricingExtraSlot:
          PrototypeSampleData.ensureFillingBottleProduct();
          break;
        case kSuperAdminFillingSmallGallonPricingExtraSlot:
          PrototypeSampleData.ensureWaterSmallGallonProduct();
          break;
        case kSuperAdminFillingSmallBottlePricingExtraSlot:
          PrototypeSampleData.ensureWaterSmallBottleProduct();
          break;
        case kSuperAdminEmptySaleWithFillingRow1PricingExtraSlot:
          PrototypeSampleData.ensureEmptySaleWithFillingRow1Product();
          break;
        case kSuperAdminEmptySaleWithFillingRow2PricingExtraSlot:
          PrototypeSampleData.ensureEmptySaleWithFillingRow2Product();
          break;
        case kSuperAdminStoreGallonPricingExtraSlot:
          PrototypeSampleData.ensureStoreGallonSaleProduct();
          break;
        case kSuperAdminStoreBottlePricingExtraSlot:
          PrototypeSampleData.ensureStoreBottleSaleProduct();
          break;
        case kSuperAdminStoreMahdiPricingExtraSlot:
          PrototypeSampleData.ensureStoreMahdiSaleProduct();
          break;
        default:
          await _api.upsertStationBalanceRowStock(
            rowIndex: rowIndex,
            stationStock: 0,
          );
      }
      await load();
      return null;
    } on Object catch (e) {
      return errorMessageFrom(e);
    }
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
