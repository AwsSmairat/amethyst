import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sales_aggregates.dart';
import 'package:amethyst/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// قائمة المركبات مع مبيعات اليوم والشهر؛ الضغط يفتح التفاصيل بحسب اليوم.
class VehicleSalesHubPage extends StatefulWidget {
  const VehicleSalesHubPage({
    super.key,
    required this.shellBase,
  });

  /// `/super-admin` أو `/admin`
  final String shellBase;

  @override
  State<VehicleSalesHubPage> createState() => _VehicleSalesHubPageState();
}

class _VehicleSalesHubPageState extends State<VehicleSalesHubPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _vehicles = <Map<String, dynamic>>[];
  Map<String, VehicleSalesTotals> _salesByVehicle =
      <String, VehicleSalesTotals>{};
  bool _didScheduleInitialLoad = false;
  int _loadGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didScheduleInitialLoad) {
      return;
    }
    _didScheduleInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    final int generation = ++_loadGeneration;
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final AmethystApi api = sl<AmethystApi>();
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        fetchAllVehicleRows(api),
        fetchAllVehicleSaleRows(api),
      ]);
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      final List<Map<String, dynamic>> vehicles =
          results[0] as List<Map<String, dynamic>>;
      final List<Map<String, dynamic>> sales =
          results[1] as List<Map<String, dynamic>>;

      setState(() {
        _vehicles = vehicles;
        _salesByVehicle = summarizeVehicleSalesByVehicleId(sales);
        _loading = false;
        _error = null;
      });
    } on Object catch (e) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _error = errorMessageFrom(e);
        _loading = false;
      });
    }
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  String? _driverSubtitle(BuildContext context, Map<String, dynamic> v) {
    final l10n = context.l10n;
    final Object? driver = v['driver'];
    if (driver is Map<String, dynamic>) {
      final String n = driver['fullName']?.toString() ?? '';
      if (n.isNotEmpty) {
        return '${l10n.driverAssigned}: $n';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleVehicleSales),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : _vehicles.isEmpty
                  ? Center(child: Text(l10n.nothingHereYet))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Text(
                            l10n.vehicleSalesChooseVehicleHint,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        ...List<Widget>.generate(_vehicles.length, (int i) {
                          final Map<String, dynamic> v = _vehicles[i];
                          final String id = v['id']?.toString() ?? '';
                          final String title =
                              v['vehicleNumber']?.toString().trim().isNotEmpty ==
                                      true
                                  ? v['vehicleNumber'].toString().trim()
                                  : id;
                          final String? driverLine =
                              _driverSubtitle(context, v);
                          final VehicleSalesTotals totals =
                              _salesByVehicle[id] ??
                                  const VehicleSalesTotals();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(
                                Icons.local_shipping_outlined,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (driverLine != null &&
                                      driverLine.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Text(driverLine),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.expenseCategoryTodayLine(
                                      l10n.amountDinars(
                                        _formatAmount(totals.today),
                                      ),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.expenseCategoryMonthLine(
                                      l10n.amountDinars(
                                        _formatAmount(totals.month),
                                      ),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () async {
                                if (id.isEmpty) {
                                  return;
                                }
                                await context.push(
                                  '${widget.shellBase}/vehicle-sales/$id',
                                  extra: v,
                                );
                                if (mounted) {
                                  await _load();
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
    );
  }
}
