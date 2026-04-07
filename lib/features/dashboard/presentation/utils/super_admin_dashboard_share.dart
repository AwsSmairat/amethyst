import 'dart:typed_data';

import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/utils/super_admin_reports_pdf.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

int _parseTotal(Object? v) {
  if (v is int) {
    return v;
  }
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

/// الخادم يعيد `total` داخل `data.pagination` (انظر `server/src/utils/response.js`).
int _parseListTotal(Map<String, dynamic> data) {
  final Object? pag = data['pagination'];
  if (pag is Map<String, dynamic>) {
    return _parseTotal(pag['total']);
  }
  return _parseTotal(data['total']);
}

/// iOS (خصوصاً iPad) يتطلب غالباً مصدر إحداثيات لورقة المشاركة وإلا يرمي فشلاً.
Rect? _sharePositionOrigin(BuildContext context) {
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final Size sz = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(sz.width / 2, sz.height / 2),
    width: 1,
    height: 1,
  );
}

Future<List<Map<String, dynamic>>> _fetchAllListItems(
  Future<Map<String, dynamic>> Function(int page) loadPage,
) async {
  const int limit = 100;
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  int page = 1;
  while (page <= 100) {
    final Map<String, dynamic> data = await loadPage(page);
    final Object? raw = data['items'];
    if (raw is! List<dynamic>) {
      break;
    }
    final List<Map<String, dynamic>> chunk = <Map<String, dynamic>>[];
    for (final dynamic e in raw) {
      if (e is Map<String, dynamic>) {
        chunk.add(e);
      } else if (e is Map) {
        chunk.add(Map<String, dynamic>.from(e));
      }
    }
    out.addAll(chunk);
    final int total = _parseListTotal(data);
    if (out.length >= total || chunk.length < limit) {
      break;
    }
    page++;
  }
  return out;
}

Future<void> shareSuperAdminExpensesReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  try {
    final List<Map<String, dynamic>> items = await _fetchAllListItems(
      (int page) => api.listExpenses(page: page, limit: 100),
    );
    if (!context.mounted) {
      return;
    }
    final Uint8List bytes = await buildExpensesPdf(
      expenses: items,
      l10n: l10n,
    );
    if (!context.mounted) {
      return;
    }
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'expenses-report.pdf',
      subject: l10n.expenses,
      bounds: _sharePositionOrigin(context) ??
          Rect.fromLTWH(0, 0, 1, 1),
    );
  } on Object catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printOverviewShareFailed)),
      );
    }
  }
}

Future<void> shareSuperAdminStationSalesReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  try {
    final List<Map<String, dynamic>> items = await _fetchAllListItems(
      (int page) => api.listStationSales(page: page, limit: 100),
    );
    if (!context.mounted) {
      return;
    }
    final Uint8List bytes = await buildStationSalesPdf(
      sales: items,
      l10n: l10n,
    );
    if (!context.mounted) {
      return;
    }
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'station-sales.pdf',
      subject: l10n.stationSales,
      bounds: _sharePositionOrigin(context) ??
          Rect.fromLTWH(0, 0, 1, 1),
    );
  } on Object catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printOverviewShareFailed)),
      );
    }
  }
}

Future<void> shareSuperAdminStationStockReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  try {
    final List<Map<String, dynamic>> items = await _fetchAllListItems(
      (int page) => api.listProducts(page: page, limit: 100),
    );
    if (!context.mounted) {
      return;
    }
    final Uint8List bytes = await buildStationStockPdf(
      products: items,
      l10n: l10n,
    );
    if (!context.mounted) {
      return;
    }
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'station-stock.pdf',
      subject: l10n.menuStationStock,
      bounds: _sharePositionOrigin(context) ??
          Rect.fromLTWH(0, 0, 1, 1),
    );
  } on Object catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printOverviewShareFailed)),
      );
    }
  }
}
