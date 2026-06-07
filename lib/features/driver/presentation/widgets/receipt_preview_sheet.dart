import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/printer/receipt_style_config.dart';
import 'package:amethyst/core/printer/receipt_style_storage.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

enum ReceiptPreviewKind {
  sale,
  dailySummary,
  inventory,
}

Future<void> showReceiptPreviewSheet(
  BuildContext context, {
  ReceiptStyleConfig? styleOverride,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return _ReceiptPreviewSheetBody(styleOverride: styleOverride);
    },
  );
}

class _ReceiptPreviewSheetBody extends StatefulWidget {
  const _ReceiptPreviewSheetBody({this.styleOverride});

  final ReceiptStyleConfig? styleOverride;

  @override
  State<_ReceiptPreviewSheetBody> createState() =>
      _ReceiptPreviewSheetBodyState();
}

class _ReceiptPreviewSheetBodyState extends State<_ReceiptPreviewSheetBody> {
  ReceiptPreviewKind _kind = ReceiptPreviewKind.sale;
  ReceiptStyleConfig? _style;
  bool _loadingStyle = true;

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    final ReceiptStyleConfig style =
        widget.styleOverride ?? await ReceiptStyleStorage.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _style = style;
      _loadingStyle = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.printerReceiptPreviewTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.printerReceiptPreviewHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<ReceiptPreviewKind>(
                segments: <ButtonSegment<ReceiptPreviewKind>>[
                  ButtonSegment(
                    value: ReceiptPreviewKind.sale,
                    label: Text(l10n.printerPreviewSaleTab),
                  ),
                  ButtonSegment(
                    value: ReceiptPreviewKind.dailySummary,
                    label: Text(l10n.printerPreviewSummaryTab),
                  ),
                  ButtonSegment(
                    value: ReceiptPreviewKind.inventory,
                    label: Text(l10n.printerPreviewInventoryTab),
                  ),
                ],
                selected: <ReceiptPreviewKind>{_kind},
                onSelectionChanged: (Set<ReceiptPreviewKind> selected) {
                  setState(() => _kind = selected.first);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loadingStyle || _style == null
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        controller: scrollController,
                        child: Center(
                          child: _ThermalReceiptPaper(
                            kind: _kind,
                            receiptStyle: _style!,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThermalReceiptPaper extends StatelessWidget {
  const _ThermalReceiptPaper({
    required this.kind,
    required this.receiptStyle,
  });

  final ReceiptPreviewKind kind;
  final ReceiptStyleConfig receiptStyle;

  static const double _paperWidth = 280;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final DateTime now = DateTime.now();
    final String when =
        DateFormat.yMMMd('ar').add_jm().format(now);
    final NumberFormat money = NumberFormat('#,##0.##', 'ar');

    return Container(
      width: _paperWidth,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _center(
                receiptStyle.companyTitle(l10n.appTitle),
                size: 20,
                bold: true,
              ),
              const SizedBox(height: 4),
              _center(_title(), size: 14, bold: true),
              const SizedBox(height: 10),
              if (kind == ReceiptPreviewKind.sale) ...<Widget>[
                _right('رقم الفاتورة: INV-${DateFormat('yyyyMMddHHmmss').format(now)}'),
              ],
              if (kind == ReceiptPreviewKind.dailySummary)
                _right('التاريخ: ${DateFormat.yMMMd('ar').format(now)}')
              else
                _right('التاريخ: $when'),
              _right('السائق: ${l10n.printerPreviewSampleDriver}'),
              _right(l10n.vehicleWithNumber(l10n.printerPreviewSampleVehicle)),
              if (kind == ReceiptPreviewKind.dailySummary)
                _right('عدد العمليات: ٣'),
              _divider(),
              if (kind == ReceiptPreviewKind.inventory) ...<Widget>[
                _right(receiptStyle.colItem, bold: true),
                ..._inventoryLines(),
              ] else ...<Widget>[
                _itemsHeader(),
                ..._saleLines(money),
              ],
              _divider(),
              if (kind != ReceiptPreviewKind.inventory) ...<Widget>[
                _right(
                  kind == ReceiptPreviewKind.sale
                      ? '${receiptStyle.colTotal}: ${money.format(42.5)}'
                      : 'إجمالي اليوم: ${money.format(128)}',
                  size: 16,
                  bold: true,
                ),
                if (kind == ReceiptPreviewKind.sale)
                  _right('طريقة الدفع: ${l10n.vehicleSalePlaceHome}'),
                if (kind == ReceiptPreviewKind.sale &&
                    receiptStyle.showRemainingInventory) ...<Widget>[
                  _divider(),
                  _center(receiptStyle.remainingInventoryTitle, bold: true),
                  ..._remainingLines(),
                ],
              ],
              const SizedBox(height: 8),
              if (receiptStyle.showReceiverSignature)
                _right(receiptStyle.receiverSignatureLabel),
              if (receiptStyle.showStationStamp)
                _right(receiptStyle.stationStampLabel),
              if (receiptStyle.footerNote.trim().isNotEmpty)
                _center(receiptStyle.footerNote.trim()),
              const SizedBox(height: 10),
              if (receiptStyle.autoCut) _cutLine(),
            ],
          ),
        ),
      ),
    );
  }

  String _title() {
    return switch (kind) {
      ReceiptPreviewKind.sale => receiptStyle.saleInvoiceTitle,
      ReceiptPreviewKind.dailySummary => receiptStyle.dailySummaryTitle,
      ReceiptPreviewKind.inventory => receiptStyle.inventoryReportTitle,
    };
  }

  List<Widget> _saleLines(NumberFormat money) {
    final List<({String name, int qty, double unit, double total})> rows =
        <({String name, int qty, double unit, double total})>[
      (
        name: catalogProductArabicDisplayLabel('Water Gallon'),
        qty: 2,
        unit: 1.25,
        total: 2.5,
      ),
      (
        name: catalogProductArabicDisplayLabel('Water Bottle'),
        qty: 5,
        unit: 0.5,
        total: 2.5,
      ),
      (
        name: catalogProductArabicDisplayLabel('Water Carton'),
        qty: 1,
        unit: 37.5,
        total: 37.5,
      ),
    ];
    final List<Widget> widgets = <Widget>[];
    for (final ({String name, int qty, double unit, double total}) row in rows) {
      widgets.add(
        _itemRow(
          name: row.name,
          qty: '${row.qty}',
          unit: money.format(row.unit),
          total: money.format(row.total),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _remainingLines() {
    final List<({String name, int rem})> rows = <({String name, int rem})>[
      (name: catalogProductArabicDisplayLabel('Water Gallon'), rem: 18),
      (name: catalogProductArabicDisplayLabel('Water Bottle'), rem: 42),
    ];
    return rows
        .map(
          (({String name, int rem}) row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        row.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${row.rem}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
        )
        .toList(growable: false);
  }

  List<Widget> _inventoryLines() {
    final List<({String name, int rem})> rows = <({String name, int rem})>[
      (name: catalogProductArabicDisplayLabel('Water Gallon'), rem: 18),
      (name: catalogProductArabicDisplayLabel('Water Bottle'), rem: 42),
      (name: catalogProductArabicDisplayLabel('Water Carton'), rem: 6),
      (name: catalogProductArabicDisplayLabel('Coupon'), rem: 10),
    ];
    return rows
        .map(
          (({String name, int rem}) row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        row.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${row.rem}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
        )
        .toList(growable: false);
  }

  Widget _center(String text, {double size = 12, bool bold = false}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        height: 1.35,
        color: Colors.black87,
      ),
    );
  }

  Widget _right(String text, {double size = 12, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          height: 1.35,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _itemsHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              receiptStyle.colTotal,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              receiptStyle.colPrice,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              receiptStyle.colQuantity,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              receiptStyle.colItem,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow({
    required String name,
    required String qty,
    required String unit,
    required String total,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              total,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              unit,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              name,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '-' * 32,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: Colors.black.withValues(alpha: 0.45),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _cutLine() {
    return Column(
      children: <Widget>[
        Text(
          '✂ - - - - - - - - - - - - - - - -',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '58mm',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: Colors.black.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
