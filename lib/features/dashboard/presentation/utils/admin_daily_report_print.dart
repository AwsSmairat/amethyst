import 'dart:io';

import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/printer/printer_exception.dart';
import 'package:amethyst/core/printer/printer_service.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/utils/admin_daily_report_data.dart';
import 'package:amethyst/features/dashboard/presentation/utils/admin_daily_report_pdf.dart';
import 'package:amethyst/features/dashboard/presentation/utils/admin_daily_report_receipt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

Future<void> printAdminDailyReport(BuildContext context) async {
  final l10n = context.l10n;
  try {
    final AdminDailyReportData data = await loadAdminDailyReportData();
    if (!context.mounted) {
      return;
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final List<int> bytes =
          await buildAdminDailyReportReceipt(data: data, l10n: l10n);
      await sl<PrinterService>().printBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.printerPrintSuccess)),
        );
      }
      return;
    }

    await Printing.layoutPdf(
      name: 'admin-daily-report.pdf',
      format: PdfPageFormat.a4,
      onLayout: (_) async => buildAdminDailyReportPdf(data: data, l10n: l10n),
    );
  } on PrinterException catch (e) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        action: e.code == PrinterErrorCode.printerNotFound
            ? SnackBarAction(
                label: l10n.printerSettingsTitle,
                onPressed: () => context.push('/admin/printer-settings'),
              )
            : null,
      ),
    );
  } on Object catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDailyReportPrintFailed)),
      );
    }
  }
}
