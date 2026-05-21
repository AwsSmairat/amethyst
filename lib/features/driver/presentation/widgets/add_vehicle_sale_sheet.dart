import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_product_columns.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_catalog.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/vehicle_sale_submit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum VehicleSalePlace {
  home,
  store,
}

Future<void> showAddVehicleSaleSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => BlocProvider(
      create: (_) =>
          VehicleSaleSubmitCubit(
            sl<CreateVehicleSaleUseCase>(),
            sl<PatchProductStationStockUseCase>(),
          ),
      child: const _AddVehicleSaleBody(),
    ),
  );
}

class _AddVehicleSaleBody extends StatefulWidget {
  const _AddVehicleSaleBody();

  @override
  State<_AddVehicleSaleBody> createState() => _AddVehicleSaleBodyState();
}

class _AddVehicleSaleBodyState extends State<_AddVehicleSaleBody> {
  static const List<String> _kHomeProductNames = kVehicleHomeProductApiNames;

  /// أسماء المنتجات في الـ API — مطابقة لقوالب السوبر أدمن وصف التحميل.
  static const List<String> _kStoreProductNames = kVehicleStoreProductApiNames;

  static const List<String> _kStoreMahdiCanonicalProductNames =
      kVehicleStoreMahdiStockNameCandidates;

  int _columnCount = 6;
  List<int> _quantities = List<int>.filled(6, 0);
  List<String?> _productIds = List<String?>.filled(6, null);
  List<String?> _stockProductIds = List<String?>.filled(6, null);
  List<String> _productLabels = List<String>.filled(6, '');
  List<double?> _unitPrices = List<double?>.filled(6, null);
  List<int> _stationStocks = List<int>.filled(6, 0);

  /// قائمة المنتجات من الـ API (بحث بالاسم مع تطبيع بسيط).
  List<Map<String, dynamic>> _productItems = <Map<String, dynamic>>[];

  /// أسطر حمولة السائق الحالية (من `driverCurrentLoad`).
  List<Map<String, dynamic>> _driverLoadLines = <Map<String, dynamic>>[];

  String? _vehicleId;
  bool _loadingCtx = true;
  String? _ctxError;

  VehicleSalePlace? _selectedPlace;

  /// أزرار كوبون منفصلة لمنتج 1 و2 عند البيع من المنزل (لا تربط بعمود دفتر الكوبون).
  bool _homeCouponLine1On = false;
  bool _homeCouponLine2On = false;

  void _toggleHomeCouponLine(int productIndex) {
    if (productIndex != 0 && productIndex != 1) return;
    setState(() {
      if (productIndex == 0) {
        _homeCouponLine1On = !_homeCouponLine1On;
      } else {
        _homeCouponLine2On = !_homeCouponLine2On;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  static Future<List<Map<String, dynamic>>> _fetchAllProducts(
    AmethystApi api,
  ) async {
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    var page = 1;
    const int limit = 100;
    while (true) {
      final Map<String, dynamic> p =
          await api.listProducts(page: page, limit: limit);
      final List<Map<String, dynamic>> items =
          (p['items'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      all.addAll(items);
      final int total = switch (p['total']) {
        final int t => t,
        final num t => t.toInt(),
        _ => all.length,
      };
      if (items.length < limit || all.length >= total) {
        break;
      }
      page++;
    }
    return all;
  }

  Future<void> _load() async {
    try {
      final api = sl<AmethystApi>();
      final dash = await api.getDashboardDriver();
      final vehicle = dash['assignedVehicle'] as Map<String, dynamic>?;
      final items = await _fetchAllProducts(api);
      final currentLoad = await api.driverCurrentLoad();
      final loads = (currentLoad['loads'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _vehicleId = vehicle?['id'] as String?;
        _productItems = items;
        _driverLoadLines = loads;
        _loadingCtx = false;
        if (_selectedPlace != null) {
          _applyPlaceBindings(_selectedPlace!);
        }
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _ctxError = e.toString();
        _loadingCtx = false;
      });
    }
  }

  void _applyPlaceBindings(VehicleSalePlace place) {
    final names = place == VehicleSalePlace.store
        ? _kStoreProductNames
        : _kHomeProductNames;
    _columnCount = names.length;
    _quantities = List<int>.filled(_columnCount, 0);
    _productIds = List<String?>.filled(_columnCount, null);
    _stockProductIds = List<String?>.filled(_columnCount, null);
    _productLabels = List<String>.filled(_columnCount, '');
    _unitPrices = List<double?>.filled(_columnCount, null);
    _stationStocks = List<int>.filled(_columnCount, 0);
    for (var i = 0; i < _columnCount; i++) {
      final String name = names[i];
      Map<String, dynamic>? match;
      if (place == VehicleSalePlace.store && i == 2) {
        final Map<String, dynamic>? storeSale =
            resolveStoreMahdiSaleProduct(products: _productItems) ??
                _findProductByCatalogName(name);
        final String? stockId =
            resolveMahdiCartonStockProductId(products: _productItems);
        _productIds[i] = storeSale?['id']?.toString();
        _stockProductIds[i] = stockId;
        _productLabels[i] = kStoreMahdiProductApiName;
        _unitPrices[i] = parseDynamicDouble(storeSale?['price']);
        _stationStocks[i] = _storeMahdiStationStockFromCatalog();
        continue;
      }
      if (i < kVehicleLoadFixedRowCount && place == VehicleSalePlace.home) {
        match = resolveVehicleLoadRowProduct(
          products: _productItems,
          rowIndex: i,
        );
      }
      match ??= _findProductByCatalogName(name);
      final String? pid = match?['id']?.toString();
      _stockProductIds[i] = pid;
      if (place == VehicleSalePlace.home && i == 2) {
        _stationStocks[i] = aggregateStationStockForBalanceRow(
          products: _productItems,
          rowIndex: 0,
        );
      } else if (place == VehicleSalePlace.home && i >= 3 && i <= 5) {
        _stationStocks[i] = aggregateStationStockForBalanceRow(
          products: _productItems,
          rowIndex: 8 + i,
        );
      } else {
        _stationStocks[i] =
            stationStockFromProductJson(match ?? <String, dynamic>{});
      }
      _productIds[i] = pid;
      _productLabels[i] = place == VehicleSalePlace.home
          ? vehicleProductDisplayLabel(VehicleProductColumnPlace.home, i)
          : (match?['name']?.toString().trim() ?? name);
      _unitPrices[i] = parseDynamicDouble(match?['price']);
    }
  }

  /// مخزون المحطة لبند «مهدي متجر»: جمع مخزون كل أسماء صف الكرتون في كتالوج المحطة (مطابقة مرنة).
  int _storeMahdiStationStockFromCatalog() {
    final int rowSum = aggregateStationStockForBalanceRow(
      products: _productItems,
      rowIndex: 0,
    );
    if (rowSum > 0) {
      return rowSum;
    }
    for (final Map<String, dynamic> p in _productItems) {
      if (p['isActive'] == false) {
        continue;
      }
      final String ut =
          (p['unitType'] ?? p['type'])?.toString().trim().toLowerCase() ?? '';
      if (ut != 'carton') {
        continue;
      }
      final String raw = p['name']?.toString() ?? '';
      if (raw.contains('مهدي') || raw.toLowerCase().contains('mahdi')) {
        return stationStockFromProductJson(p);
      }
    }
    var sum = 0;
    final Set<String> seen = <String>{};
    for (final String n in _kStoreMahdiCanonicalProductNames) {
      final Map<String, dynamic>? m = _findProductByCatalogName(n);
      final String? id = m?['id']?.toString();
      if (m == null || id == null || seen.contains(id)) {
        continue;
      }
      seen.add(id);
      sum += stationStockFromProductJson(m);
    }
    return sum;
  }

  List<String> _loadNameCandidatesForColumn(int columnIndex) {
    final VehicleSalePlace? place = _selectedPlace;
    if (place == null) {
      return <String>[];
    }
    return switch (place) {
      VehicleSalePlace.home => columnIndex < kVehicleLoadFixedRowCount
          ? <String>[
              kVehicleLoadFixedApiNames[columnIndex],
              ...vehicleLoadNameCandidatesForRow(columnIndex),
            ]
          : <String>[],
      VehicleSalePlace.store => switch (columnIndex) {
          0 => vehicleLoadNameCandidatesForRow(0),
          1 => vehicleLoadNameCandidatesForRow(1),
          2 => <String>[
            ...kMahdiCartonStockNameCandidates,
            ..._kStoreMahdiCanonicalProductNames,
            if (_kStoreProductNames.length > 2) _kStoreProductNames[2],
          ],
          _ => <String>[],
        },
    };
  }

  int _vehicleRemainingForColumn(int columnIndex) {
    if (_selectedPlace == null || _driverLoadLines.isEmpty) {
      return 0;
    }

    final String? stockId = columnIndex < _stockProductIds.length
        ? _stockProductIds[columnIndex]
        : null;
    final String? columnProductId = stockId ?? _productIds[columnIndex];
    if (columnProductId != null && columnProductId.isNotEmpty) {
      var fromProductId = 0;
      for (final Map<String, dynamic> line in _driverLoadLines) {
        if (line['productId']?.toString() == columnProductId) {
          fromProductId += (line['remaining'] as int?) ?? 0;
        }
      }
      if (fromProductId > 0) {
        return fromProductId;
      }
    }

    final List<String> candidates = _loadNameCandidatesForColumn(columnIndex);
    if (candidates.isEmpty) {
      return 0;
    }

    var sum = 0;
    for (final Map<String, dynamic> line in _driverLoadLines) {
      final String loadName =
          (line['product'] as Map<String, dynamic>?)?['name']?.toString() ??
              '';
      if (loadName.isEmpty) {
        continue;
      }
      for (final String candidate in candidates) {
        if (stationBalanceProductNamesMatch(loadName, candidate)) {
          sum += (line['remaining'] as int?) ?? 0;
          break;
        }
      }
    }
    return sum;
  }

  /// يطابق اسم القالب مع `products.name` بعد `trim` (وتطابق حالة الأحرف للأسماء اللاتينية).
  /// يُفضَّل منتج نشط فقط؛ البيع من السيرفر يُرفض إن كان المنتج غير نشط.
  Map<String, dynamic>? _findProductByCatalogName(String requestedName) {
    final String want = requestedName.trim();
    if (want.isEmpty) {
      return null;
    }
    for (final Map<String, dynamic> pr in _productItems) {
      if (pr['isActive'] == false) {
        continue;
      }
      final String? n = pr['name']?.toString().trim();
      if (n != null && n == want) {
        return pr;
      }
    }
    final String wantLower = want.toLowerCase();
    for (final Map<String, dynamic> pr in _productItems) {
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

  int _stationStockForColumn(int columnIndex) {
    if (_selectedPlace == VehicleSalePlace.store && columnIndex == 2) {
      return _storeMahdiStationStockFromCatalog();
    }
    if (_selectedPlace == VehicleSalePlace.home) {
      if (columnIndex == 2) {
        return aggregateStationStockForBalanceRow(
          products: _productItems,
          rowIndex: 0,
        );
      }
      if (columnIndex >= 3 && columnIndex <= 5) {
        return aggregateStationStockForBalanceRow(
          products: _productItems,
          rowIndex: 8 + columnIndex,
        );
      }
    }
    return columnIndex < _stationStocks.length ? _stationStocks[columnIndex] : 0;
  }

  /// أقصى كمية للبيع: الأقل بين متبقي السيارة ومخزون المحطة.
  int _maxSellableQuantity(int columnIndex) {
    final bool homeRows =
        _selectedPlace == VehicleSalePlace.home &&
            columnIndex >= 2 &&
            columnIndex <= 5;
    final bool storeMahdi =
        _selectedPlace == VehicleSalePlace.store && columnIndex == 2;
    if (!homeRows && !storeMahdi) {
      return 999999;
    }
    final int onVehicle = _vehicleRemainingForColumn(columnIndex);
    final int atStation = _stationStockForColumn(columnIndex);
    return onVehicle < atStation ? onVehicle : atStation;
  }

  void _adjustQuantity(int index, int delta) {
    setState(() {
      var next = _quantities[index] + delta;
      if (next < 0) {
        next = 0;
      }
      if (_maxSellableQuantity(index) < 999999) {
        final int cap = _maxSellableQuantity(index);
        if (next > cap) {
          next = cap;
        }
      }
      _quantities[index] = next;
    });
  }

  String _columnTitle(BuildContext context, int index) {
    if (_selectedPlace == VehicleSalePlace.home) {
      return vehicleProductDisplayLabel(VehicleProductColumnPlace.home, index);
    }
    final label = _productLabels[index];
    return label.isNotEmpty ? label : '—';
  }

  String _badgeLabel(BuildContext context, int index) {
    if (_selectedPlace == VehicleSalePlace.home) {
      return vehicleProductBadgeLabel(VehicleProductColumnPlace.home, index) ??
          context.l10n.productRow(index + 1);
    }
    return context.l10n.productRow(index + 1);
  }

  List<VehicleSaleLineInput>? _collectLines() {
    final l10n = context.l10n;
    final lines = <VehicleSaleLineInput>[];
    for (var i = 0; i < _columnCount; i++) {
      final pid = _productIds[i];
      final q = _quantities[i];
      final unit = _unitPrices[i];
      if (q <= 0) continue;
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.stationProductNotInCatalog)),
        );
        return null;
      }
      if (unit == null || unit < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkQtyPrice)),
        );
        return null;
      }
      final bool homeStationStockDeduct =
          _selectedPlace == VehicleSalePlace.home && i >= 2 && i <= 5;
      final bool storeStationStockDeduct =
          _selectedPlace == VehicleSalePlace.store && i == 2;
      final bool needsStationStockCheck =
          homeStationStockDeduct || storeStationStockDeduct;
      final int stationAvailable = _stationStockForColumn(i);
      final bool needsVehicleCheck =
          (_selectedPlace == VehicleSalePlace.home && i >= 2 && i <= 5) ||
          (_selectedPlace == VehicleSalePlace.store && i <= 2);

      // أولاً: متبقي السيارة (منتج ٣ متجر = كرتون مهدي على الحمولة).
      if (needsVehicleCheck) {
        final int onVehicle = _vehicleRemainingForColumn(i);
        if (q > onVehicle) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.stationSaleValidationInsufficientStock)),
          );
          return null;
        }
      }

      // ثانياً: مخزون المحطة (مهدي متجر / منتجات ٣–٦ منزل).
      if (needsStationStockCheck && q > stationAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.stationSaleValidationInsufficientStock)),
        );
        return null;
      }

      final bool couponPriceZero =
          _selectedPlace == VehicleSalePlace.home &&
              ((i == 0 && _homeCouponLine1On) ||
                  (i == 1 && _homeCouponLine2On));
      final String? stockPid = i < _stockProductIds.length
          ? _stockProductIds[i]
          : null;
      lines.add(
        (
          productId: pid,
          quantity: q,
          unitPrice: couponPriceZero ? 0.0 : unit,
          deductStationStock:
              homeStationStockDeduct || storeStationStockDeduct,
          stationStockSnapshot: stationAvailable,
          stockProductId: storeStationStockDeduct && i == 2
              ? stockPid
              : (homeStationStockDeduct && i == 2
                  ? stockPid
                  : null),
        ),
      );
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
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottom + 20,
        top: 8,
      ),
      child: BlocConsumer<VehicleSaleSubmitCubit, SubmitState>(
        listener: (context, state) {
          if (state is SubmitSuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.vehicleSalesRecorded)),
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
          if (_loadingCtx) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_ctxError != null) {
            return Text(_ctxError!);
          }
          if (_vehicleId == null) {
            return Text(context.l10n.noVehicleContactAdmin);
          }
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.newVehicleSale,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<VehicleSalePlace?>(
                  value: _selectedPlace,
                  decoration: InputDecoration(
                    labelText: l10n.vehicleSaleChoosePlaceTitle,
                    hintText: l10n.vehicleSaleTapToChoosePlace,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  isExpanded: true,
                  items: <DropdownMenuItem<VehicleSalePlace?>>[
                    DropdownMenuItem<VehicleSalePlace?>(
                      value: VehicleSalePlace.home,
                      child: Text(l10n.vehicleSalePlaceHome),
                    ),
                    DropdownMenuItem<VehicleSalePlace?>(
                      value: VehicleSalePlace.store,
                      child: Text(l10n.vehicleSalePlaceStore),
                    ),
                  ],
                  onChanged: busy
                      ? null
                      : (VehicleSalePlace? v) {
                          if (v == null) return;
                          setState(() {
                            _selectedPlace = v;
                            if (v != VehicleSalePlace.home) {
                              _homeCouponLine1On = false;
                              _homeCouponLine2On = false;
                            }
                            _applyPlaceBindings(v);
                          });
                        },
                ),
                if (_selectedPlace != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _selectedPlace == VehicleSalePlace.home
                        ? l10n.vehicleSaleFromHome
                        : l10n.vehicleSaleFromStore,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.vehicleLoadProductsSection,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _VehicleSaleProductsGrid(
                    columnCount: _columnCount,
                    columnBuilder: (BuildContext context, int i) =>
                        _VehicleSaleColumn(
                      index: i,
                      badgeLabel: _badgeLabel(context, i),
                      productLabel: _columnTitle(context, i),
                      vehicleRemaining: _vehicleRemainingForColumn(i),
                      quantity: _quantities[i],
                      onDecrement: () => _adjustQuantity(i, -1),
                      onIncrement: () => _adjustQuantity(i, 1),
                      busy: busy,
                      showHomeCouponButton:
                          _selectedPlace == VehicleSalePlace.home &&
                              (i == 0 || i == 1),
                      homeCouponActive: i == 0
                          ? _homeCouponLine1On
                          : i == 1
                              ? _homeCouponLine2On
                              : false,
                      onHomeCouponToggle:
                          _selectedPlace == VehicleSalePlace.home &&
                                  (i == 0 || i == 1)
                              ? () => _toggleHomeCouponLine(i)
                              : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () {
                            final lines = _collectLines();
                            if (lines == null) return;
                            context
                                .read<VehicleSaleSubmitCubit>()
                                .submitLinesAndDeductStationStock(
                                  vehicleId: _vehicleId!,
                                  lines: lines,
                                  saleDestination:
                                      _selectedPlace == VehicleSalePlace.store
                                          ? 'store'
                                          : 'home',
                                );
                          },
                    child: busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.addSale),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VehicleSaleProductsGrid extends StatelessWidget {
  const _VehicleSaleProductsGrid({
    required this.columnCount,
    required this.columnBuilder,
  });

  final int columnCount;
  final Widget Function(BuildContext context, int index) columnBuilder;

  static const int _kColumnsPerRow = 3;
  static const double _kColumnGap = 8;

  @override
  Widget build(BuildContext context) {
    if (columnCount <= 0) {
      return const SizedBox.shrink();
    }
    final List<Widget> rows = <Widget>[];
    for (var start = 0; start < columnCount; start += _kColumnsPerRow) {
      final int end = start + _kColumnsPerRow > columnCount
          ? columnCount
          : start + _kColumnsPerRow;
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: _kColumnGap));
      }
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var i = start; i < end; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: i == start ? 0 : _kColumnGap / 2,
                    end: i == end - 1 ? 0 : _kColumnGap / 2,
                  ),
                  child: columnBuilder(context, i),
                ),
              ),
            for (var i = end; i < start + _kColumnsPerRow; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: _kColumnGap / 2,
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _VehicleSaleColumn extends StatelessWidget {
  const _VehicleSaleColumn({
    required this.index,
    required this.badgeLabel,
    required this.productLabel,
    required this.vehicleRemaining,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.busy,
    this.showHomeCouponButton = false,
    this.homeCouponActive = false,
    this.onHomeCouponToggle,
  });

  final int index;
  final String badgeLabel;
  final String productLabel;
  final int vehicleRemaining;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool busy;
  final bool showHomeCouponButton;
  final bool homeCouponActive;
  final VoidCallback? onHomeCouponToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool hasStock = vehicleRemaining > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: Text(
                    badgeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              productLabel.isNotEmpty ? productLabel : '—',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: hasStock
                    ? AppColors.success.withValues(alpha: 0.12)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 14,
                      color: hasStock
                          ? AppColors.success
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.left}: $vehicleRemaining',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                            color: hasStock
                                ? AppColors.success
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.quantity,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: <Widget>[
                    _QuantityStepButton(
                      icon: Icons.remove,
                      onPressed: busy || quantity <= 0 ? null : onDecrement,
                    ),
                    Expanded(
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                      ),
                    ),
                    _QuantityStepButton(
                      icon: Icons.add,
                      onPressed: busy ? null : onIncrement,
                    ),
                  ],
                ),
              ),
            ),
            if (showHomeCouponButton && onHomeCouponToggle != null) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy ? null : onHomeCouponToggle,
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      homeCouponActive ? AppColors.success : Colors.transparent,
                  foregroundColor: homeCouponActive
                      ? Colors.white
                      : scheme.primary,
                  side: BorderSide(
                    color: homeCouponActive
                        ? AppColors.success
                        : AppColors.outlineVariant,
                    width: homeCouponActive ? 2 : 1,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.couponButton,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuantityStepButton extends StatelessWidget {
  const _QuantityStepButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      iconSize: 18,
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        minimumSize: const Size(36, 36),
        fixedSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
