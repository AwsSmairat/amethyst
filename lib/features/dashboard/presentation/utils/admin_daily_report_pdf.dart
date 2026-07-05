import 'dart:typed_data';

import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/station_debt/station_debt_entry_utils.dart';
import 'package:amethyst/core/utils/format_money.dart';
import 'package:amethyst/core/utils/parse_api_datetime.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_lines.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_display.dart';
import 'package:amethyst/features/dashboard/presentation/utils/admin_daily_report_data.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<Uint8List> buildAdminDailyReportPdf({
  required AdminDailyReportData data,
  required AppLocalizations l10n,
}) async {
  final pw.Font font = await PdfGoogleFonts.notoNaskhArabicRegular();
  final pw.Font fontBold = await PdfGoogleFonts.notoNaskhArabicBold();
  final String locale = 'ar';
  final NumberFormat money = NumberFormat.decimalPattern(locale);
  final String dayLabel = DateFormat.yMMMMd(locale).format(data.day);
  final String generatedAt =
      DateFormat('yyyy-MM-dd HH:mm', locale).format(DateTime.now());

  pw.Widget sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: fontBold, fontSize: 13),
          textAlign: pw.TextAlign.right,
        ),
      );

  pw.Widget summaryLine(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 10)),
            pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ),
      );

  final List<pw.TableRow> balanceRows = <pw.TableRow>[
    _pdfHeaderRow(fontBold, <String>[l10n.quantity, l10n.printColumnProduct]),
  ];
  for (final AdminBalanceRow row in data.balanceRows) {
    balanceRows.add(
      _pdfDataRow(
        font,
        <String>[
          '${row.stock}',
          stationBalanceRowLabel(l10n, row.rowIndex),
        ],
      ),
    );
  }
  if (balanceRows.length == 1) {
    balanceRows.add(_pdfDataRow(font, <String>['—', '—']));
  }

  final List<pw.TableRow> stationSaleRows = <pw.TableRow>[
    _pdfHeaderRow(
      fontBold,
      <String>[
        l10n.printColumnProduct,
        l10n.quantity,
        l10n.printColumnAmount,
        l10n.printColumnDateTime,
      ],
    ),
  ];
  if (data.stationSales.isEmpty) {
    stationSaleRows.add(_pdfDataRow(font, <String>['—', '—', '—', '—']));
  } else {
    for (final Map<String, dynamic> s in data.stationSales) {
      final Object? p = s['product'];
      final String name = p is Map<String, dynamic>
          ? catalogProductArabicDisplayLabel(p['name']?.toString())
          : '—';
      final int q = (s['quantity'] as num?)?.toInt() ?? 0;
      final double total = parseDynamicDouble(s['totalAmount']) ?? 0;
      final String created = _formatSaleTime(s['createdAt'], locale);
      stationSaleRows.add(
        _pdfDataRow(font, <String>[name, '$q', money.format(total), created]),
      );
    }
  }

  final List<pw.TableRow> vehicleSaleRows = <pw.TableRow>[
    _pdfHeaderRow(
      fontBold,
      <String>[
        l10n.printColumnProduct,
        l10n.quantity,
        l10n.printColumnAmount,
        l10n.printColumnVehicle,
        l10n.driver,
      ],
    ),
  ];
  if (data.vehicleSales.isEmpty) {
    vehicleSaleRows.add(_pdfDataRow(font, <String>['—', '—', '—', '—', '—']));
  } else {
    for (final Map<String, dynamic> s in data.vehicleSales) {
      final Object? p = s['product'];
      final String name = p is Map<String, dynamic>
          ? catalogProductArabicDisplayLabel(p['name']?.toString())
          : '—';
      final int q = (s['quantity'] as num?)?.toInt() ?? 0;
      final double total = parseDynamicDouble(s['totalAmount']) ?? 0;
      final Object? v = s['vehicle'];
      final String vehicle = v is Map<String, dynamic>
          ? (v['vehicleNumber']?.toString() ?? '—')
          : '—';
      final Object? d = s['driver'];
      final String driver = d is Map<String, dynamic>
          ? (d['fullName']?.toString() ?? '—')
          : '—';
      vehicleSaleRows.add(
        _pdfDataRow(
          font,
          <String>[name, '$q', money.format(total), vehicle, driver],
        ),
      );
    }
  }

  final List<pw.TableRow> debtRows = <pw.TableRow>[
    _pdfHeaderRow(
      fontBold,
      <String>[
        l10n.printColumnDebtor,
        l10n.printColumnDebtKind,
        l10n.printColumnProduct,
        l10n.printColumnAmount,
      ],
    ),
  ];
  if (data.debtEntriesToday.isEmpty) {
    debtRows.add(_pdfDataRow(font, <String>['—', '—', '—', '—']));
  } else {
    for (final Map<String, dynamic> e in data.debtEntriesToday) {
      final String debtor = e['debtorName']?.toString().trim() ?? '—';
      final String kind = isVehicleDebtEntry(e)
          ? l10n.stationDebtKindVehicle
          : l10n.stationDebtKindStation;
      debtRows.add(
        _pdfDataRow(
          font,
          <String>[
            debtor,
            kind,
            debtEntryProductDisplayLabel(e),
            money.format(parseDynamicDouble(e['totalAmount']) ?? 0),
          ],
        ),
      );
    }
  }

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: fontBold),
  );
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      textDirection: pw.TextDirection.rtl,
      build: (pw.Context ctx) => <pw.Widget>[
        pw.Text(
          l10n.adminDailyReportTitle,
          style: pw.TextStyle(font: fontBold, fontSize: 18),
          textAlign: pw.TextAlign.right,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$dayLabel · $generatedAt',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
          textAlign: pw.TextAlign.right,
        ),
        sectionTitle(l10n.adminDailyReportCashSection),
        summaryLine(
          l10n.stationCashBalanceTodayLabel,
          formatMoneyAmount(data.cashToday),
        ),
        summaryLine(
          l10n.stationCashBalanceYesterdayLabel,
          formatMoneyAmount(data.cashYesterday),
        ),
        sectionTitle(l10n.adminDailyReportBalanceSection),
        summaryLine(
          l10n.adminDailyReportBalanceTotalUnits,
          '${data.balanceSummary.totalUnits}',
        ),
        summaryLine(
          l10n.adminDailyReportRemainingStationStock,
          '${data.remainingStationStock}',
        ),
        summaryLine(
          l10n.adminDailyReportRemainingOnVehicles,
          '${data.remainingOnVehicles}',
        ),
        pw.SizedBox(height: 4),
        _pdfTable(
          balanceRows,
          columnWidths: <int, pw.TableColumnWidth>{
            0: const pw.FlexColumnWidth(0.8),
            1: const pw.FlexColumnWidth(2.5),
          },
        ),
        sectionTitle(l10n.adminDailyReportSalesSummarySection),
        summaryLine(
          l10n.stationInsideSales,
          formatMoneyAmount(data.stationSalesToday),
        ),
        summaryLine(
          l10n.adminVehicleSalesLabel,
          formatMoneyAmount(data.vehicleSalesToday),
        ),
        summaryLine(
          l10n.adminDailyReportTotalSalesToday,
          formatMoneyAmount(data.totalSalesToday),
        ),
        sectionTitle(l10n.adminDailyReportStationSalesSection),
        _pdfTable(
          stationSaleRows,
          columnWidths: <int, pw.TableColumnWidth>{
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(0.6),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.2),
          },
        ),
        sectionTitle(l10n.adminDailyReportVehicleSalesSection),
        _pdfTable(
          vehicleSaleRows,
          columnWidths: <int, pw.TableColumnWidth>{
            0: const pw.FlexColumnWidth(1.8),
            1: const pw.FlexColumnWidth(0.5),
            2: const pw.FlexColumnWidth(0.9),
            3: const pw.FlexColumnWidth(0.8),
            4: const pw.FlexColumnWidth(1.2),
          },
        ),
        sectionTitle(l10n.adminDailyReportDebtSection),
        summaryLine(
          l10n.adminDailyReportDebtTotalToday,
          formatMoneyAmount(data.debtTotalToday),
        ),
        _pdfTable(
          debtRows,
          columnWidths: <int, pw.TableColumnWidth>{
            0: const pw.FlexColumnWidth(1.4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.6),
            3: const pw.FlexColumnWidth(0.8),
          },
        ),
      ],
    ),
  );
  return pdf.save();
}

String _formatSaleTime(Object? createdAt, String locale) {
  final DateTime? dt = parseApiDateTime(createdAt);
  if (dt == null) {
    return '—';
  }
  return DateFormat('HH:mm', locale).format(dt);
}

pw.TableRow _pdfHeaderRow(pw.Font fontBold, List<String> cells) {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
    children: cells
        .map(
          (String s) => pw.Padding(
            padding: const pw.EdgeInsets.all(7),
            child: pw.Text(
              s,
              style: pw.TextStyle(font: fontBold, fontSize: 10),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        )
        .toList(),
  );
}

pw.TableRow _pdfDataRow(pw.Font font, List<String> cells) {
  return pw.TableRow(
    children: cells
        .map(
          (String s) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              s,
              style: pw.TextStyle(font: font, fontSize: 9),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        )
        .toList(),
  );
}

pw.Table _pdfTable(
  List<pw.TableRow> rows, {
  Map<int, pw.TableColumnWidth>? columnWidths,
}) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.4),
    columnWidths: columnWidths,
    children: rows,
  );
}
