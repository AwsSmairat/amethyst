part of 'super_admin_reports_pdf.dart';

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
