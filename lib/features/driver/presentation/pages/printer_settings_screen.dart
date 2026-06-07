import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/printer/printer_exception.dart';
import 'package:amethyst/core/printer/printer_service.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/driver/presentation/widgets/add_vehicle_sale_sheet.dart';
import 'package:amethyst/features/driver/presentation/widgets/receipt_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printer = sl<PrinterService>();
  List<BluetoothPrinterDevice> _devices = <BluetoothPrinterDevice>[];
  bool _scanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final List<BluetoothPrinterDevice> devices =
          await _printer.scanPairedPrinters();
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = devices;
        _scanning = false;
      });
    } on PrinterException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message;
        _scanning = false;
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _scanning = false;
      });
    }
  }

  Future<void> _connect(BluetoothPrinterDevice device) async {
    try {
      await _printer.connect(device);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.printerConnected)),
      );
      setState(() {});
    } on PrinterException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _disconnect() async {
    await _printer.disconnect();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _registerSaleAndPrint() async {
    await showAddVehicleSaleSheet(context);
  }

  String _statusLabel(BuildContext context, PrinterConnectionStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      PrinterConnectionStatus.connected => l10n.printerStatusConnected,
      PrinterConnectionStatus.connecting => l10n.printerStatusConnecting,
      PrinterConnectionStatus.error => l10n.printerStatusError,
      PrinterConnectionStatus.disconnected => l10n.printerStatusDisconnected,
    };
  }

  Color _statusColor(PrinterConnectionStatus status) {
    return switch (status) {
      PrinterConnectionStatus.connected => AppColors.success,
      PrinterConnectionStatus.connecting => AppColors.brandPrimary,
      PrinterConnectionStatus.error => AppColors.error,
      PrinterConnectionStatus.disconnected => AppColors.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.printerSettingsTitle),
        actions: <Widget>[
          IconButton(
            onPressed: _scanning ? null : _scan,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          ValueListenableBuilder<PrinterConnectionStatus>(
            valueListenable: _printer.status,
            builder: (BuildContext context, PrinterConnectionStatus status, _) {
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.print_outlined,
                    color: _statusColor(status),
                  ),
                  title: Text(l10n.printerStatusTitle),
                  subtitle: Text(
                    _printer.connectedName ??
                        l10n.printerNoPrinterSelected,
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(context, status),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_printer.connectedMac != null)
            OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off),
              label: Text(l10n.printerDisconnect),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showReceiptPreviewSheet(context),
            icon: const Icon(Icons.visibility_outlined),
            label: Text(l10n.printerReceiptPreviewTitle),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/driver/receipt-style'),
            icon: const Icon(Icons.tune_outlined),
            label: Text(l10n.receiptStyleSettingsTitle),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _registerSaleAndPrint,
            icon: const Icon(Icons.add_shopping_cart_outlined),
            label: Text(l10n.printerRegisterSaleAndPrint),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.printerPairedDevicesTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (_scanning)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error))
          else if (_devices.isEmpty)
            Text(l10n.printerNoDevicesFound)
          else
            ..._devices.map(
              (BluetoothPrinterDevice device) => Card(
                child: ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.macAddress),
                  trailing: _printer.connectedMac == device.macAddress
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const Icon(Icons.chevron_left),
                  onTap: () => _connect(device),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
