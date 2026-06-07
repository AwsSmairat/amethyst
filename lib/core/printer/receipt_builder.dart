import 'package:amethyst/core/printer/receipt_models.dart';
import 'package:amethyst/core/printer/receipt_style_config.dart';
import 'package:amethyst/core/printer/receipt_style_storage.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Builds ESC/POS byte payloads for 58mm thermal printers with Arabic RTL layout.
abstract final class ReceiptBuilder {
  static const int _paperWidth = 384;

  static Future<List<int>> buildSaleReceipt(SaleReceiptData data) async {
    final ReceiptStyleConfig style = await ReceiptStyleStorage.load();
    final Generator generator = await _generator();
    final List<int> bytes = <int>[];
    bytes.addAll(
      _header(
        generator,
        style.companyTitle(data.companyTitle),
        style.saleInvoiceTitle,
      ),
    );
    bytes.addAll(
      generator.text(
        'رقم الفاتورة: ${data.invoiceNumber}',
        styles: const PosStyles(align: PosAlign.right),
      ),
    );
    bytes.addAll(
      _metaBlock(generator, data.dateTime, data.driverName, data.vehicleName),
    );
    bytes.addAll(_divider(generator));
    bytes.addAll(_itemsTable(generator, data.items, style));
    bytes.addAll(_divider(generator));
    bytes.addAll(
      generator.text(
        '${style.colTotal}: ${_money(data.grandTotal)}',
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        'طريقة الدفع: ${data.paymentMethod}',
        styles: const PosStyles(align: PosAlign.right),
      ),
    );
    if (style.showRemainingInventory && data.remainingInventory.isNotEmpty) {
      bytes.addAll(_divider(generator));
      bytes.addAll(
        generator.text(
          style.remainingInventoryTitle,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
      );
      for (final ReceiptInventoryLine line in data.remainingInventory) {
        bytes.addAll(
          generator.row(<PosColumn>[
            PosColumn(
              text: '${line.remaining}',
              width: 2,
              styles: const PosStyles(align: PosAlign.left),
            ),
            PosColumn(
              text: line.name,
              width: 10,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]),
        );
      }
    }
    bytes.addAll(_footer(generator, style));
    return bytes;
  }

  static Future<List<int>> buildDailySummaryReceipt(
    DailySummaryReceiptData data,
  ) async {
    final ReceiptStyleConfig style = await ReceiptStyleStorage.load();
    final Generator generator = await _generator();
    final List<int> bytes = <int>[];
    bytes.addAll(
      _header(
        generator,
        style.companyTitle(data.companyTitle),
        style.dailySummaryTitle,
      ),
    );
    bytes.addAll(
      generator.text(
        'التاريخ: ${DateFormat.yMMMd('ar').format(data.date)}',
        styles: const PosStyles(align: PosAlign.right),
      ),
    );
    bytes.addAll(
      generator.text(
        'السائق: ${data.driverName}',
        styles: const PosStyles(align: PosAlign.right),
      ),
    );
    bytes.addAll(
      generator.text(
        'المركبة: ${data.vehicleName}',
        styles: const PosStyles(align: PosAlign.right),
      ),
    );
    bytes.addAll(
      generator.text(
        'عدد العمليات: ${data.saleCount}',
        styles: const PosStyles(align: PosAlign.right),
      ),
    );
    bytes.addAll(_divider(generator));
    bytes.addAll(_itemsTable(generator, data.items, style));
    bytes.addAll(_divider(generator));
    bytes.addAll(
      generator.text(
        'إجمالي اليوم: ${_money(data.grandTotal)}',
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(_footer(generator, style));
    return bytes;
  }

  static Future<List<int>> buildInventoryReportReceipt(
    InventoryReportReceiptData data,
  ) async {
    final ReceiptStyleConfig style = await ReceiptStyleStorage.load();
    final Generator generator = await _generator();
    final List<int> bytes = <int>[];
    bytes.addAll(
      _header(
        generator,
        style.companyTitle(data.companyTitle),
        style.inventoryReportTitle,
      ),
    );
    bytes.addAll(
      _metaBlock(generator, data.dateTime, data.driverName, data.vehicleName),
    );
    bytes.addAll(_divider(generator));
    bytes.addAll(
      generator.text(
        style.colItem,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    );
    for (final ReceiptInventoryLine line in data.lines) {
      bytes.addAll(
        generator.row(<PosColumn>[
          PosColumn(
            text: '${line.remaining}',
            width: 3,
            styles: const PosStyles(align: PosAlign.left, bold: true),
          ),
          PosColumn(
            text: line.name,
            width: 9,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }
    bytes.addAll(_footer(generator, style));
    return bytes;
  }

  static Future<List<int>> buildTestReceipt({
    required String companyTitle,
    required String message,
  }) async {
    final ReceiptStyleConfig style = await ReceiptStyleStorage.load();
    final Generator generator = await _generator();
    final List<int> bytes = <int>[];
    bytes.addAll(
      _header(generator, style.companyTitle(companyTitle), 'اختبار الطابعة'),
    );
    bytes.addAll(
      generator.text(
        message,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        DateFormat.yMMMd('ar').add_jm().format(DateTime.now()),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(_footer(generator, style));
    return bytes;
  }

  static Future<Generator> _generator() async {
    final CapabilityProfile profile = await CapabilityProfile.load();
    return Generator(PaperSize.mm58, profile);
  }

  static List<int> _header(
    Generator generator,
    String companyTitle,
    String title,
  ) {
    return <int>[
      ...generator.text(
        companyTitle,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      ...generator.text(
        title,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
      ...generator.feed(1),
    ];
  }

  static List<int> _metaBlock(
    Generator generator,
    DateTime dateTime,
    String driverName,
    String vehicleName,
  ) {
    final String when = DateFormat.yMMMd('ar').add_jm().format(dateTime);
    return <int>[
      ...generator.text(
        'التاريخ: $when',
        styles: const PosStyles(align: PosAlign.right),
      ),
      ...generator.text(
        'السائق: $driverName',
        styles: const PosStyles(align: PosAlign.right),
      ),
      ...generator.text(
        'المركبة: $vehicleName',
        styles: const PosStyles(align: PosAlign.right),
      ),
    ];
  }

  static List<int> _itemsTable(
    Generator generator,
    List<ReceiptLineItem> items,
    ReceiptStyleConfig style,
  ) {
    final List<int> bytes = <int>[
      ...generator.row(<PosColumn>[
        PosColumn(
          text: style.colTotal,
          width: 3,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        ),
        PosColumn(
          text: style.colPrice,
          width: 3,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: style.colQuantity,
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: style.colItem,
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    ];
    for (final ReceiptLineItem item in items) {
      bytes.addAll(
        generator.row(<PosColumn>[
          PosColumn(
            text: _money(item.total),
            width: 3,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: _money(item.unitPrice),
            width: 3,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: '${item.quantity}',
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: item.name,
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }
    return bytes;
  }

  static List<int> _divider(Generator generator) {
    return generator.hr(ch: '-', len: _paperWidth ~/ 12);
  }

  static List<int> _footer(Generator generator, ReceiptStyleConfig style) {
    final List<int> bytes = <int>[...generator.feed(1)];
    if (style.showReceiverSignature) {
      bytes.addAll(
        generator.text(
          style.receiverSignatureLabel,
          styles: const PosStyles(align: PosAlign.right),
        ),
      );
    }
    if (style.showStationStamp) {
      bytes.addAll(
        generator.text(
          style.stationStampLabel,
          styles: const PosStyles(align: PosAlign.right),
        ),
      );
    }
    if (style.footerNote.trim().isNotEmpty) {
      bytes.addAll(
        generator.text(
          style.footerNote.trim(),
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }
    bytes.addAll(generator.feed(2));
    if (style.autoCut) {
      bytes.addAll(generator.cut());
    }
    return bytes;
  }

  static String _money(double value) =>
      NumberFormat('#,##0.##', 'ar').format(value);
}
