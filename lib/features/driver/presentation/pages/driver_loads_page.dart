import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/widgets/fab_hero_tags.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/core/printer/receipt_builder.dart';
import 'package:amethyst/features/driver/presentation/driver_loads_list_refresh.dart';
import 'package:amethyst/features/driver/presentation/widgets/add_return_sheet.dart';
import 'package:amethyst/features/driver/presentation/widgets/driver_print_context.dart';
import 'package:amethyst/features/driver/presentation/widgets/driver_receipt_factory.dart';
import 'package:amethyst/features/driver/presentation/widgets/print_receipt_prompt_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverLoadsPage extends StatefulWidget {
  const DriverLoadsPage({super.key});

  @override
  State<DriverLoadsPage> createState() => _DriverLoadsPageState();
}

class _DriverLoadsPageState extends State<DriverLoadsPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  bool _loadsExpanded = false;

  @override
  void initState() {
    super.initState();
    DriverLoadsListRefresh.onRefreshRequested = _load;
    _load();
  }

  @override
  void dispose() {
    if (DriverLoadsListRefresh.onRefreshRequested == _load) {
      DriverLoadsListRefresh.onRefreshRequested = null;
    }
    super.dispose();
  }

  Future<void> _printInventoryReport() async {
    final DriverPrintContext? ctx = await loadDriverPrintContext(context);
    if (!mounted) {
      return;
    }
    if (ctx == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noVehicleAssignedFull)),
      );
      return;
    }
    final List<Map<String, dynamic>> loads =
        (_data?['loads'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    final receipt = DriverReceiptFactory.buildInventoryReport(
      l10n: context.l10n,
      driverName: ctx.driverName,
      vehicleName: ctx.vehicleName,
      loads: loads,
    );
    await showPrintReceiptPromptSheet(
      context,
      buildReceiptBytes: () =>
          ReceiptBuilder.buildInventoryReportReceipt(receipt),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await sl<AmethystApi>().driverCurrentLoad();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.currentLoads),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.printerPrintInventoryReport,
            onPressed: _printInventoryReport,
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: FabHeroTags.driverLoads,
        onPressed: () => showAddReturnSheet(context).then((_) => _load()),
        icon: const Icon(Icons.assignment_return),
        label: Text(context.l10n.quickLogReturn),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    final vehicle = _data?['vehicle'] as Map<String, dynamic>?;
    final loads = (_data?['loads'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (vehicle == null) {
      return Center(child: Text(l10n.noVehicleAssignedFull));
    }
    final String locale = Localizations.localeOf(context).toString();
    final String dayLabel =
        DateFormat.yMMMEd(locale).format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _loadsExpanded = !_loadsExpanded),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.todaysLoadsSection,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.todaysLoadsExpandHint,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _loadsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_loadsExpanded) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            l10n.vehicleWithNumber('${vehicle['vehicleNumber'] ?? ''}'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          if (loads.isEmpty)
            Text(l10n.noLoadsForToday)
          else
            ...loads.map(
              (Map<String, dynamic> l) {
                final String? raw = l['product']?['name']?.toString();
                final String title = raw == null || raw.trim().isEmpty
                    ? l10n.product
                    : catalogProductArabicDisplayLabel(raw);
                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(
                    l10n.loadQuantitiesLine(
                      '${l['quantityLoaded']}',
                      '${l['quantitySold']}',
                      '${l['quantityReturned']}',
                      '${l['remaining']}',
                    ),
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}
