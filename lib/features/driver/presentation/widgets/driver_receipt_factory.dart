import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/printer/receipt_models.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/features/driver/presentation/widgets/add_vehicle_sale_sheet.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

abstract final class DriverReceiptFactory {
  static SaleReceiptData buildSaleReceipt({
    required AppLocalizations l10n,
    required String driverName,
    required String vehicleName,
    required VehicleSalePlace? place,
    required List<int> quantities,
    required List<String> productLabels,
    required List<double?> unitPrices,
    required List<Map<String, dynamic>> driverLoadLines,
    required int columnCount,
    String? paymentMethodLabel,
  }) {
    final DateTime now = DateTime.now();
    final List<ReceiptLineItem> items = <ReceiptLineItem>[];
    var grandTotal = 0.0;
    for (var i = 0; i < columnCount; i++) {
      final int qty = quantities[i];
      if (qty <= 0) {
        continue;
      }
      final double unit = unitPrices[i] ?? 0;
      final double lineTotal = unit * qty;
      grandTotal += lineTotal;
      items.add(
        ReceiptLineItem(
          name: productLabels[i].isEmpty
              ? l10n.productRow(i + 1)
              : productLabels[i],
          quantity: qty,
          unitPrice: unit,
          total: lineTotal,
        ),
      );
    }

    final List<ReceiptInventoryLine> remaining = driverLoadLines
        .map((Map<String, dynamic> line) {
          final String? raw = line['product']?['name']?.toString() ??
              line['productName']?.toString();
          final String name = raw == null || raw.trim().isEmpty
              ? l10n.product
              : catalogProductArabicDisplayLabel(raw);
          final int rem = (line['remaining'] as num?)?.toInt() ?? 0;
          return ReceiptInventoryLine(name: name, remaining: rem);
        })
        .where((ReceiptInventoryLine line) => line.remaining > 0)
        .toList(growable: false);

    return SaleReceiptData(
      companyTitle: l10n.appTitle,
      invoiceTitle: l10n.printerSaleInvoiceTitle,
      invoiceNumber: 'INV-${DateFormat('yyyyMMddHHmmss').format(now)}',
      dateTime: now,
      driverName: driverName,
      vehicleName: vehicleName,
      items: items,
      grandTotal: grandTotal,
      paymentMethod: paymentMethodLabel ?? _paymentMethodLabel(l10n, place),
      remainingInventory: remaining,
    );
  }

  static DailySummaryReceiptData buildDailySummary({
    required AppLocalizations l10n,
    required String driverName,
    required String vehicleName,
    required DateTime day,
    required List<Map<String, dynamic>> sales,
  }) {
    final Map<String, ReceiptLineItem> merged = <String, ReceiptLineItem>{};
    var grandTotal = 0.0;
    for (final Map<String, dynamic> sale in sales) {
      final String name = _productName(l10n, sale);
      final int qty = (sale['quantity'] as num?)?.toInt() ?? 0;
      final double unit = parseDynamicDouble(sale['unitPrice']) ?? 0;
      final double total = parseDynamicDouble(sale['totalAmount']) ?? unit * qty;
      grandTotal += total;
      final ReceiptLineItem? existing = merged[name];
      if (existing == null) {
        merged[name] = ReceiptLineItem(
          name: name,
          quantity: qty,
          unitPrice: unit,
          total: total,
        );
      } else {
        merged[name] = ReceiptLineItem(
          name: name,
          quantity: existing.quantity + qty,
          unitPrice: unit,
          total: existing.total + total,
        );
      }
    }

    return DailySummaryReceiptData(
      companyTitle: l10n.appTitle,
      reportTitle: l10n.printerDailySummaryTitle,
      date: day,
      driverName: driverName,
      vehicleName: vehicleName,
      items: merged.values.toList(growable: false),
      grandTotal: grandTotal,
      saleCount: sales.length,
    );
  }

  static InventoryReportReceiptData buildInventoryReport({
    required AppLocalizations l10n,
    required String driverName,
    required String vehicleName,
    required List<Map<String, dynamic>> loads,
  }) {
    final List<ReceiptInventoryLine> lines = loads
        .map((Map<String, dynamic> line) {
          final String? raw = line['product']?['name']?.toString();
          final String name = raw == null || raw.trim().isEmpty
              ? l10n.product
              : catalogProductArabicDisplayLabel(raw);
          return ReceiptInventoryLine(
            name: name,
            remaining: (line['remaining'] as num?)?.toInt() ?? 0,
          );
        })
        .toList(growable: false);

    return InventoryReportReceiptData(
      companyTitle: l10n.appTitle,
      reportTitle: l10n.printerInventoryReportTitle,
      dateTime: DateTime.now(),
      driverName: driverName,
      vehicleName: vehicleName,
      lines: lines,
    );
  }

  static String _paymentMethodLabel(
    AppLocalizations l10n,
    VehicleSalePlace? place,
  ) {
    return switch (place) {
      VehicleSalePlace.home => l10n.vehicleSalePlaceHome,
      VehicleSalePlace.store => l10n.vehicleSalePlaceStore,
      null => l10n.printerPaymentCash,
    };
  }

  static String _productName(AppLocalizations l10n, Map<String, dynamic> sale) {
    final Map<String, dynamic>? product = sale['product'] as Map<String, dynamic>?;
    final String? raw = product?['name']?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      return catalogProductArabicDisplayLabel(raw);
    }
    return l10n.product;
  }
}
