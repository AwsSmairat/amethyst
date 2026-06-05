import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/data/api_list_fetch.dart';
import 'package:amethyst/core/expenses/expense_category_match.dart';
import 'package:amethyst/core/firebase/firestore_mappers.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/l10n/app_localizations.dart';

/// مبالغ مصروف لبند واحد (يوم / شهر / إجمالي).
final class CategoryExpenseTotals {
  const CategoryExpenseTotals({
    this.today = 0,
    this.month = 0,
    this.allTime = 0,
  });

  final double today;
  final double month;
  final double allTime;

  CategoryExpenseTotals add({
    required double amount,
    required bool isToday,
    required bool isMonth,
  }) {
    return CategoryExpenseTotals(
      today: today + (isToday ? amount : 0),
      month: month + (isMonth ? amount : 0),
      allTime: allTime + amount,
    );
  }
}

final class ExpenseSummaryTotals {
  const ExpenseSummaryTotals({
    this.today = 0,
    this.month = 0,
    this.allTime = 0,
  });

  final double today;
  final double month;
  final double allTime;
}

DateTime? expenseRowDate(Object? v) {
  if (v == null) {
    return null;
  }
  final DateTime? fromTimestamp = timestampToDate(v);
  if (fromTimestamp != null) {
    return fromTimestamp;
  }
  if (v is DateTime) {
    return v;
  }
  return DateTime.tryParse(v.toString());
}

bool expenseIsToday(DateTime? created, DateTime now) {
  if (created == null) {
    return false;
  }
  final DateTime day = DateTime(created.year, created.month, created.day);
  final DateTime todayKey = DateTime(now.year, now.month, now.day);
  return day == todayKey;
}

bool expenseIsCurrentMonth(DateTime? created, DateTime now) {
  if (created == null) {
    return false;
  }
  return created.year == now.year && created.month == now.month;
}

/// جلب كل سجلات المصاريف دفعة واحدة.
Future<List<Map<String, dynamic>>> fetchAllExpenseRows(AmethystApi api) =>
    fetchAllExpenses(api);

ExpenseSummaryTotals summarizeExpenseRows(
  List<Map<String, dynamic>> rows, {
  DateTime? asOf,
}) {
  final DateTime now = asOf ?? DateTime.now();
  var today = 0.0;
  var month = 0.0;
  var allTime = 0.0;
  for (final Map<String, dynamic> row in rows) {
    final double amount = parseDynamicDouble(row['amount']) ?? 0;
    allTime += amount;
    final DateTime? created = expenseRowDate(row['createdAt']);
    if (expenseIsToday(created, now)) {
      today += amount;
    }
    if (expenseIsCurrentMonth(created, now)) {
      month += amount;
    }
  }
  return ExpenseSummaryTotals(today: today, month: month, allTime: allTime);
}

Map<String, CategoryExpenseTotals> summarizeExpensesByCategory({
  required List<Map<String, dynamic>> rows,
  required AppLocalizations l10n,
  required List<String> categoryKeys,
  DateTime? asOf,
}) {
  final DateTime now = asOf ?? DateTime.now();
  final Map<String, CategoryExpenseTotals> out = <String, CategoryExpenseTotals>{
    for (final String key in categoryKeys) key: const CategoryExpenseTotals(),
  };

  for (final Map<String, dynamic> row in rows) {
    final double amount = parseDynamicDouble(row['amount']) ?? 0;
    if (amount <= 0) {
      continue;
    }
    final String note = row['note']?.toString() ?? '';
    final DateTime? created = expenseRowDate(row['createdAt']);
    final bool isToday = expenseIsToday(created, now);
    final bool isMonth = expenseIsCurrentMonth(created, now);

    for (final String key in categoryKeys) {
      if (!expenseNoteMatchesCategory(note, key, l10n)) {
        continue;
      }
      out[key] = out[key]!.add(
        amount: amount,
        isToday: isToday,
        isMonth: isMonth,
      );
      break;
    }
  }
  return out;
}

/// مصاريف السائق الحالي فقط (حسب `driverId` في السجل).
List<Map<String, dynamic>> expenseRowsForDriver(
  List<Map<String, dynamic>> rows, {
  required String? driverId,
}) {
  if (driverId == null || driverId.isEmpty) {
    return rows;
  }
  return rows
      .where(
        (Map<String, dynamic> row) =>
            row['driverId']?.toString() == driverId,
      )
      .toList(growable: false);
}
