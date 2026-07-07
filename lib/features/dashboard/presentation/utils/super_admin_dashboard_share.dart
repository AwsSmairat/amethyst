import 'dart:typed_data';

import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/data/api_list_fetch.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/utils/super_admin_reports_pdf.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

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

Future<void> _sharePdfReport(
  BuildContext context, {
  required AppLocalizations l10n,
  required Future<Uint8List> Function() buildPdf,
  required String filename,
  required String subject,
}) async {
  try {
    final Uint8List bytes = await buildPdf();
    if (!context.mounted) {
      return;
    }
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
      subject: subject,
      bounds: _sharePositionOrigin(context) ?? Rect.fromLTWH(0, 0, 1, 1),
    );
  } on Object catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printOverviewShareFailed)),
      );
    }
  }
}

Future<void> shareSuperAdminExpensesReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  final List<Map<String, dynamic>> items = await fetchAllExpenses(api);
  if (!context.mounted) {
    return;
  }
  await _sharePdfReport(
    context,
    l10n: l10n,
    buildPdf: () => buildExpensesPdf(expenses: items, l10n: l10n),
    filename: 'expenses-report.pdf',
    subject: l10n.expenses,
  );
}

Future<void> shareSuperAdminStationSalesReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  final List<Map<String, dynamic>> items = await fetchAllStationSales(api);
  if (!context.mounted) {
    return;
  }
  await _sharePdfReport(
    context,
    l10n: l10n,
    buildPdf: () => buildStationSalesPdf(sales: items, l10n: l10n),
    filename: 'station-sales.pdf',
    subject: l10n.stationSales,
  );
}

Future<void> shareSuperAdminStationStockReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  final List<Map<String, dynamic>> items = await fetchAllProducts(api);
  if (!context.mounted) {
    return;
  }
  await _sharePdfReport(
    context,
    l10n: l10n,
    buildPdf: () => buildStationStockPdf(products: items, l10n: l10n),
    filename: 'station-stock.pdf',
    subject: l10n.menuStationStock,
  );
}

Future<void> shareSuperAdminStationDebtReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  final List<Map<String, dynamic>> items =
      await fetchAllStationDebtEntries(api);
  if (!context.mounted) {
    return;
  }
  await _sharePdfReport(
    context,
    l10n: l10n,
    buildPdf: () => buildStationDebtPdf(entries: items, l10n: l10n),
    filename: 'station-debt.pdf',
    subject: l10n.titleStationDebtList,
  );
}

Future<void> shareSuperAdminVehicleSalesReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  final List<Map<String, dynamic>> items = await fetchAllVehicleSales(api);
  if (!context.mounted) {
    return;
  }
  await _sharePdfReport(
    context,
    l10n: l10n,
    buildPdf: () => buildVehicleSalesPdf(sales: items, l10n: l10n),
    filename: 'vehicle-sales.pdf',
    subject: l10n.vehicleSales,
  );
}

Future<void> shareSuperAdminVehicleLoadsReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  final List<Map<String, dynamic>> items = await fetchAllVehicleLoads(api);
  if (!context.mounted) {
    return;
  }
  await _sharePdfReport(
    context,
    l10n: l10n,
    buildPdf: () => buildVehicleLoadsPdf(loads: items, l10n: l10n),
    filename: 'vehicle-loads.pdf',
    subject: l10n.vehicleLoads,
  );
}

Future<void> shareSuperAdminCartonReport(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final AmethystApi api = sl<AmethystApi>();
  final DateTime now = DateTime.now();
  final Map<String, dynamic> summary = await api.getSuperAdminCartonSummary(
    year: now.year,
    month: now.month,
  );
  if (!context.mounted) {
    return;
  }
  await _sharePdfReport(
    context,
    l10n: l10n,
    buildPdf: () => buildCartonSummaryPdf(
      summary: summary,
      l10n: l10n,
      year: now.year,
      month: now.month,
    ),
    filename: 'carton-summary.pdf',
    subject: l10n.printCartonSection,
  );
}
