final class ReceiptLineItem {
  const ReceiptLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final double total;
}

final class ReceiptInventoryLine {
  const ReceiptInventoryLine({
    required this.name,
    required this.remaining,
  });

  final String name;
  final int remaining;
}

final class SaleReceiptData {
  const SaleReceiptData({
    required this.companyTitle,
    required this.invoiceTitle,
    required this.invoiceNumber,
    required this.dateTime,
    required this.driverName,
    required this.vehicleName,
    required this.items,
    required this.grandTotal,
    required this.paymentMethod,
    required this.remainingInventory,
  });

  final String companyTitle;
  final String invoiceTitle;
  final String invoiceNumber;
  final DateTime dateTime;
  final String driverName;
  final String vehicleName;
  final List<ReceiptLineItem> items;
  final double grandTotal;
  final String paymentMethod;
  final List<ReceiptInventoryLine> remainingInventory;
}

final class DailySummaryReceiptData {
  const DailySummaryReceiptData({
    required this.companyTitle,
    required this.reportTitle,
    required this.date,
    required this.driverName,
    required this.vehicleName,
    required this.items,
    required this.grandTotal,
    required this.saleCount,
  });

  final String companyTitle;
  final String reportTitle;
  final DateTime date;
  final String driverName;
  final String vehicleName;
  final List<ReceiptLineItem> items;
  final double grandTotal;
  final int saleCount;
}

final class InventoryReportReceiptData {
  const InventoryReportReceiptData({
    required this.companyTitle,
    required this.reportTitle,
    required this.dateTime,
    required this.driverName,
    required this.vehicleName,
    required this.lines,
  });

  final String companyTitle;
  final String reportTitle;
  final DateTime dateTime;
  final String driverName;
  final String vehicleName;
  final List<ReceiptInventoryLine> lines;
}
