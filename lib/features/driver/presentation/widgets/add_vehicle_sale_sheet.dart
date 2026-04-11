import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
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
  static const List<String> _kHomeProductNames = <String>[
    'Water Gallon',
    'Water Bottle',
    'Water Carton',
    'Coupon',
    'Coupon 2',
    'Coupon 3',
  ];

  /// أسماء المنتجات في الـ API — مطابقة لقوالب السوبر أدمن وصف التحميل.
  static const List<String> _kStoreProductNames = <String>[
    'جالون متجر',
    'قاروره متجر',
    'مهدي متجر',
  ];

  /// مطابقة [server/src/services/vehicleSale.service.js] `STORE_CANONICAL_NAME_LISTS['مهدي متجر']`.
  /// مخزون المحطة والمتبقي على السيارة لهذا البند يُحسبان من هذه الأسماء وليس من صف «مهدي متجر» لو كان ID منفصلاً.
  static const List<String> _kStoreMahdiCanonicalProductNames = <String>[
    'Water Carton',
    'Carton Mahdi',
    'ك مهدي',
    'مهدي (كرتون)',
  ];

  int _columnCount = 6;
  List<int> _quantities = List<int>.filled(6, 0);
  List<String?> _productIds = List<String?>.filled(6, null);
  List<String> _productLabels = List<String>.filled(6, '');
  List<double?> _unitPrices = List<double?>.filled(6, null);
  List<int> _stationStocks = List<int>.filled(6, 0);

  /// قائمة المنتجات من الـ API (بحث بالاسم مع تطبيع بسيط).
  List<Map<String, dynamic>> _productItems = <Map<String, dynamic>>[];

  /// لقطة متبقي حمولة السائق الحالية (من `/vehicle-loads/driver/current`).
  /// مفتاحها اسم المنتج بعد التطبيع (لأنه قد يختلف حسب قالب البيع "متجر").
  Map<String, int> _vehicleLoadRemainingByNormalizedName = <String, int>{};

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
        final Map<String, int> remainingByName = <String, int>{};
        for (final Map<String, dynamic> l in loads) {
          final String k = normalizeStationBalanceProductName(
            (l['product'] as Map<String, dynamic>?)?['name']?.toString() ?? '',
          );
          if (k.trim().isEmpty) {
            continue;
          }
          final int r = (l['remaining'] as int?) ?? 0;
          remainingByName[k] = (remainingByName[k] ?? 0) + r;
        }
        _vehicleLoadRemainingByNormalizedName = remainingByName;
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
    _productLabels = List<String>.filled(_columnCount, '');
    _unitPrices = List<double?>.filled(_columnCount, null);
    _stationStocks = List<int>.filled(_columnCount, 0);
    for (var i = 0; i < _columnCount; i++) {
      final String name = names[i];
      final match = _findProductByCatalogName(name);
      _productIds[i] = match?['id']?.toString();
      _productLabels[i] = match?['name']?.toString().trim() ?? name;
      _unitPrices[i] = parseDynamicDouble(match?['price']);
      if (place == VehicleSalePlace.store && i == 2) {
        _stationStocks[i] = _storeMahdiStationStockFromCatalog();
      } else {
        _stationStocks[i] =
            stationStockFromProductJson(match ?? <String, dynamic>{});
      }
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

  String _arabicLabelForCatalogName(String raw) {
    final String name = raw.trim();
    return switch (name) {
      'Water Gallon' => 'جالون',
      'Water Bottle' => 'قارورة',
      'Water Carton' => 'كرتون',
      'Coupon' => 'كوبون',
      'Coupon 2' => 'كوبون 2',
      'Coupon 3' => 'كوبون 3',
      // "متجر" أصلاً عربية في القالب.
      _ => name,
    };
  }

  int _vehicleRemainingForColumn(int columnIndex) {
    final place = _selectedPlace;
    if (place == null) return 0;

    // ربط أعمدة الشاشة باسم حمولة السيارة الحقيقي (driverCurrentLoad).
    // - منزل: أول 3 أعمدة = Water Gallon/Bottle/Carton
    // - متجر: الأعمدة 0..2 تستهلك من Water Gallon/Bottle/Carton
    final String loadName = switch (place) {
      VehicleSalePlace.home => switch (columnIndex) {
          0 => 'Water Gallon',
          1 => 'Water Bottle',
          2 => 'Water Carton',
          _ => '',
        },
      VehicleSalePlace.store => switch (columnIndex) {
          0 => 'Water Gallon',
          1 => 'Water Bottle',
          2 => 'Water Carton',
          _ => '',
        },
    };

    if (loadName.isEmpty) return 0;

    // الكرتون قد يُحمَّل كـ Water Carton أو «ك مهدي» — نجمع المتبقي لكل المرشّحات.
    if (columnIndex == 2) {
      var sum = 0;
      for (final String c in _kStoreMahdiCanonicalProductNames) {
        final String k = normalizeStationBalanceProductName(c);
        sum += _vehicleLoadRemainingByNormalizedName[k] ?? 0;
      }
      return sum;
    }

    final String key = normalizeStationBalanceProductName(loadName);
    return _vehicleLoadRemainingByNormalizedName[key] ?? 0;
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

  void _adjustQuantity(int index, int delta) {
    setState(() {
      final next = _quantities[index] + delta;
      _quantities[index] = next < 0 ? 0 : next;
    });
  }

  String _columnTitle(BuildContext context, int index) {
    final label = _productLabels[index];
    final String base = label.isNotEmpty ? label : '—';
    // عرض اسم عربي ثابت لمنتجات المنزل، وباقي الحالات نترك اسم المنتج كما هو من الـ API.
    return _selectedPlace == VehicleSalePlace.home
        ? _arabicLabelForCatalogName(base)
        : base;
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
      final int available = storeStationStockDeduct
          ? _storeMahdiStationStockFromCatalog()
          : (i < _stationStocks.length ? _stationStocks[i] : 0);
      if (needsStationStockCheck && q > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.stationSaleValidationInsufficientStock)),
        );
        return null;
      }

      // تحقق من حمولة السيارة عند البيع للمتجر (الكرتون = مجموع أسماء الكنسي).
      if (_selectedPlace == VehicleSalePlace.store && i >= 0 && i <= 2) {
        final int rem = _vehicleRemainingForColumn(i);
        if (q > rem) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.stationSaleValidationInsufficientStock)),
          );
          return null;
        }
      }

      final bool couponPriceZero =
          _selectedPlace == VehicleSalePlace.home &&
              ((i == 0 && _homeCouponLine1On) ||
                  (i == 1 && _homeCouponLine2On));
      // بيع «متجر» للكرتون: السيرفر يخصم مخزون المحطة من المنتج الكنسي على الحمولة — لا نُرسل PATCH لصف «مهدي متجر».
      lines.add(
        (
          productId: pid,
          quantity: q,
          unitPrice: couponPriceZero ? 0.0 : unit,
          deductStationStock: homeStationStockDeduct,
          stationStockSnapshot: available,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (var i = 0; i < _columnCount; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: i == 0 ? 0 : 4,
                              end: i == _columnCount - 1 ? 0 : 4,
                            ),
                            child: _VehicleSaleColumn(
                              index: i,
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
                        ),
                    ],
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

class _VehicleSaleColumn extends StatelessWidget {
  const _VehicleSaleColumn({
    required this.index,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.productRow(index + 1),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          productLabel,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'المتبقي: $vehicleRemaining',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.quantity,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton.filledTonal(
              onPressed: busy || quantity <= 0 ? null : onDecrement,
              icon: const Icon(Icons.remove, size: 16),
              iconSize: 16,
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: const Size(26, 26),
                fixedSize: const Size(26, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
            IconButton.filledTonal(
              onPressed: busy ? null : onIncrement,
              icon: const Icon(Icons.add, size: 16),
              iconSize: 16,
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: const Size(26, 26),
                fixedSize: const Size(26, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (showHomeCouponButton && onHomeCouponToggle != null) ...<Widget>[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onHomeCouponToggle,
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    homeCouponActive ? AppColors.success : Colors.transparent,
                foregroundColor: homeCouponActive
                    ? Colors.white
                    : theme.colorScheme.primary,
                side: BorderSide(
                  color: homeCouponActive
                      ? AppColors.success
                      : AppColors.outlineVariant,
                  width: homeCouponActive ? 2 : 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.couponButton,
                style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
