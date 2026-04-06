import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatStationDebtAmount(dynamic v) {
  if (v == null) {
    return '—';
  }
  if (v is num) {
    return v.toString();
  }
  return v.toString();
}

String? formatStationDebtDateTime(BuildContext context, dynamic raw) {
  if (raw == null) {
    return null;
  }
  final String s = raw.toString();
  if (s.isEmpty) {
    return null;
  }
  try {
    final DateTime d = DateTime.parse(s);
    final String locale = Localizations.localeOf(context).toString();
    final DateTime local = d.toLocal();
    return '${DateFormat.yMMMd(locale).format(local)} ${DateFormat.Hm(locale).format(local)}';
  } on Object {
    return s;
  }
}
