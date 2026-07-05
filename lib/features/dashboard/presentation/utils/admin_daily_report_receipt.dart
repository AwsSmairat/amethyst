import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/printer/receipt_style_storage.dart';
import 'package:amethyst/core/station_debt/station_debt_entry_utils.dart';
import 'package:amethyst/core/utils/format_money.dart';
import 'package:amethyst/core/utils/parse_api_datetime.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_lines.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_display.dart';
import 'package:amethyst/features/dashboard/presentation/utils/admin_daily_report_data.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart' hide TextDirection;

Future<List<int>> buildAdminDailyReportReceipt({
  required AdminDailyReportData data,
  required AppLocalizations l10n,
}) async {
  final String companyTitle =
      (await ReceiptStyleStorage.load()).companyTitle('أميثست');
  final CapabilityProfile profile = await CapabilityProfile.load();
  final Generator generator = Generator(PaperSize.mm58, profile);
  final List<int> bytes = <int>[];

  bytes.addAll(
    generator.text(
      companyTitle,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ),
  );
  bytes.addAll(
    generator.text(
      l10n.adminDailyReportTitle,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ),
  );
  bytes.addAll(
    generator.text(
      DateFormat.yMMMd('ar').format(data.day),
      styles: const PosStyles(align: PosAlign.right),
    ),
  );
  bytes.addAll(generator.feed(1));
  bytes.addAll(_hr(generator));

  bytes.addAll(_section(generator, l10n.adminDailyReportCashSection));
  bytes.addAll(
    _line(
      generator,
      l10n.stationCashBalanceTodayLabel,
      formatMoneyAmount(data.cashToday),
    ),
  );
  bytes.addAll(
    _line(
      generator,
      l10n.stationCashBalanceYesterdayLabel,
      formatMoneyAmount(data.cashYesterday),
    ),
  );

  bytes.addAll(_section(generator, l10n.adminDailyReportBalanceSection));
  bytes.addAll(
    _line(
      generator,
      l10n.adminDailyReportBalanceTotalUnits,
      '${data.balanceSummary.totalUnits}',
    ),
  );
  bytes.addAll(
    _line(
      generator,
      l10n.adminDailyReportRemainingStationStock,
      '${data.remainingStationStock}',
    ),
  );
  bytes.addAll(
    _line(
      generator,
      l10n.adminDailyReportRemainingOnVehicles,
      '${data.remainingOnVehicles}',
    ),
  );
  for (final AdminBalanceRow row in data.balanceRows) {
    bytes.addAll(
      generator.row(<PosColumn>[
        PosColumn(
          text: '${row.stock}',
          width: 3,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: stationBalanceRowLabel(l10n, row.rowIndex),
          width: 9,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
  }

  bytes.addAll(_section(generator, l10n.adminDailyReportSalesSummarySection));
  bytes.addAll(
    _line(
      generator,
      l10n.stationInsideSales,
      formatMoneyAmount(data.stationSalesToday),
    ),
  );
  bytes.addAll(
    _line(
      generator,
      l10n.adminVehicleSalesLabel,
      formatMoneyAmount(data.vehicleSalesToday),
    ),
  );
  bytes.addAll(
    _line(
      generator,
      l10n.adminDailyReportTotalSalesToday,
      formatMoneyAmount(data.totalSalesToday),
    ),
  );

  bytes.addAll(_section(generator, l10n.adminDailyReportStationSalesSection));
  if (data.stationSales.isEmpty) {
    bytes.addAll(
      generator.text('—', styles: const PosStyles(align: PosAlign.right)),
    );
  } else {
    for (final Map<String, dynamic> sale in data.stationSales) {
      bytes.addAll(_saleLine(generator, sale));
    }
  }

  bytes.addAll(_section(generator, l10n.adminDailyReportVehicleSalesSection));
  if (data.vehicleSales.isEmpty) {
    bytes.addAll(
      generator.text('—', styles: const PosStyles(align: PosAlign.right)),
    );
  } else {
    for (final Map<String, dynamic> sale in data.vehicleSales) {
      bytes.addAll(_vehicleSaleLine(generator, sale));
    }
  }

  bytes.addAll(_section(generator, l10n.adminDailyReportDebtSection));
  bytes.addAll(
    _line(
      generator,
      l10n.adminDailyReportDebtTotalToday,
      formatMoneyAmount(data.debtTotalToday),
    ),
  );
  if (data.debtEntriesToday.isEmpty) {
    bytes.addAll(
      generator.text('—', styles: const PosStyles(align: PosAlign.right)),
    );
  } else {
    for (final Map<String, dynamic> entry in data.debtEntriesToday) {
      bytes.addAll(_debtLine(generator, l10n, entry));
    }
  }

  bytes.addAll(generator.feed(2));
  bytes.addAll(generator.cut());
  return bytes;
}

List<int> _section(Generator generator, String title) {
  return <int>[
    ..._hr(generator),
    ...generator.text(
      title,
      styles: const PosStyles(align: PosAlign.right, bold: true),
    ),
  ];
}

List<int> _line(Generator generator, String label, String value) {
  return generator.row(<PosColumn>[
    PosColumn(
      text: value,
      width: 4,
      styles: const PosStyles(align: PosAlign.left),
    ),
    PosColumn(
      text: label,
      width: 8,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);
}

List<int> _saleLine(Generator generator, Map<String, dynamic> sale) {
  final Object? p = sale['product'];
  final String name = p is Map<String, dynamic>
      ? catalogProductArabicDisplayLabel(p['name']?.toString())
      : '—';
  final int q = (sale['quantity'] as num?)?.toInt() ?? 0;
  final double total = parseDynamicDouble(sale['totalAmount']) ?? 0;
  final String time = _formatTime(sale['createdAt']);
  return generator.text(
    '$name · $q · ${formatMoneyAmount(total)} · $time',
    styles: const PosStyles(align: PosAlign.right),
  );
}

List<int> _vehicleSaleLine(Generator generator, Map<String, dynamic> sale) {
  final Object? p = sale['product'];
  final String name = p is Map<String, dynamic>
      ? catalogProductArabicDisplayLabel(p['name']?.toString())
      : '—';
  final int q = (sale['quantity'] as num?)?.toInt() ?? 0;
  final double total = parseDynamicDouble(sale['totalAmount']) ?? 0;
  final Object? v = sale['vehicle'];
  final String vehicle = v is Map<String, dynamic>
      ? (v['vehicleNumber']?.toString() ?? '—')
      : '—';
  return generator.text(
    '$vehicle · $name · $q · ${formatMoneyAmount(total)}',
    styles: const PosStyles(align: PosAlign.right),
  );
}

List<int> _debtLine(
  Generator generator,
  AppLocalizations l10n,
  Map<String, dynamic> entry,
) {
  final String debtor = entry['debtorName']?.toString().trim() ?? '—';
  final String product = debtEntryProductDisplayLabel(entry);
  final double amount = parseDynamicDouble(entry['totalAmount']) ?? 0;
  final String kind = isVehicleDebtEntry(entry)
      ? l10n.stationDebtKindVehicle
      : l10n.stationDebtKindStation;
  return generator.text(
    '$debtor · $kind · $product · ${formatMoneyAmount(amount)}',
    styles: const PosStyles(align: PosAlign.right),
  );
}

String _formatTime(Object? createdAt) {
  final DateTime? dt = parseApiDateTime(createdAt);
  if (dt == null) {
    return '—';
  }
  return DateFormat.Hm('ar').format(dt);
}

List<int> _hr(Generator generator) => generator.hr(ch: '-', len: 32);
