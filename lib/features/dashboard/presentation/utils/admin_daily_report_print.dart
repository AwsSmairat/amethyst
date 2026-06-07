import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/features/dashboard/presentation/utils/admin_daily_report_data.dart';
import 'package:amethyst/features/dashboard/presentation/utils/admin_daily_report_pdf.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

Future<void> printAdminDailyReport(BuildContext context) async {
  final l10n = context.l10n;
  try {
    final AdminDailyReportData data = await loadAdminDailyReportData();
    if (!context.mounted) {
      return;
    }
    await Printing.layoutPdf(
      name: 'admin-daily-report.pdf',
      format: PdfPageFormat.a4,
      onLayout: (_) async => buildAdminDailyReportPdf(data: data, l10n: l10n),
    );
  } on Object catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDailyReportPrintFailed)),
      );
    }
  }
}
