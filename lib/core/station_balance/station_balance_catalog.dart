/// عدد صفوف رصيد المحطة المعروضة في الواجهة (١٤ بنداً ثابتاً + صف اختياري).
const int kStationBalanceRowCount = 15;

/// آخر فهرس للبند الثابت (قبل الصف الاختياري).
const int kStationBalanceLastFixedRowIndex = 13;

/// صفوف رصيد المحطة في لوحة «أسعار المنتجات» (كل البنود الثابتة).
const List<int> kStationPricingBalanceRowIndices = <int>[
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
];

/// اسم ووحدة إنشاء المنتج في الـ API عند عدم وجوده (يتطابق مع [StationBalanceProductLookup]).
({String name, String unitType}) stationBalanceSeedSpecForRow(int rowIndex) {
  switch (rowIndex) {
    case 0:
      return (name: 'Water Carton', unitType: 'carton');
    case 1:
      return (name: 'Carton Yafa', unitType: 'carton');
    case 2:
      return (name: 'Shanta Large', unitType: 'carton');
    case 3:
      return (name: 'Shanta Medium', unitType: 'carton');
    case 4:
      return (name: 'Shanta Small', unitType: 'carton');
    case 5:
      return (name: 'Saudi Bottle', unitType: 'bottle');
    case 6:
      return (name: 'Jordanian Bottle', unitType: 'bottle');
    case 7:
      return (name: 'Empty Gallon', unitType: 'gallon');
    case 8:
      return (name: 'Bottle 10 Liter', unitType: 'bottle');
    case 9:
      return (name: 'Ground Bottle', unitType: 'bottle');
    case 10:
      return (name: 'Ground Gallon', unitType: 'gallon');
    case 11:
      return (name: 'Coupon', unitType: 'coupon');
    case 12:
      return (name: 'Coupon 2', unitType: 'coupon');
    case 13:
      return (name: 'Coupon 3', unitType: 'coupon');
    default:
      throw ArgumentError.value(
        rowIndex,
        'rowIndex',
        'use kStationPricingBalanceRowIndices only',
      );
  }
}

/// أسماء المنتج في الـ API لكل صف (يُجرى البحث بالتطابق بدون حساسية لحالة الأحرف).
abstract final class StationBalanceProductLookup {
  static const List<List<String>> nameCandidates = <List<String>>[
    <String>['Water Carton', 'Carton Mahdi', 'ك مهدي'],
    <String>['Carton Yafa', 'ك يافا', 'Yafa Carton'],
    <String>['Shanta Large', 'ش كبير', 'Sh Large', 'Large Shanta'],
    <String>['Shanta Medium', 'ش وسط', 'Sh Medium', 'Medium Shanta'],
    <String>['Shanta Small', 'ش صغير', 'Sh Small', 'Small Shanta'],
    <String>['Saudi Bottle', 'ق سعودي', 'Bottle Saudi'],
    <String>['Jordanian Bottle', 'ق اردني', 'Bottle Jordanian'],
    <String>[
      'Empty Gallon',
      'ج فارغ',
      'جالون فارغ',
      'جالون فاضي',
      'Gallon Empty',
    ],
    <String>[
      'Bottle 10 Liter',
      'ق ١٠ لتر',
      'ق 10 لتر',
      '10L Bottle',
      'Q 10 Liter',
    ],
    <String>['Ground Bottle', 'ق ارضية', 'Bottle Ground'],
    <String>['Ground Gallon', 'ج ارضية', 'Gallon Ground'],
    /// مطابقة [StationSaleApiProductNames.filling] وباقي التطبيق (كوبون ١٢ / ٢٤ / ٥٠).
    <String>['Coupon', 'دفتر كوبون ١٢', 'Coupon Book 12', 'كوبون ١٢'],
    <String>['Coupon 2', 'دفتر كوبون ٢٤', 'Coupon Book 24', 'كوبون ٢٤'],
    <String>['Coupon 3', 'دفتر كوبون ٥٠', 'Coupon Book 50', 'كوبون ٥٠'],
  ];
}

sealed class ParsedStationStockInput {
  const ParsedStationStockInput();
}

/// حقل فارغ — لا يُحدَّث مخزون هذا الصف.
final class ParsedStationStockSkip extends ParsedStationStockInput {
  const ParsedStationStockSkip();
}

/// إدخال غير صالح (ليس رقماً صحيحاً ≥ 0).
final class ParsedStationStockInvalid extends ParsedStationStockInput {
  const ParsedStationStockInvalid();
}

/// قيمة صالحة للمخزون.
final class ParsedStationStockOk extends ParsedStationStockInput {
  const ParsedStationStockOk(this.value);

  final int value;
}

/// تحليل حقل الكمية في نموذج الرصيد.
ParsedStationStockInput parseStationStockInput(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) {
    return const ParsedStationStockSkip();
  }
  final String normalized =
      t.replaceAll('٫', '.').replaceAll(',', '.').replaceAll(' ', '');
  final num? n = num.tryParse(normalized);
  if (n == null || n < 0) {
    return const ParsedStationStockInvalid();
  }
  final double d = n.toDouble();
  final int v = d.round();
  if ((d - v).abs() > 1e-9) {
    return const ParsedStationStockInvalid();
  }
  return ParsedStationStockOk(v);
}

/// تطبيع بسيط لأسماء المنتجات عند المطابقة (مسافات، أحرف خفية، حركات عربية).
String normalizeStationBalanceProductName(String raw) {
  var s = raw.trim();
  if (s.isEmpty) {
    return '';
  }
  s = s.replaceAll(
    RegExp(r'[\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]'),
    '',
  );
  s = s.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.toLowerCase();
}

bool _stationBalanceNamesMatch(String dbName, String candidate) {
  final String a = normalizeStationBalanceProductName(dbName);
  final String b = normalizeStationBalanceProductName(candidate);
  if (a.isEmpty || b.isEmpty) {
    return false;
  }
  if (a == b) {
    return true;
  }
  // أسماء طويلة قد تختلف بلاحقة (مثل "ق ١٠ لتر — مخزن")
  if (a.length >= 6 && b.length >= 6 && (a.contains(b) || b.contains(a))) {
    return true;
  }
  return false;
}

Map<String, dynamic>? _resolveStationBalanceProductFromPool({
  required List<Map<String, dynamic>> pool,
  required List<String> candidates,
}) {
  for (final String c in candidates) {
    if (c.trim().isEmpty) {
      continue;
    }
    for (final Map<String, dynamic> p in pool) {
      final String n = p['name']?.toString() ?? '';
      if (_stationBalanceNamesMatch(n, c)) {
        return p;
      }
    }
  }
  return null;
}

/// يعيد منتج المحطة المطابق للصف، أو `null` إن لم يُعثر على اسم مطابق.
Map<String, dynamic>? resolveStationBalanceProduct({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (rowIndex < 0 ||
      rowIndex > kStationBalanceLastFixedRowIndex ||
      rowIndex >= StationBalanceProductLookup.nameCandidates.length) {
    return null;
  }
  final List<String> candidates =
      StationBalanceProductLookup.nameCandidates[rowIndex];
  final List<Map<String, dynamic>> active = products
      .where((Map<String, dynamic> p) => p['isActive'] != false)
      .toList(growable: false);
  final Map<String, dynamic>? fromActive = _resolveStationBalanceProductFromPool(
    pool: active,
    candidates: candidates,
  );
  if (fromActive != null) {
    return fromActive;
  }
  // منتج موجود لكن معطّل — ما زلنا نربط الصف لتحديث المخزون من رصيد المحطة
  return _resolveStationBalanceProductFromPool(
    pool: products,
    candidates: candidates,
  );
}

int stationStockFromProductJson(Map<String, dynamic> item) {
  final Object? v = item['stationStock'] ?? item['stock'];
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
