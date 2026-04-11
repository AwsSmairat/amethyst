import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/utils/parse_quantity_input.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_stock_rules.dart';
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
  /// بيع «متجر» من السيارة يستهلك نفس الحمل (جالون/قارورة/كرتون) بأسعار منفصلة في الخادم.
  /// جالون / قارورة (الصفّان ٠ و١): لا تحقق من مخزون المحطة ولا خصم عند التحميل.
  /// يُكمَّل بالتحقق من `unitType` واسم المنتج ليطابق الخادم إن تغيّر ترتيب العرض أو الاسم في الـ API.
  bool _lineSkipsStationStock(int rowIndex) {
    if (rowIndex == 0 || rowIndex == 1) {
      return true;
    }
    final String unit =
        (_unitTypes[rowIndex] ?? '').toString().trim().toLowerCase();
    if (unit == 'gallon' || unit == 'bottle') {
      return true;
    }
    return productNameSuggestsFillingSkipStock(_productLabels[rowIndex]);
  }

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
  final List<String?> _unitTypes = List<String?>.filled(_rowCount, null);
  final List<int> _stationStocks = List<int>.filled(_rowCount, 0);

  String? _vehicleId;
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _vehicles = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// مطابقة اسم القالب مع `products.name` (trim + حالة الأحرف)، منتج نشط فقط.
  static Map<String, dynamic>? _findProductByCatalogName(
    List<Map<String, dynamic>> items,
    String requestedName,
  ) {
    final String want = requestedName.trim();
    if (want.isEmpty) {
      return null;
    }
    for (final Map<String, dynamic> pr in items) {
      if (pr['isActive'] == false) {
        continue;
      }
      final String? n = pr['name']?.toString().trim();
      if (n != null && n == want) {
        return pr;
      }
    }
    final String wantLower = want.toLowerCase();
    for (final Map<String, dynamic> pr in items) {
      if (pr['isActive'] == false) {
        continue;
      }
      final String? n = pr['name']?.toString().trim();
      if (n != null && n.toLowerCase() == wantLower) {
        return pr;
      }
    }
    return null;
  }

  Future<void> _load() async {
    try {
      final api = sl<AmethystApi>();
      final v = await api.listVehicles();
      final p = await api.listProducts();
      final vehicles = (v['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final products = (p['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _vehicleId = _pickInitialVehicleId(vehicles);
        for (var i = 0; i < _rowCount; i++) {
          final String fixedName =
              i < _kFixedProductNames.length ? _kFixedProductNames[i] : '';
          final Map<String, dynamic>? match = fixedName.isNotEmpty
              ? _findProductByCatalogName(products, fixedName)
              : null;
          _productIds[i] = match?['id'] as String?;
          _productLabels[i] =
              match?['name']?.toString().trim() ?? fixedName;
          _unitTypes[i] = match?['unitType']?.toString() ?? match?['type']?.toString();
          _stationStocks[i] = stationStockFromProductJson(match ?? <String, dynamic>{});
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

  /// أول مركبة فيها سائق معيّن؛ وإلا أول مركبة (لتجنب تعارض مع التحقق في السيرفر).
  static String? _pickInitialVehicleId(List<Map<String, dynamic>> vehicles) {
    if (vehicles.isEmpty) return null;
    for (final Map<String, dynamic> x in vehicles) {
      if (x['driverId'] != null) {
        return x['id'] as String?;
      }
    }
    return vehicles.first['id'] as String?;
  }

  Map<String, dynamic>? _vehicleById(String? id) {
    if (id == null) return null;
    for (final Map<String, dynamic> x in _vehicles) {
      if (x['id'] == id) return x;
    }
    return null;
  }

  String? get _resolvedDriverId =>
      _vehicleById(_vehicleId)?['driverId'] as String?;

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
      if (!_lineSkipsStationStock(i)) {
        final int available =
            i < _stationStocks.length ? _stationStocks[i] : 0;
        if (q > available) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.stationSaleValidationInsufficientStock)),
          );
          return null;
        }
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
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.driverField,
                    alignLabelWithHint: true,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Builder(
                      builder: (BuildContext context) {
                        final Map<String, dynamic>? veh =
                            _vehicleById(_vehicleId);
                        final Map<String, dynamic>? driver =
                            veh?['driver'] as Map<String, dynamic>?;
                        final String name =
                            driver?['fullName']?.toString() ?? l10n.noDriver;
                        final bool hasDriver =
                            veh?['driverId'] != null;
                        return Text(
                          name,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: hasDriver
                                    ? AppColors.primaryText
                                    : Theme.of(context).colorScheme.error,
                              ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.vehicleLoadProductsSection,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                if (_productIds.any((String? id) => id == null)) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    l10n.vehicleLoadCatalogGapHint,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                for (var i = 0; i < _rowCount; i++) ...<Widget>[
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: _productRowTitle(context, i),
                      alignLabelWithHint: true,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            _productLabels[i].isNotEmpty
                                ? _productLabels[i]
                                : '—',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _lineSkipsStationStock(i)
                                ? l10n.vehicleLoadNoStationStockForRow
                                : l10n.stationSaleStockAvailable(
                                    i < _stationStocks.length
                                        ? _stationStocks[i]
                                        : 0,
                                  ),
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ],
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
                          if (_vehicleId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.fillAllFields)),
                            );
                            return;
                          }
                          final String? driverId = _resolvedDriverId;
                          if (driverId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.vehicleHasNoDriverHint),
                              ),
                            );
                            return;
                          }
                          final lines = _collectLines();
                          if (lines == null) return;
                          context.read<VehicleLoadSubmitCubit>().submitLines(
                                vehicleId: _vehicleId!,
                                driverId: driverId,
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
