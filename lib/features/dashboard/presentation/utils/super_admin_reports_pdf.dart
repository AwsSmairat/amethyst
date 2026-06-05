import 'dart:typed_data';

import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/expenses/expense_category_match.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

bool _isHiddenFromStationStockReport(String productName) {
  final String k = normalizeStationBalanceProductName(productName);
  // أصناف "متجر" لا يجب أن تظهر ضمن مخزون المحطة (تقرير المخزون).
  return k == normalizeStationBalanceProductName('جالون متجر') ||
      k == normalizeStationBalanceProductName('قاروره متجر') ||
      k == normalizeStationBalanceProductName('مهدي متجر');
}

Future<Uint8List> buildStationStockPdf({
  required List<Map<String, dynamic>> products,
  required AppLocalizations l10n,
}) async {
  final pw.Font font = await PdfGoogleFonts.notoNaskhArabicRegular();
  final pw.Font fontBold = await PdfGoogleFonts.notoNaskhArabicBold();
  final String generatedAt =
      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  final List<Map<String, dynamic>> sorted =
      List<Map<String, dynamic>>.from(products);
  sorted.sort(
    (Map<String, dynamic> a, Map<String, dynamic> b) =>
        (a['name']?.toString() ?? '')
            .toLowerCase()
            .compareTo((b['name']?.toString() ?? '').toLowerCase()),
  );

  // ربط "مهدي متجر" ضمن نفس مخزون Water Carton في التقرير (بدون صف منفصل).
  final int aggregatedWaterCartonStock = aggregateStationStockForBalanceRow(
    products: sorted,
    rowIndex: 0,
  );
  final Set<String> normalizedWaterCartonCandidates =
      StationBalanceProductLookup.nameCandidates.first
          .map(normalizeStationBalanceProductName)
          .where((e) => e.isNotEmpty)
          .toSet();

  final List<pw.TableRow> rows = <pw.TableRow>[
    _pdfHeaderRow(
      fontBold,
      <String>[
        l10n.printColumnProduct,
        l10n.printColumnUnitType,
        l10n.quantity,
      ],
    ),
  ];

  for (final Map<String, dynamic> pr in sorted) {
    if (pr['isActive'] == false) {
      continue;
    }
    final String rawName = pr['name']?.toString() ?? '—';
    if (_isHiddenFromStationStockReport(rawName)) {
      continue;
    }

    // امنع تكرار أصناف الكرتون المرتبطة: نعرض صف Water Carton فقط ونخفي البقية.
    final String normalizedName = normalizeStationBalanceProductName(rawName);
    if (normalizedWaterCartonCandidates.contains(normalizedName) &&
        rawName.trim() != 'Water Carton') {
      continue;
    }

    final Object? st = pr['stationStock'] ?? pr['stock'];
    final String stockStr = rawName.trim() == 'Water Carton'
        ? aggregatedWaterCartonStock.toString()
        : (st is int ? '$st' : (int.tryParse(st?.toString() ?? '') ?? 0).toString());
    final String displayName = catalogProductArabicDisplayLabel(rawName);
    final String ut = productUnitTypeArabicLabel(
      pr['unitType']?.toString() ?? pr['type']?.toString(),
    );
    rows.add(
      _pdfDataRow(font, <String>[displayName, ut, stockStr]),
    );
  }

  if (rows.length == 1) {
    rows.add(_pdfDataRow(font, <String>['—', '—', '—']));
  }

  return _buildPdfDocument(
    title: l10n.menuStationStock,
    subtitle: generatedAt,
    font: font,
    fontBold: fontBold,
    table: _pdfTable(
      rows,
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(0.9),
      },
    ),
  );
}

Future<Uint8List> buildStationSalesPdf({
  required List<Map<String, dynamic>> sales,
  required AppLocalizations l10n,
}) async {
  final pw.Font font = await PdfGoogleFonts.notoNaskhArabicRegular();
  final pw.Font fontBold = await PdfGoogleFonts.notoNaskhArabicBold();
  final String generatedAt =
      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  final String locale = 'ar';
  final NumberFormat money = NumberFormat.decimalPattern(locale);

  final List<pw.TableRow> rows = <pw.TableRow>[
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

  if (sales.isEmpty) {
    rows.add(_pdfDataRow(font, <String>['—', '—', '—', '—']));
  } else {
    for (final Map<String, dynamic> s in sales) {
      final Object? p = s['product'];
      final String name = p is Map<String, dynamic>
          ? catalogProductArabicDisplayLabel(p['name']?.toString())
          : '—';
      final int q = int.tryParse(s['quantity']?.toString() ?? '') ?? 0;
      final double total = parseDynamicDouble(s['totalAmount']) ?? 0;
      final String created = s['createdAt']?.toString() ?? '';
      rows.add(
        _pdfDataRow(
          font,
          <String>[name, '$q', money.format(total), created],
        ),
      );
    }
  }

  return _buildPdfDocument(
    title: l10n.stationSales,
    subtitle: generatedAt,
    font: font,
    fontBold: fontBold,
    table: _pdfTable(
      rows,
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(0.7),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(1.5),
      },
    ),
  );
}

Future<Uint8List> buildExpensesPdf({
  required List<Map<String, dynamic>> expenses,
  required AppLocalizations l10n,
}) async {
  final pw.Font font = await PdfGoogleFonts.notoNaskhArabicRegular();
  final pw.Font fontBold = await PdfGoogleFonts.notoNaskhArabicBold();
  final String generatedAt =
      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  final String locale = 'ar';
  final NumberFormat money = NumberFormat.decimalPattern(locale);

  final List<pw.TableRow> rows = <pw.TableRow>[
    _pdfHeaderRow(
      fontBold,
      <String>[
        l10n.printColumnAmount,
        l10n.printColumnVehicle,
        l10n.printColumnDateTime,
        l10n.printColumnNote,
      ],
    ),
  ];

  if (expenses.isEmpty) {
    rows.add(_pdfDataRow(font, <String>['—', '—', '—', '—']));
  } else {
    for (final Map<String, dynamic> e in expenses) {
      final String created = e['createdAt']?.toString() ?? '';
      final double amt = parseDynamicDouble(e['amount']) ?? 0;
      String note = expenseNoteArabicDisplayLabel(
        e['note']?.toString() ?? '',
        l10n,
      );
      if (note.length > 120) {
        note = '${note.substring(0, 117)}…';
      }
      final Object? v = e['vehicle'];
      String veh = '—';
      if (v is Map<String, dynamic>) {
        final String n = v['vehicleNumber']?.toString() ?? '';
        if (n.isNotEmpty) {
          veh = n;
        }
      }
      rows.add(
        _pdfDataRow(
          font,
          <String>[money.format(amt), veh, created, note.isEmpty ? '—' : note],
        ),
      );
    }
  }

  return _buildPdfDocument(
    title: l10n.expenses,
    subtitle: generatedAt,
    font: font,
    fontBold: fontBold,
    table: _pdfTable(
      rows,
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(2.2),
      },
    ),
  );
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

Future<Uint8List> _buildPdfDocument({
  required String title,
  required String subtitle,
  required pw.Font font,
  required pw.Font fontBold,
  required pw.Widget table,
}) async {
  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: fontBold),
  );
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      textDirection: pw.TextDirection.rtl,
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[
            pw.Text(
              title,
              style: pw.TextStyle(font: fontBold, fontSize: 18),
              textAlign: pw.TextAlign.right,
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              subtitle,
              style: pw.TextStyle(font: font, fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
            pw.SizedBox(height: 16),
            table,
          ],
        );
      },
    ),
  );
  return pdf.save();
}
