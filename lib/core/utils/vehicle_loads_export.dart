import 'dart:convert';
import 'dart:io';

import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// يصدّر تحميلات **اليوم فقط** إلى ملف نصي باسم: `اسم_اليوم_dd_MM_yyyy.txt` ثم يفتح المشاركة.
Future<void> shareTodaysVehicleLoads(
  BuildContext context,
  List<Map<String, dynamic>> items,
) async {
  final DateTime today = DateTime.now();
  final List<Map<String, dynamic>> todayItems = items.where((Map<String, dynamic> m) {
    final DateTime? d = _parseLoadDate(m['loadDate']);
    return d != null && _sameDay(d, today);
  }).toList();

  if (todayItems.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.exportNoLoadsToday)),
    );
    return;
  }

  final String body = _buildExportText(context, todayItems);
  final String locale = Localizations.localeOf(context).toString();
  final String fileName = _exportFileName(today, locale);

  final Directory dir = await getTemporaryDirectory();
  final File file = File('${dir.path}/$fileName');
  await file.writeAsBytes(utf8.encode('\uFEFF$body'));

  if (!context.mounted) return;
  await Share.shareXFiles(
    <XFile>[XFile(file.path, mimeType: 'text/plain')],
    subject: fileName,
  );
}

String _exportFileName(DateTime now, String locale) {
  final String dayName = DateFormat('EEEE', locale).format(now);
  final String datePart = DateFormat('dd_MM_yyyy').format(now);
  final String safe =
      dayName.replaceAll(RegExp(r'[/\\:*?"<>|\s]+'), '_').replaceAll('__', '_');
  return '${safe}_$datePart.txt';
}

String _buildExportText(
  BuildContext context,
  List<Map<String, dynamic>> items,
) {
  final l10n = context.l10n;
  final String loc = Localizations.localeOf(context).toString();
  final DateTime now = DateTime.now();
  final String headerDate = DateFormat.yMMMEd(loc).format(now);
  final StringBuffer b = StringBuffer()
    ..writeln(l10n.titleVehicleLoads)
    ..writeln(headerDate)
    ..writeln();

  for (final Map<String, dynamic> item in items) {
    final String product = _nested(item['product'], 'name');
    final String vehicleNo = _nested(item['vehicle'], 'vehicleNumber');
    final String driver = _nested(item['driver'], 'fullName');
    final DateTime? loadDate = _parseLoadDate(item['loadDate']);
    final String dateStr = loadDate != null
        ? DateFormat.yMMMEd(loc).format(loadDate)
        : '';
    final String status = _statusAr(context, item['status']?.toString() ?? '');
    final dynamic qty = item['quantityLoaded'];

    b.writeln('---');
    b.writeln('${l10n.product}: ${product.isNotEmpty ? product : '—'}');
    if (vehicleNo.isNotEmpty) {
      b.writeln(l10n.vehicleWithNumber(vehicleNo));
    }
    if (driver.isNotEmpty) {
      b.writeln(driver);
    }
    b.writeln('${l10n.loadDate}: $dateStr');
    b.writeln('${l10n.statusLabel}: $status');
    b.writeln('${l10n.quantity}: $qty');
    b.writeln();
  }

  return b.toString();
}

String _nested(dynamic obj, String key) {
  if (obj is Map<String, dynamic>) {
    return obj[key]?.toString() ?? '';
  }
  if (obj is Map) {
    return obj[key]?.toString() ?? '';
  }
  return '';
}

DateTime? _parseLoadDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _statusAr(BuildContext context, String status) {
  final l10n = context.l10n;
  switch (status.toLowerCase()) {
    case 'open':
      return l10n.loadStatusOpen;
    case 'closed':
      return l10n.loadStatusClosed;
    default:
      return status;
  }
}
