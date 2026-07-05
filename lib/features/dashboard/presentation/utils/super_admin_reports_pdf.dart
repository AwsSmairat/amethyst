import 'dart:typed_data';

import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/expenses/expense_category_match.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/station_debt/station_debt_entry_utils.dart';
import 'package:amethyst/core/utils/parse_api_datetime.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_display.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const PdfColor _kExcelHeader = PdfColor.fromInt(0xFF4472C4);
const PdfColor _kExcelHeaderText = PdfColors.white;
const PdfColor _kExcelZebra = PdfColor.fromInt(0xFFF2F2F2);
const PdfColor _kExcelFooter = PdfColor.fromInt(0xFFD9E1F2);
const PdfColor _kExcelBorder = PdfColor.fromInt(0xFFB4B4B4);

final class _ExcelReportSection {
  const _ExcelReportSection({
    required this.title,
    required this.headers,
    required this.rows,
    this.subtitle,
    this.footer,
    this.columnWidths,
    this.columnAligns,
  });

  final String title;
  final String? subtitle;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String>? footer;
  final Map<int, pw.TableColumnWidth>? columnWidths;
  final Map<int, pw.TextAlign>? columnAligns;
}

bool _isHiddenFromStationStockReport(String productName) {
  final String k = normalizeStationBalanceProductName(productName);
  return k == normalizeStationBalanceProductName('جالون متجر') ||
      k == normalizeStationBalanceProductName('قاروره متجر') ||
      k == normalizeStationBalanceProductName('مهدي متجر');
}

Future<Uint8List> buildStationStockPdf({
  required List<Map<String, dynamic>> products,
  required AppLocalizations l10n,
}) async {
  final List<Map<String, dynamic>> sorted =
      List<Map<String, dynamic>>.from(products)
        ..sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (a['name']?.toString() ?? '')
                  .toLowerCase()
                  .compareTo((b['name']?.toString() ?? '').toLowerCase()),
        );

  final int aggregatedWaterCartonStock = aggregateStationStockForBalanceRow(
    products: sorted,
    rowIndex: 0,
  );
  final Set<String> normalizedWaterCartonCandidates =
      StationBalanceProductLookup.nameCandidates.first
          .map(normalizeStationBalanceProductName)
          .where((String e) => e.isNotEmpty)
          .toSet();

  final List<List<String>> data = <List<String>>[];
  int totalStock = 0;
  for (final Map<String, dynamic> pr in sorted) {
    if (pr['isActive'] == false) {
      continue;
    }
    final String rawName = pr['name']?.toString() ?? '—';
    if (_isHiddenFromStationStockReport(rawName)) {
      continue;
    }
    final String normalizedName = normalizeStationBalanceProductName(rawName);
    if (normalizedWaterCartonCandidates.contains(normalizedName) &&
        rawName.trim() != 'Water Carton') {
      continue;
    }
    final Object? st = pr['stationStock'] ?? pr['stock'];
    final int stock = rawName.trim() == 'Water Carton'
        ? aggregatedWaterCartonStock
        : (st is int ? st : int.tryParse(st?.toString() ?? '') ?? 0);
    totalStock += stock;
    data.add(<String>[
      catalogProductArabicDisplayLabel(rawName),
      productUnitTypeArabicLabel(
        pr['unitType']?.toString() ?? pr['type']?.toString(),
      ),
      '$stock',
    ]);
  }

  return _buildExcelReportPdf(
    title: l10n.menuStationStock,
    l10n: l10n,
    headers: <String>[
      l10n.printColumnProduct,
      l10n.printColumnUnitType,
      l10n.quantity,
    ],
    rows: data,
    footer: <String>['', l10n.printReportTotalLabel, '$totalStock'],
    columnWidths: <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2.4),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(0.8),
    },
    columnAligns: <int, pw.TextAlign>{
      2: pw.TextAlign.center,
    },
    landscape: false,
  );
}

Future<Uint8List> buildStationSalesPdf({
  required List<Map<String, dynamic>> sales,
  required AppLocalizations l10n,
}) async {
  final String locale = 'ar';
  final NumberFormat money = NumberFormat.decimalPattern(locale);
  final List<Map<String, dynamic>> sorted = _sortByCreatedAtDesc(sales);

  final List<List<String>> data = <List<String>>[];
  int totalQty = 0;
  double totalAmount = 0;
  for (var i = 0; i < sorted.length; i++) {
    final Map<String, dynamic> s = sorted[i];
    final String name = _saleProductName(s);
    final int q = int.tryParse(s['quantity']?.toString() ?? '') ?? 0;
    final double unit = parseDynamicDouble(s['unitPrice']) ?? 0;
    final double total = parseDynamicDouble(s['totalAmount']) ?? 0;
    totalQty += q;
    totalAmount += total;
    data.add(<String>[
      '${i + 1}',
      _formatPdfDateTime(s['createdAt']),
      name,
      '$q',
      money.format(unit),
      money.format(total),
      _nestedName(s['soldBy'], 'fullName'),
    ]);
  }

  return _buildExcelReportPdf(
    title: l10n.stationSales,
    l10n: l10n,
    headers: <String>[
      '#',
      l10n.printColumnDateTime,
      l10n.printColumnProduct,
      l10n.quantity,
      l10n.unitPrice,
      l10n.printColumnAmount,
      l10n.sellerLabel,
    ],
    rows: data,
    footer: <String>[
      '',
      '',
      l10n.printReportTotalLabel,
      '$totalQty',
      '',
      money.format(totalAmount),
      '',
    ],
    columnWidths: <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(28),
      1: const pw.FlexColumnWidth(1.3),
      2: const pw.FlexColumnWidth(1.8),
      3: const pw.FlexColumnWidth(0.7),
      4: const pw.FlexColumnWidth(0.9),
      5: const pw.FlexColumnWidth(0.9),
      6: const pw.FlexColumnWidth(1.2),
    },
    columnAligns: <int, pw.TextAlign>{
      0: pw.TextAlign.center,
      3: pw.TextAlign.center,
      4: pw.TextAlign.center,
      5: pw.TextAlign.center,
    },
    landscape: true,
  );
}

Future<Uint8List> buildExpensesPdf({
  required List<Map<String, dynamic>> expenses,
  required AppLocalizations l10n,
}) async {
  final String locale = 'ar';
  final NumberFormat money = NumberFormat.decimalPattern(locale);
  final List<Map<String, dynamic>> sorted = _sortByCreatedAtDesc(expenses);

  final List<List<String>> data = <List<String>>[];
  double totalAmount = 0;
  for (var i = 0; i < sorted.length; i++) {
    final Map<String, dynamic> e = sorted[i];
    final double amt = parseDynamicDouble(e['amount']) ?? 0;
    totalAmount += amt;
    String note = expenseNoteArabicDisplayLabel(
      e['note']?.toString() ?? '',
      l10n,
    );
    if (note.length > 80) {
      note = '${note.substring(0, 77)}…';
    }
    data.add(<String>[
      '${i + 1}',
      _formatPdfDateTime(e['createdAt']),
      money.format(amt),
      _nestedName(e['vehicle'], 'vehicleNumber'),
      note.isEmpty ? '—' : note,
    ]);
  }

  return _buildExcelReportPdf(
    title: l10n.expenses,
    l10n: l10n,
    headers: <String>[
      '#',
      l10n.printColumnDateTime,
      l10n.printColumnAmount,
      l10n.printColumnVehicle,
      l10n.printColumnNote,
    ],
    rows: data,
    footer: <String>[
      '',
      l10n.printReportTotalLabel,
      money.format(totalAmount),
      '',
      '',
    ],
    columnWidths: <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(28),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(0.9),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(2.4),
    },
    columnAligns: <int, pw.TextAlign>{
      0: pw.TextAlign.center,
      2: pw.TextAlign.center,
    },
    landscape: true,
  );
}

Future<Uint8List> buildStationDebtPdf({
  required List<Map<String, dynamic>> entries,
  required AppLocalizations l10n,
}) async {
  final String locale = 'ar';
  final NumberFormat money = NumberFormat.decimalPattern(locale);
  final List<Map<String, dynamic>> sorted = _sortByCreatedAtDesc(entries);

  final Map<String, List<Map<String, dynamic>>> byDebtor =
      <String, List<Map<String, dynamic>>>{};
  for (final Map<String, dynamic> e in sorted) {
    final String name = normalizeDebtorName(e['debtorName']?.toString());
    final String key = name.isEmpty ? '—' : name;
    byDebtor.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(e);
  }

  final List<String> debtorKeys = byDebtor.keys.toList()
    ..sort((String a, String b) => a.compareTo(b));

  final List<String> headers = <String>[
    '#',
    l10n.printColumnDateTime,
    l10n.printColumnDebtKind,
    l10n.printColumnProduct,
    l10n.quantity,
    l10n.printColumnAmount,
    l10n.statusLabel,
  ];
  final Map<int, pw.TableColumnWidth> columnWidths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(28),
    1: const pw.FlexColumnWidth(1.2),
    2: const pw.FlexColumnWidth(0.9),
    3: const pw.FlexColumnWidth(1.6),
    4: const pw.FlexColumnWidth(0.7),
    5: const pw.FlexColumnWidth(0.9),
    6: const pw.FlexColumnWidth(0.8),
  };
  final Map<int, pw.TextAlign> columnAligns = <int, pw.TextAlign>{
    0: pw.TextAlign.center,
    4: pw.TextAlign.center,
    5: pw.TextAlign.center,
  };

  final List<_ExcelReportSection> sections = <_ExcelReportSection>[];
  int grandQty = 0;
  double grandAmount = 0;

  for (final String debtor in debtorKeys) {
    final List<Map<String, dynamic>> debtorEntries = byDebtor[debtor]!;
    final List<List<String>> rows = <List<String>>[];
    int sectionQty = 0;
    double sectionAmount = 0;

    for (var i = 0; i < debtorEntries.length; i++) {
      final Map<String, dynamic> e = debtorEntries[i];
      final int q = int.tryParse(e['quantity']?.toString() ?? '') ?? 0;
      final double total = parseDynamicDouble(e['totalAmount']) ?? 0;
      sectionQty += q;
      sectionAmount += total;
      rows.add(<String>[
        '${i + 1}',
        _formatPdfDateTime(e['createdAt']),
        _debtKindLabel(l10n, e),
        debtEntryProductDisplayLabel(e),
        '$q',
        money.format(total),
        e['repaidAt'] != null
            ? l10n.printDebtStatusRepaid
            : l10n.printDebtStatusOpen,
      ]);
    }

    grandQty += sectionQty;
    grandAmount += sectionAmount;

    final String? placeLabel = debtorEntries
        .map((Map<String, dynamic> e) => debtEntryVehiclePlaceLabel(e, l10n))
        .whereType<String>()
        .firstOrNull;

    sections.add(
      _ExcelReportSection(
        title: debtor,
        subtitle: stationDebtKindSummary(debtorEntries, l10n: l10n) +
            (placeLabel != null ? ' · $placeLabel' : ''),
        headers: headers,
        rows: rows,
        footer: <String>[
          '',
          '',
          '',
          l10n.printReportTotalLabel,
          '$sectionQty',
          money.format(sectionAmount),
          '',
        ],
        columnWidths: columnWidths,
        columnAligns: columnAligns,
      ),
    );
  }

  return _buildGroupedExcelReportPdf(
    title: l10n.titleStationDebtList,
    l10n: l10n,
    sections: sections,
    rowCount: sorted.length,
    grandSummary: l10n.printReportGrandTotal(
      '$grandQty',
      money.format(grandAmount),
    ),
    landscape: true,
  );
}

Future<Uint8List> buildVehicleSalesPdf({
  required List<Map<String, dynamic>> sales,
  required AppLocalizations l10n,
}) async {
  final String locale = 'ar';
  final NumberFormat money = NumberFormat.decimalPattern(locale);
  final List<Map<String, dynamic>> sorted = _sortByCreatedAtDesc(sales);

  final Map<String, List<Map<String, dynamic>>> byVehicle =
      <String, List<Map<String, dynamic>>>{};
  for (final Map<String, dynamic> s in sorted) {
    byVehicle.putIfAbsent(_vehicleGroupKey(s), () => <Map<String, dynamic>>[])
        .add(s);
  }

  final List<String> vehicleKeys = byVehicle.keys.toList()
    ..sort(
      (String a, String b) => _vehicleGroupLabel(byVehicle[a]!.first)
          .compareTo(_vehicleGroupLabel(byVehicle[b]!.first)),
    );

  final List<String> headers = <String>[
    '#',
    l10n.printColumnDateTime,
    l10n.printColumnProduct,
    l10n.quantity,
    l10n.printColumnAmount,
    l10n.driver,
  ];
  final Map<int, pw.TableColumnWidth> columnWidths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(28),
    1: const pw.FlexColumnWidth(1.3),
    2: const pw.FlexColumnWidth(2),
    3: const pw.FlexColumnWidth(0.7),
    4: const pw.FlexColumnWidth(0.9),
    5: const pw.FlexColumnWidth(1.3),
  };
  final Map<int, pw.TextAlign> columnAligns = <int, pw.TextAlign>{
    0: pw.TextAlign.center,
    3: pw.TextAlign.center,
    4: pw.TextAlign.center,
  };

  final List<_ExcelReportSection> sections = <_ExcelReportSection>[];
  int grandQty = 0;
  double grandAmount = 0;

  for (final String key in vehicleKeys) {
    final List<Map<String, dynamic>> vehicleSales = byVehicle[key]!;
    final String vehicleLabel = _vehicleGroupLabel(vehicleSales.first);
    final String driver = _nestedName(vehicleSales.first['driver'], 'fullName');

    final List<List<String>> rows = <List<String>>[];
    int sectionQty = 0;
    double sectionAmount = 0;
    for (var i = 0; i < vehicleSales.length; i++) {
      final Map<String, dynamic> s = vehicleSales[i];
      final int q = int.tryParse(s['quantity']?.toString() ?? '') ?? 0;
      final double total = parseDynamicDouble(s['totalAmount']) ?? 0;
      sectionQty += q;
      sectionAmount += total;
      rows.add(<String>[
        '${i + 1}',
        _formatPdfDateTime(s['createdAt']),
        _saleProductName(s),
        '$q',
        money.format(total),
        driver,
      ]);
    }
    grandQty += sectionQty;
    grandAmount += sectionAmount;

    sections.add(
      _ExcelReportSection(
        title: l10n.vehicleWithNumber(vehicleLabel),
        subtitle: driver != '—' ? '${l10n.driver}: $driver' : null,
        headers: headers,
        rows: rows,
        footer: <String>[
          '',
          '',
          l10n.printReportTotalLabel,
          '$sectionQty',
          money.format(sectionAmount),
          '',
        ],
        columnWidths: columnWidths,
        columnAligns: columnAligns,
      ),
    );
  }

  return _buildGroupedExcelReportPdf(
    title: l10n.vehicleSales,
    l10n: l10n,
    sections: sections,
    rowCount: sorted.length,
    grandSummary: l10n.printReportGrandTotal(
      '$grandQty',
      money.format(grandAmount),
    ),
    landscape: true,
  );
}

Future<Uint8List> buildVehicleLoadsPdf({
  required List<Map<String, dynamic>> loads,
  required AppLocalizations l10n,
}) async {
  final List<Map<String, dynamic>> sorted = List<Map<String, dynamic>>.from(loads)
    ..sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime? da = parseApiDateTime(a['loadDate'] ?? a['createdAt']);
      final DateTime? db = parseApiDateTime(b['loadDate'] ?? b['createdAt']);
      if (da == null && db == null) {
        return 0;
      }
      if (da == null) {
        return 1;
      }
      if (db == null) {
        return -1;
      }
      return db.compareTo(da);
    });

  final List<List<String>> data = <List<String>>[];
  int totalQty = 0;
  for (var i = 0; i < sorted.length; i++) {
    final Map<String, dynamic> l = sorted[i];
    final int q = int.tryParse(l['quantityLoaded']?.toString() ?? '') ?? 0;
    totalQty += q;
    data.add(<String>[
      '${i + 1}',
      _formatPdfDate(l['loadDate'] ?? l['createdAt']),
      _saleProductName(l),
      _nestedName(l['vehicle'], 'vehicleNumber'),
      _nestedName(l['driver'], 'fullName'),
      '$q',
      _loadStatusLabel(l10n, l['status']?.toString()),
    ]);
  }

  return _buildExcelReportPdf(
    title: l10n.vehicleLoads,
    l10n: l10n,
    headers: <String>[
      '#',
      l10n.loadDate,
      l10n.printColumnProduct,
      l10n.printColumnVehicle,
      l10n.driver,
      l10n.quantity,
      l10n.statusLabel,
    ],
    rows: data,
    footer: <String>[
      '',
      '',
      l10n.printReportTotalLabel,
      '',
      '',
      '$totalQty',
      '',
    ],
    columnWidths: <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(28),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(1.6),
      3: const pw.FlexColumnWidth(0.9),
      4: const pw.FlexColumnWidth(1.2),
      5: const pw.FlexColumnWidth(0.7),
      6: const pw.FlexColumnWidth(0.8),
    },
    columnAligns: <int, pw.TextAlign>{
      0: pw.TextAlign.center,
      5: pw.TextAlign.center,
    },
    landscape: true,
  );
}

Future<Uint8List> _buildExcelReportPdf({
  required String title,
  required AppLocalizations l10n,
  required List<String> headers,
  required List<List<String>> rows,
  List<String>? footer,
  Map<int, pw.TableColumnWidth>? columnWidths,
  Map<int, pw.TextAlign>? columnAligns,
  bool landscape = true,
}) async {
  final pw.Font font = await PdfGoogleFonts.notoNaskhArabicRegular();
  final pw.Font fontBold = await PdfGoogleFonts.notoNaskhArabicBold();
  final String generatedAt =
      DateFormat('yyyy-MM-dd HH:mm', 'ar').format(DateTime.now());
  final List<List<String>> body =
      rows.isEmpty ? <List<String>>[_emptyRow(headers.length)] : rows;

  final pw.Table table = _excelTable(
    font: font,
    fontBold: fontBold,
    headers: headers,
    rows: body,
    footer: footer,
    columnWidths: columnWidths,
    columnAligns: columnAligns,
  );

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: fontBold),
  );
  pdf.addPage(
    pw.MultiPage(
      pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      textDirection: pw.TextDirection.rtl,
      build: (pw.Context ctx) => <pw.Widget>[
        pw.Text(
          title,
          style: pw.TextStyle(font: fontBold, fontSize: 18),
          textAlign: pw.TextAlign.right,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          generatedAt,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
          textAlign: pw.TextAlign.right,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          l10n.printReportRowCount('${body.length}'),
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
          textAlign: pw.TextAlign.right,
        ),
        pw.SizedBox(height: 12),
        table,
      ],
    ),
  );
  return pdf.save();
}

Future<Uint8List> _buildGroupedExcelReportPdf({
  required String title,
  required AppLocalizations l10n,
  required List<_ExcelReportSection> sections,
  required int rowCount,
  required String grandSummary,
  bool landscape = true,
}) async {
  final pw.Font font = await PdfGoogleFonts.notoNaskhArabicRegular();
  final pw.Font fontBold = await PdfGoogleFonts.notoNaskhArabicBold();
  final String generatedAt =
      DateFormat('yyyy-MM-dd HH:mm', 'ar').format(DateTime.now());

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: fontBold),
  );
  pdf.addPage(
    pw.MultiPage(
      pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      textDirection: pw.TextDirection.rtl,
      build: (pw.Context ctx) {
        final List<pw.Widget> widgets = <pw.Widget>[
          pw.Text(
            title,
            style: pw.TextStyle(font: fontBold, fontSize: 18),
            textAlign: pw.TextAlign.right,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            generatedAt,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.right,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            l10n.printReportRowCount('$rowCount'),
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
            textAlign: pw.TextAlign.right,
          ),
          pw.SizedBox(height: 12),
        ];

        if (sections.isEmpty) {
          widgets.add(
            _excelTable(
              font: font,
              fontBold: fontBold,
              headers: <String>['—'],
              rows: <List<String>>[_emptyRow(1)],
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FlexColumnWidth(),
              },
            ),
          );
        } else {
          for (var i = 0; i < sections.length; i++) {
            final _ExcelReportSection section = sections[i];
            if (i > 0) {
              widgets.add(pw.SizedBox(height: 18));
            }
            widgets.add(
              pw.Text(
                section.title,
                style: pw.TextStyle(font: fontBold, fontSize: 13),
                textAlign: pw.TextAlign.right,
              ),
            );
            if (section.subtitle != null && section.subtitle!.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 2));
              widgets.add(
                pw.Text(
                  section.subtitle!,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              );
            }
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              _excelTable(
                font: font,
                fontBold: fontBold,
                headers: section.headers,
                rows: section.rows.isEmpty
                    ? <List<String>>[_emptyRow(section.headers.length)]
                    : section.rows,
                footer: section.footer,
                columnWidths: section.columnWidths,
                columnAligns: section.columnAligns,
              ),
            );
          }
        }

        widgets.add(pw.SizedBox(height: 16));
        widgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _kExcelFooter,
              border: pw.Border.all(color: _kExcelBorder),
            ),
            child: pw.Text(
              grandSummary,
              style: pw.TextStyle(font: fontBold, fontSize: 11),
              textAlign: pw.TextAlign.right,
            ),
          ),
        );
        return widgets;
      },
    ),
  );
  return pdf.save();
}

pw.Table _excelTable({
  required pw.Font font,
  required pw.Font fontBold,
  required List<String> headers,
  required List<List<String>> rows,
  List<String>? footer,
  Map<int, pw.TableColumnWidth>? columnWidths,
  Map<int, pw.TextAlign>? columnAligns,
}) {
  return pw.Table(
    border: pw.TableBorder.all(color: _kExcelBorder, width: 0.5),
    columnWidths: columnWidths,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: <pw.TableRow>[
      _excelHeaderRow(fontBold, headers, columnAligns),
      for (var i = 0; i < rows.length; i++)
        _excelDataRow(
          font,
          rows[i],
          zebra: i.isOdd,
          columnAligns: columnAligns,
        ),
      if (footer != null) _excelFooterRow(fontBold, footer, columnAligns),
    ],
  );
}

List<String> _emptyRow(int columns) =>
    List<String>.filled(columns, '—', growable: false);

pw.TableRow _excelHeaderRow(
  pw.Font fontBold,
  List<String> headers,
  Map<int, pw.TextAlign>? columnAligns,
) {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(color: _kExcelHeader),
    children: headers
        .asMap()
        .entries
        .map(
          (MapEntry<int, String> e) => _pdfCell(
            e.value,
            fontBold,
            fontSize: 10,
            color: _kExcelHeaderText,
            bold: true,
            align: columnAligns?[e.key] ?? pw.TextAlign.center,
          ),
        )
        .toList(),
  );
}

pw.TableRow _excelDataRow(
  pw.Font font,
  List<String> cells, {
  required bool zebra,
  Map<int, pw.TextAlign>? columnAligns,
}) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(
      color: zebra ? _kExcelZebra : PdfColors.white,
    ),
    children: cells
        .asMap()
        .entries
        .map(
          (MapEntry<int, String> e) => _pdfCell(
            e.value,
            font,
            align: columnAligns?[e.key] ?? pw.TextAlign.right,
          ),
        )
        .toList(),
  );
}

pw.TableRow _excelFooterRow(
  pw.Font fontBold,
  List<String> cells,
  Map<int, pw.TextAlign>? columnAligns,
) {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(color: _kExcelFooter),
    children: cells
        .asMap()
        .entries
        .map(
          (MapEntry<int, String> e) => _pdfCell(
            e.value,
            fontBold,
            bold: true,
            align: columnAligns?[e.key] ?? pw.TextAlign.right,
          ),
        )
        .toList(),
  );
}

pw.Widget _pdfCell(
  String text,
  pw.Font font, {
  double fontSize = 9,
  bool bold = false,
  PdfColor? color,
  pw.TextAlign align = pw.TextAlign.right,
}) {
  return pw.Container(
    constraints: const pw.BoxConstraints(minHeight: 22),
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    alignment: align == pw.TextAlign.center
        ? pw.Alignment.center
        : pw.Alignment.centerRight,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
      textDirection: pw.TextDirection.rtl,
      textAlign: align,
      maxLines: 3,
      overflow: pw.TextOverflow.clip,
    ),
  );
}

List<Map<String, dynamic>> _sortByCreatedAtDesc(
  List<Map<String, dynamic>> items,
) {
  final List<Map<String, dynamic>> sorted =
      List<Map<String, dynamic>>.from(items);
  sorted.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
    final DateTime? da = parseApiDateTime(a['createdAt']);
    final DateTime? db = parseApiDateTime(b['createdAt']);
    if (da == null && db == null) {
      return 0;
    }
    if (da == null) {
      return 1;
    }
    if (db == null) {
      return -1;
    }
    return db.compareTo(da);
  });
  return sorted;
}

String _saleProductName(Map<String, dynamic> item) {
  final Object? p = item['product'];
  if (p is Map<String, dynamic>) {
    final String? raw = p['name']?.toString();
    if (raw == null || raw.trim().isEmpty) {
      return '—';
    }
    return catalogProductArabicDisplayLabel(raw);
  }
  return '—';
}

String _nestedName(dynamic obj, String key) {
  if (obj is Map<String, dynamic>) {
    final String v = obj[key]?.toString().trim() ?? '';
    return v.isEmpty ? '—' : v;
  }
  if (obj is Map) {
    final String v = obj[key]?.toString().trim() ?? '';
    return v.isEmpty ? '—' : v;
  }
  return '—';
}

String _debtKindLabel(AppLocalizations l10n, Map<String, dynamic> entry) {
  if (isVehicleDebtEntry(entry)) {
    return l10n.stationDebtKindVehicle;
  }
  return l10n.stationDebtKindStation;
}

String _vehicleGroupKey(Map<String, dynamic> sale) {
  final Object? v = sale['vehicle'];
  if (v is Map<String, dynamic>) {
    final String? id = v['id']?.toString().trim();
    if (id != null && id.isNotEmpty) {
      return id;
    }
  }
  final String? vehicleId = sale['vehicleId']?.toString().trim();
  if (vehicleId != null && vehicleId.isNotEmpty) {
    return vehicleId;
  }
  return _vehicleGroupLabel(sale);
}

String _vehicleGroupLabel(Map<String, dynamic> sale) {
  final String number = _nestedName(sale['vehicle'], 'vehicleNumber');
  if (number != '—') {
    return number;
  }
  final String? vehicleId = sale['vehicleId']?.toString().trim();
  return vehicleId != null && vehicleId.isNotEmpty ? vehicleId : '—';
}

String _formatPdfDateTime(Object? value) {
  final DateTime? dt = parseApiDateTime(value);
  if (dt == null) {
    return '—';
  }
  return DateFormat('yyyy-MM-dd HH:mm', 'ar').format(dt);
}

String _formatPdfDate(Object? value) {
  final DateTime? dt = parseApiDateTime(value);
  if (dt == null) {
    return '—';
  }
  return DateFormat('yyyy-MM-dd', 'ar').format(dt);
}

String _loadStatusLabel(AppLocalizations l10n, String? status) {
  switch (status?.toLowerCase()) {
    case 'open':
      return l10n.loadStatusOpen;
    case 'closed':
      return l10n.loadStatusClosed;
    default:
      return status?.trim().isNotEmpty == true ? status!.trim() : '—';
  }
}
