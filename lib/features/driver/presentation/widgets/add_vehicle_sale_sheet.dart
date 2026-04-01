import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
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
          VehicleSaleSubmitCubit(sl<CreateVehicleSaleUseCase>()),
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
  static const int _colCount = 4;

  static const List<String> _kFixedProductNames = <String>[
    'Water Gallon',
    'Water Bottle',
    'Water Carton',
    'Coupon',
  ];

  final List<int> _quantities = List<int>.filled(_colCount, 0);
  final List<String?> _productIds = List<String?>.filled(_colCount, null);
  final List<String> _productLabels = List<String>.filled(_colCount, '');
  final List<double?> _unitPrices = List<double?>.filled(_colCount, null);

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

  Future<void> _load() async {
    try {
      final api = sl<AmethystApi>();
      final dash = await api.getDashboardDriver();
      final vehicle = dash['assignedVehicle'] as Map<String, dynamic>?;
      final products = await api.listProducts();
      final items = (products['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final byName = <String, Map<String, dynamic>>{};
      for (final pr in items) {
        final n = pr['name']?.toString();
        if (n != null) byName[n] = pr;
      }
      if (!mounted) return;
      setState(() {
        _vehicleId = vehicle?['id'] as String?;
        for (var i = 0; i < _colCount; i++) {
          final name =
              i < _kFixedProductNames.length ? _kFixedProductNames[i] : '';
          final match = name.isNotEmpty ? byName[name] : null;
          _productIds[i] = match?['id'] as String?;
          _productLabels[i] = match?['name']?.toString() ?? name;
          _unitPrices[i] = _parsePrice(match?['price']);
        }
        _loadingCtx = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _ctxError = e.toString();
        _loadingCtx = false;
      });
    }
  }

  void _adjustQuantity(int index, int delta) {
    setState(() {
      final next = _quantities[index] + delta;
      _quantities[index] = next < 0 ? 0 : next;
    });
  }

  String _columnTitle(BuildContext context, int index) {
    if (index == _colCount - 1) {
      return context.l10n.couponProduct;
    }
    final label = _productLabels[index];
    return label.isNotEmpty ? label : '—';
  }

  List<({String productId, int quantity, double unitPrice})>? _collectLines() {
    final l10n = context.l10n;
    final lines = <({String productId, int quantity, double unitPrice})>[];
    for (var i = 0; i < _colCount; i++) {
      final pid = _productIds[i];
      final q = _quantities[i];
      final unit = _unitPrices[i];
      if (q <= 0) continue;
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vehicleLoadInvalidRow)),
        );
        return null;
      }
      if (unit == null || unit < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkQtyPrice)),
        );
        return null;
      }
      lines.add((productId: pid, quantity: q, unitPrice: unit));
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
                      for (var i = 0; i < _colCount; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: i == 0 ? 0 : 4,
                              end: i == _colCount - 1 ? 0 : 4,
                            ),
                            child: _VehicleSaleColumn(
                              index: i,
                              productLabel: _columnTitle(context, i),
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
                            context.read<VehicleSaleSubmitCubit>().submitLines(
                                  vehicleId: _vehicleId!,
                                  lines: lines,
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

double? _parsePrice(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
