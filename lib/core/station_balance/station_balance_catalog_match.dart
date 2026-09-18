part of 'station_balance_catalog.dart';

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

/// مطابقة مرنة بين اسم منتج في الكتالوج/الحمولة واسم قالب الواجهة.
bool stationBalanceProductNamesMatch(String dbName, String candidate) =>
    _stationBalanceNamesMatch(dbName, candidate);

bool _isCouponBookLabel(String normalized) =>
    normalized.contains('coupon') || normalized.contains('كوبون');

bool _nameIndicatesSmallSize(String normalized) =>
    normalized.contains('صغير') ||
    normalized.contains('small') ||
    normalized.contains('صغيرة');

bool _nameIndicatesEmpty(String normalized) =>
    normalized.contains('empty') ||
    normalized.contains('فارغ') ||
    normalized.contains('فاضي') ||
    normalized.contains('فارغه');

/// يمنع خلط «ج فارغ» مع «ج صغير فارغ» ونحوها عند التطابق الجزئي.
bool _stationBalanceSizeClassConflict(String a, String b) {
  if (a == b) {
    return false;
  }
  return _nameIndicatesSmallSize(a) != _nameIndicatesSmallSize(b);
}

/// يمنع اعتبار «Empty Gallon» مثل «Gallon» أو «Water Gallon».
bool _stationBalanceEmptyClassConflict(String a, String b) {
  if (a == b) {
    return false;
  }
  return _nameIndicatesEmpty(a) != _nameIndicatesEmpty(b);
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
  // لا تطابق جزئي بين «Coupon» و«Coupon 2/3» أو «كوبون ٢٤» و«كوبون ٢».
  if (_isCouponBookLabel(a) || _isCouponBookLabel(b)) {
    return false;
  }
  // أسماء طويلة قد تختلف بلاحقة (مثل "ق سعودي — مخزن")
  if (a.length >= 6 && b.length >= 6 && (a.contains(b) || b.contains(a))) {
    if (_stationBalanceSizeClassConflict(a, b)) {
      return false;
    }
    if (_stationBalanceEmptyClassConflict(a, b)) {
      return false;
    }
    return true;
  }
  return false;
}

int _stationBalanceMatchScore(String dbName, String candidate) {
  if (!_stationBalanceNamesMatch(dbName, candidate)) {
    return 0;
  }
  return normalizeStationBalanceProductName(candidate).length;
}

Map<String, dynamic>? _resolveStationBalanceProductFromPool({
  required List<Map<String, dynamic>> pool,
  required List<String> candidates,
}) {
  Map<String, dynamic>? best;
  var bestScore = 0;
  for (final String c in candidates) {
    if (c.trim().isEmpty) {
      continue;
    }
    for (final Map<String, dynamic> p in pool) {
      final String n = p['name']?.toString() ?? '';
      final int score = _stationBalanceMatchScore(n, c);
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }
  }
  return best;
}

/// يعيد أول منتج نشط يطابق أحد الأسماء المرشّحة (أو منتج معطّل إن لم يوجد نشط).
Map<String, dynamic>? resolveProductByNameCandidates({
  required List<Map<String, dynamic>> products,
  required List<String> candidates,
}) {
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
  return _resolveStationBalanceProductFromPool(
    pool: products,
    candidates: candidates,
  );
}

/// مجموع `stationStock` لكل منتجات نشطة تطابق مرشّحات صف الرصيد (بدون تكرار `id`).
///
/// يُفضَّل لبند «مهدي متجر» حيث قد يوجد أكثر من اسم API (`Water Carton` و`ك مهدي`) —
/// [resolveStationBalanceProduct] يعيد مطابقة واحدة فقط وقد تكون بمخزون ٠.
int aggregateStationStockForBalanceRow({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (rowIndex < 0 ||
      rowIndex >= StationBalanceProductLookup.nameCandidates.length) {
    return 0;
  }
  final List<String> candidates =
      StationBalanceProductLookup.nameCandidates[rowIndex];
  final List<Map<String, dynamic>> active = products
      .where((Map<String, dynamic> p) => p['isActive'] != false)
      .toList(growable: false);
  final Set<String> seen = <String>{};
  var sum = 0;
  for (final Map<String, dynamic> p in active) {
    final String id = p['id']?.toString() ?? '';
    if (id.isEmpty || seen.contains(id)) {
      continue;
    }
    final String n = p['name']?.toString() ?? '';
    var matched = false;
    for (final String c in candidates) {
      if (_stationBalanceNamesMatch(n, c)) {
        matched = true;
        break;
      }
    }
    if (matched) {
      seen.add(id);
      sum += stationStockFromProductJson(p);
    }
  }
  return sum;
}

/// مخزون المنتج الأساسي لصف الرصيد (أول مطابقة) — للكوبونات وغيرها حيث لا يُجمَّع المخزون.
int stationStockForBalanceRowCanonical({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  final Map<String, dynamic>? product = resolveStationBalanceProduct(
    products: products,
    rowIndex: rowIndex,
  );
  return stationStockFromProductJson(product ?? <String, dynamic>{});
}

/// مخزون صف الرصيد للعرض والملخص — يجمّع كل منتج نشط يطابق مرشّحات الصف (بدون تكرار `id`).
int stationStockForBalanceRow({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (rowIndex < 0 ||
      rowIndex > kStationBalanceLastFixedRowIndex ||
      rowIndex >= StationBalanceProductLookup.nameCandidates.length) {
    return 0;
  }
  return aggregateStationStockForBalanceRow(
    products: products,
    rowIndex: rowIndex,
  );
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

