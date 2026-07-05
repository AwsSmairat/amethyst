import 'package:amethyst/core/data/amethyst_api.dart';

/// حد أقصى لجلب القائمة دفعة واحدة — الخادم يجلب المجموعة كاملة ثم يقطّعها.
const int kApiListFetchMaxLimit = 5000;

Future<List<Map<String, dynamic>>> fetchAllListItems(
  Future<Map<String, dynamic>> Function({required int page, required int limit}) listPage, {
  int limit = kApiListFetchMaxLimit,
}) async {
  final Map<String, dynamic> res = await listPage(page: 1, limit: limit);
  return (res['items'] as List<dynamic>? ?? <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

Future<List<Map<String, dynamic>>> fetchAllProducts(AmethystApi api) =>
    fetchAllListItems(
      ({required int page, required int limit}) =>
          api.listProducts(page: page, limit: limit),
    );

Future<List<Map<String, dynamic>>> fetchAllVehicles(AmethystApi api) =>
    fetchAllListItems(
      ({required int page, required int limit}) =>
          api.listVehicles(page: page, limit: limit),
    );

Future<List<Map<String, dynamic>>> fetchAllExpenses(AmethystApi api) =>
    fetchAllListItems(
      ({required int page, required int limit}) =>
          api.listExpenses(page: page, limit: limit),
    );

Future<List<Map<String, dynamic>>> fetchAllVehicleLoads(AmethystApi api) =>
    fetchAllListItems(
      ({required int page, required int limit}) =>
          api.listVehicleLoads(page: page, limit: limit),
    );

Future<List<Map<String, dynamic>>> fetchAllStationSales(AmethystApi api) =>
    fetchAllListItems(
      ({required int page, required int limit}) =>
          api.listStationSales(page: page, limit: limit),
    );

Future<List<Map<String, dynamic>>> fetchAllVehicleSales(AmethystApi api) =>
    fetchAllVehicleSalesInRange(api);

Future<List<Map<String, dynamic>>> fetchAllStationDebtSummaryEntries(
  AmethystApi api,
) =>
    fetchAllListItems(
      ({required int page, required int limit}) =>
          api.listStationDebtEntriesForSummary(page: page, limit: limit),
    );

/// قائمة الدين المفتوحة (محطة + مركبات) — نفس مصدر شاشة قائمة الدين.
Future<List<Map<String, dynamic>>> fetchAllStationDebtEntries(AmethystApi api) =>
    fetchAllListItems(
      ({required int page, required int limit}) =>
          api.listStationDebtEntries(page: page, limit: limit),
    );

Future<List<Map<String, dynamic>>> fetchAllVehicleSalesInRange(
  AmethystApi api, {
  String? vehicleId,
  String? driverId,
  String? dateFrom,
  String? dateTo,
}) async {
  const int limit = 100;
  int page = 1;
  final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
  while (true) {
    final Map<String, dynamic> res = await api.listVehicleSales(
      page: page,
      limit: limit,
      vehicleId: vehicleId,
      driverId: driverId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    final List<Map<String, dynamic>> batch =
        (res['items'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    all.addAll(batch);
    if (batch.length < limit) {
      break;
    }
    page += 1;
    if (page > 500) {
      break;
    }
  }
  return all;
}
