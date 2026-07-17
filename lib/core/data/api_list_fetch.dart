import 'package:amethyst/core/data/amethyst_api.dart';

/// حجم صفحة الجلب — يطابق سقف `_paginate` في الـ backend (حد أقصى 100).
const int kApiListFetchPageLimit = 100;

/// سقف أمان لعدد الصفحات حتى لا تعلق الحلقة عند بيانات تالفة.
const int kApiListFetchMaxPages = 500;

/// يجلب **كل** عناصر القائمة عبر الصفحات (لأن السيرفر يقطع كل طلب عند 100).
Future<List<Map<String, dynamic>>> fetchAllListItems(
  Future<Map<String, dynamic>> Function({required int page, required int limit})
      listPage, {
  int limit = kApiListFetchPageLimit,
}) async {
  final int pageLimit = limit.clamp(1, kApiListFetchPageLimit);
  final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
  for (int page = 1; page <= kApiListFetchMaxPages; page++) {
    final Map<String, dynamic> res = await listPage(
      page: page,
      limit: pageLimit,
    );
    final List<Map<String, dynamic>> batch =
        (res['items'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    all.addAll(batch);
    if (batch.length < pageLimit) {
      break;
    }
    final Object? totalRaw = res['total'];
    final int? total = totalRaw is int
        ? totalRaw
        : totalRaw is num
            ? totalRaw.toInt()
            : null;
    if (total != null && all.length >= total) {
      break;
    }
  }
  return all;
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
  const int limit = kApiListFetchPageLimit;
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
    if (page > kApiListFetchMaxPages) {
      break;
    }
  }
  return all;
}
