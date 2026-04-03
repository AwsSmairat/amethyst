import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/utils/parse_quantity_input.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/vehicle_load_submit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

Future<void> showAddVehicleLoadSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => BlocProvider(
      create: (_) =>
          VehicleLoadSubmitCubit(sl<CreateVehicleLoadUseCase>()),
      child: const _AddVehicleLoadBody(),
    ),
  );
}

class _AddVehicleLoadBody extends StatefulWidget {
  const _AddVehicleLoadBody();

  @override
  State<_AddVehicleLoadBody> createState() => _AddVehicleLoadBodyState();
}

class _AddVehicleLoadBodyState extends State<_AddVehicleLoadBody> {
  static const int _rowCount = 6;

  /// ترتيب ثابت لأسماء المنتجات (كما في الخادم) — بدون قوائم اختيار.
  /// ثلاثة أصناف كوبون (١٢ / ٢٤ / ٥٠): أنشئ منتجات `Coupon` و `Coupon 2` و `Coupon 3`.
  static const List<String> _kFixedProductNames = <String>[
    'Water Gallon',
    'Water Bottle',
    'Water Carton',
    'Coupon',
    'Coupon 2',
    'Coupon 3',
  ];

  final List<TextEditingController> _qtyCtrls =
      List<TextEditingController>.generate(
    _rowCount,
    (_) => TextEditingController(),
  );
  final List<String?> _productIds = List<String?>.filled(_rowCount, null);
  final List<String> _productLabels = List<String>.filled(_rowCount, '');

  String? _vehicleId;
  String? _driverId;
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _vehicles = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _drivers = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = sl<AmethystApi>();
      final v = await api.listVehicles();
      final u = await api.listUsers();
      final p = await api.listProducts();
      final vehicles = (v['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final users = (u['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final drivers =
          users.where((e) => e['role'] == 'driver').toList(growable: false);
      final products = (p['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      if (!mounted) return;
      final Map<String, Map<String, dynamic>> byName =
          <String, Map<String, dynamic>>{};
      for (final Map<String, dynamic> pr in products) {
        final String? n = pr['name']?.toString();
        if (n != null) byName[n] = pr;
      }
      setState(() {
        _vehicles = vehicles;
        _drivers = drivers;
        _vehicleId = vehicles.isNotEmpty ? vehicles.first['id'] as String? : null;
        _driverId = drivers.isNotEmpty ? drivers.first['id'] as String? : null;
        for (var i = 0; i < _rowCount; i++) {
          final String fixedName =
              i < _kFixedProductNames.length ? _kFixedProductNames[i] : '';
          final Map<String, dynamic>? match =
              fixedName.isNotEmpty ? byName[fixedName] : null;
          _productIds[i] = match?['id'] as String?;
          _productLabels[i] =
              match?['name']?.toString() ?? fixedName;
        }
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
  void dispose() {
    for (final c in _qtyCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _productRowTitle(BuildContext context, int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.vehicleLoadRowGallon,
      1 => l10n.vehicleLoadRowBottle,
      2 => l10n.vehicleLoadRowCarton,
      3 => l10n.vehicleLoadCouponBook1,
      4 => l10n.vehicleLoadCouponBook2,
      5 => l10n.vehicleLoadCouponBook3,
      _ => l10n.productRow(index + 1),
    };
  }

  List<({String productId, int quantityLoaded})>? _collectLines() {
    final l10n = context.l10n;
    final lines = <({String productId, int quantityLoaded})>[];
    for (var i = 0; i < _rowCount; i++) {
      final String? pid = _productIds[i];
      final String raw = _qtyCtrls[i].text.trim();
      // صف غير مستخدم: فارغ أو ٠ — لا يُشترط تعبئة كل المنتجات.
      if (raw.isEmpty) {
        continue;
      }
      final int? q = parseLoosePositiveIntField(raw);
      if (q == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vehicleLoadInvalidRow)),
        );
        return null;
      }
      if (q <= 0) {
        continue;
      }
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vehicleLoadInvalidRow)),
        );
        return null;
      }
      lines.add((productId: pid, quantityLoaded: q));
    }
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleLoadNeedOneLine)),
      );
      return null;
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: bottom + 20, top: 8),
      child: BlocConsumer<VehicleLoadSubmitCubit, SubmitState>(
        listener: (context, state) {
          if (state is SubmitSuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.loadsRecorded)),
            );
          }
          if (state is SubmitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final busy = state is SubmitLoading;
          if (_loading) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_error != null) {
            return Text(_error!);
          }
          final dateStr = DateFormat('yyyy-MM-dd').format(_date);
          final l10n = context.l10n;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.newVehicleLoad,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _vehicleId,
                  decoration: InputDecoration(labelText: l10n.vehicleField),
                  items: _vehicles
                      .map(
                        (x) => DropdownMenuItem<String>(
                          value: x['id'] as String,
                          child: Text(x['vehicleNumber']?.toString() ?? ''),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: busy
                      ? null
                      : (v) => setState(() => _vehicleId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _driverId,
                  decoration: InputDecoration(labelText: l10n.driverField),
                  items: _drivers
                      .map(
                        (x) => DropdownMenuItem<String>(
                          value: x['id'] as String,
                          child: Text(x['fullName']?.toString() ?? ''),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: busy
                      ? null
                      : (v) => setState(() => _driverId = v),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.vehicleLoadProductsSection,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _rowCount; i++) ...<Widget>[
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: _productRowTitle(context, i),
                      alignLabelWithHint: true,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Text(
                        _productLabels[i].isNotEmpty
                            ? _productLabels[i]
                            : '—',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qtyCtrls[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: l10n.quantityLoaded,
                    ),
                  ),
                  if (i < _rowCount - 1) const SizedBox(height: 16),
                ],
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.loadDate),
                  subtitle: Text(dateStr),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: busy
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _date = picked);
                          }
                        },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () {
                          if (_vehicleId == null ||
                              _driverId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.fillAllFields)),
                            );
                            return;
                          }
                          final lines = _collectLines();
                          if (lines == null) return;
                          context.read<VehicleLoadSubmitCubit>().submitLines(
                                vehicleId: _vehicleId!,
                                driverId: _driverId!,
                                loadDate: dateStr,
                                lines: lines,
                              );
                        },
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.createLoad),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
