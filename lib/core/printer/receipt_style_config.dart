import 'package:amethyst/core/printer/driver_receipt_style_id.dart';

/// قابل للتخصيص من شاشة «نمط الطباعة» — تُحفظ محلياً على الجهاز (للسائقين).
final class ReceiptStyleConfig {
  const ReceiptStyleConfig({
    this.displayName = '',
    this.companyTitleOverride = '',
    this.saleInvoiceTitle = 'فاتورة بيع رسمية',
    this.dailySummaryTitle = 'ملخص مبيعات اليوم',
    this.inventoryReportTitle = 'تقرير جرد المركبة',
    this.showRemainingInventory = true,
    this.showReceiverSignature = true,
    this.showStationStamp = true,
    this.receiverSignatureLabel = 'توقيع المستلم: ________________',
    this.stationStampLabel = 'ختم المحطة: ________________',
    this.footerNote = '',
    this.colItem = 'الصنف',
    this.colQuantity = 'الكمية',
    this.colPrice = 'السعر',
    this.colTotal = 'الإجمالي',
    this.remainingInventoryTitle = 'المخزون المتبقي',
    this.autoCut = true,
  });

  final String displayName;
  final String companyTitleOverride;
  final String saleInvoiceTitle;
  final String dailySummaryTitle;
  final String inventoryReportTitle;
  final bool showRemainingInventory;
  final bool showReceiverSignature;
  final bool showStationStamp;
  final String receiverSignatureLabel;
  final String stationStampLabel;
  final String footerNote;
  final String colItem;
  final String colQuantity;
  final String colPrice;
  final String colTotal;
  final String remainingInventoryTitle;
  final bool autoCut;

  static const ReceiptStyleConfig defaults = ReceiptStyleConfig();

  static ReceiptStyleConfig preset(DriverReceiptStyleId id) {
    return switch (id) {
      DriverReceiptStyleId.pattern1 => const ReceiptStyleConfig(
          displayName: 'النمط الأول',
          saleInvoiceTitle: 'فاتورة بيع رسمية',
        ),
      DriverReceiptStyleId.pattern2 => const ReceiptStyleConfig(
          displayName: 'النمط الثاني',
          saleInvoiceTitle: 'فاتورة مبيعات',
          showStationStamp: false,
        ),
      DriverReceiptStyleId.pattern3 => const ReceiptStyleConfig(
          displayName: 'النمط الثالث',
          saleInvoiceTitle: 'فاتورة سائق',
          footerNote: 'شكراً لتعاملكم معنا',
        ),
    };
  }

  String companyTitle(String fallback) =>
      companyTitleOverride.trim().isEmpty ? fallback : companyTitleOverride.trim();

  ReceiptStyleConfig copyWith({
    String? displayName,
    String? companyTitleOverride,
    String? saleInvoiceTitle,
    String? dailySummaryTitle,
    String? inventoryReportTitle,
    bool? showRemainingInventory,
    bool? showReceiverSignature,
    bool? showStationStamp,
    String? receiverSignatureLabel,
    String? stationStampLabel,
    String? footerNote,
    String? colItem,
    String? colQuantity,
    String? colPrice,
    String? colTotal,
    String? remainingInventoryTitle,
    bool? autoCut,
  }) {
    return ReceiptStyleConfig(
      displayName: displayName ?? this.displayName,
      companyTitleOverride: companyTitleOverride ?? this.companyTitleOverride,
      saleInvoiceTitle: saleInvoiceTitle ?? this.saleInvoiceTitle,
      dailySummaryTitle: dailySummaryTitle ?? this.dailySummaryTitle,
      inventoryReportTitle: inventoryReportTitle ?? this.inventoryReportTitle,
      showRemainingInventory:
          showRemainingInventory ?? this.showRemainingInventory,
      showReceiverSignature:
          showReceiverSignature ?? this.showReceiverSignature,
      showStationStamp: showStationStamp ?? this.showStationStamp,
      receiverSignatureLabel:
          receiverSignatureLabel ?? this.receiverSignatureLabel,
      stationStampLabel: stationStampLabel ?? this.stationStampLabel,
      footerNote: footerNote ?? this.footerNote,
      colItem: colItem ?? this.colItem,
      colQuantity: colQuantity ?? this.colQuantity,
      colPrice: colPrice ?? this.colPrice,
      colTotal: colTotal ?? this.colTotal,
      remainingInventoryTitle:
          remainingInventoryTitle ?? this.remainingInventoryTitle,
      autoCut: autoCut ?? this.autoCut,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'displayName': displayName,
        'companyTitleOverride': companyTitleOverride,
        'saleInvoiceTitle': saleInvoiceTitle,
        'dailySummaryTitle': dailySummaryTitle,
        'inventoryReportTitle': inventoryReportTitle,
        'showRemainingInventory': showRemainingInventory,
        'showReceiverSignature': showReceiverSignature,
        'showStationStamp': showStationStamp,
        'receiverSignatureLabel': receiverSignatureLabel,
        'stationStampLabel': stationStampLabel,
        'footerNote': footerNote,
        'colItem': colItem,
        'colQuantity': colQuantity,
        'colPrice': colPrice,
        'colTotal': colTotal,
        'remainingInventoryTitle': remainingInventoryTitle,
        'autoCut': autoCut,
      };

  factory ReceiptStyleConfig.fromJson(
    Map<String, dynamic> json, {
    DriverReceiptStyleId fallbackId = DriverReceiptStyleId.pattern1,
  }) {
    final ReceiptStyleConfig preset = ReceiptStyleConfig.preset(fallbackId);
    return ReceiptStyleConfig(
      displayName: json['displayName'] as String? ?? preset.displayName,
      companyTitleOverride: json['companyTitleOverride'] as String? ?? '',
      saleInvoiceTitle:
          json['saleInvoiceTitle'] as String? ?? preset.saleInvoiceTitle,
      dailySummaryTitle:
          json['dailySummaryTitle'] as String? ?? preset.dailySummaryTitle,
      inventoryReportTitle:
          json['inventoryReportTitle'] as String? ?? preset.inventoryReportTitle,
      showRemainingInventory:
          json['showRemainingInventory'] as bool? ?? true,
      showReceiverSignature:
          json['showReceiverSignature'] as bool? ?? true,
      showStationStamp: json['showStationStamp'] as bool? ?? true,
      receiverSignatureLabel: json['receiverSignatureLabel'] as String? ??
          preset.receiverSignatureLabel,
      stationStampLabel:
          json['stationStampLabel'] as String? ?? preset.stationStampLabel,
      footerNote: json['footerNote'] as String? ?? preset.footerNote,
      colItem: json['colItem'] as String? ?? preset.colItem,
      colQuantity: json['colQuantity'] as String? ?? preset.colQuantity,
      colPrice: json['colPrice'] as String? ?? preset.colPrice,
      colTotal: json['colTotal'] as String? ?? preset.colTotal,
      remainingInventoryTitle: json['remainingInventoryTitle'] as String? ??
          preset.remainingInventoryTitle,
      autoCut: json['autoCut'] as bool? ?? true,
    );
  }
}
