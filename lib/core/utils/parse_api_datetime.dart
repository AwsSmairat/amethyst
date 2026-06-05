import 'package:amethyst/core/firebase/firestore_mappers.dart';

/// يحوّل قيمة تاريخ من الـ API (نص ISO أو [DateTime] أو Firestore Timestamp).
DateTime? parseApiDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  final DateTime? fromTimestamp = timestampToDate(value);
  if (fromTimestamp != null) {
    return fromTimestamp;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}

DateTime? parseApiDateOnly(dynamic value) {
  final DateTime? parsed = parseApiDateTime(value);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// هل يوم العملية ضمن النطاق `yyyy-MM-dd` (شامل)؟
bool apiDateMatchesRange({
  required dynamic createdAt,
  String? dateFrom,
  String? dateTo,
}) {
  final DateTime? day = parseApiDateOnly(createdAt);
  if (day == null) {
    return dateFrom == null && dateTo == null;
  }
  if (dateFrom != null && dateFrom.trim().isNotEmpty) {
    final DateTime? from = DateTime.tryParse(dateFrom.trim());
    if (from != null) {
      final DateTime fromDay = DateTime(from.year, from.month, from.day);
      if (day.isBefore(fromDay)) {
        return false;
      }
    }
  }
  if (dateTo != null && dateTo.trim().isNotEmpty) {
    final DateTime? to = DateTime.tryParse(dateTo.trim());
    if (to != null) {
      final DateTime toDay = DateTime(to.year, to.month, to.day);
      if (day.isAfter(toDay)) {
        return false;
      }
    }
  }
  return true;
}
