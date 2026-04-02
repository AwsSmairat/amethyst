import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/station_sale_submit_cubit.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// نوع بيع المحطة قبل فتح نموذج الكميات (لا يُرسل للـ API حالياً — للعرض فقط).
enum StationSaleEntryKind {
  filling,
  emptySale,
}

Future<void> showAddStationSaleSheet(BuildContext context) async {
  final StationSaleEntryKind? kind = await showModalBottomSheet<StationSaleEntryKind>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext ctx) => const _StationSaleKindPicker(),
  );
  if (!context.mounted || kind == null) {
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => BlocProvider(
      create: (_) => StationSaleSubmitCubit(sl<CreateStationSaleUseCase>()),
      child: _AddStationSaleBody(entryKind: kind),
    ),
  );
}

class _StationSaleKindPicker extends StatelessWidget {
  const _StationSaleKindPicker();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.stationSalePickKindTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(StationSaleEntryKind.filling),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: scheme.primary,
            ),
            child: Text(l10n.stationSaleKindFilling),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () =>
                Navigator.of(context).pop(StationSaleEntryKind.emptySale),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.stationSaleKindEmptySale),
          ),
        ],
      ),
    );
  }
}

class _AddStationSaleBody extends StatefulWidget {
  const _AddStationSaleBody({required this.entryKind});

  final StationSaleEntryKind entryKind;

  @override
  State<_AddStationSaleBody> createState() => _AddStationSaleBodyState();
}

class _AddStationSaleBodyState extends State<_AddStationSaleBody> {
  /// تعبئة: ٤ صفوف كما في بيع المركبة (Carton + Coupon في الـ API). بيع فارغ: منتجان فقط.
  int get _colCount =>
      widget.entryKind == StationSaleEntryKind.filling ? 4 : 2;

  /// أسماء المنتجات في الـ API لمطابقة الـ id والسعر (العرض للمستخدم عربي).
  static const List<String> _kFillingApiNames = <String>[
    'Water Gallon',
    'Water Bottle',
    'Water Carton',
    'Coupon',
  ];

  static const List<String> _kEmptySaleApiNames = <String>[
    'Water Gallon',
    'Water Bottle',
  ];

  late List<int> _quantities;
  late List<String?> _productIds;
  late List<String> _productLabels;
  late List<double?> _unitPrices;

  bool _loading = true;
  String? _error;
  bool _withFilling = false;
  /// تعبئة أو بيع فارغ: كوبون تحت منتج ١ و٢ (جالون/قاروره) عند الكمية > 0 (عرض فقط).
  bool _emptySaleCouponLine1On = false;
  bool _emptySaleCouponLine2On = false;

  bool get _showCouponUnderProduct1And2 =>
      widget.entryKind == StationSaleEntryKind.filling ||
      widget.entryKind == StationSaleEntryKind.emptySale;

  @override
  void initState() {
    super.initState();
    final int n = _colCount;
    _quantities = List<int>.filled(n, 0);
    _productIds = List<String?>.filled(n, null);
    _productLabels = List<String>.filled(n, '');
    _unitPrices = List<double?>.filled(n, null);
    _load();
  }

  Future<void> _load() async {
    try {
      final Map<String, dynamic> p = await sl<AmethystApi>().listProducts();
      final List<Map<String, dynamic>> items =
          (p['items'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      final Map<String, Map<String, dynamic>> byName =
          <String, Map<String, dynamic>>{};
      for (final Map<String, dynamic> pr in items) {
        final String? n = pr['name']?.toString();
        if (n != null) byName[n] = pr;
      }
      if (!mounted) return;
      final l10n = context.l10n;
      final List<String> apiNames = widget.entryKind ==
              StationSaleEntryKind.filling
          ? _kFillingApiNames
          : _kEmptySaleApiNames;
      setState(() {
        for (var i = 0; i < _colCount; i++) {
          final String name = i < apiNames.length ? apiNames[i] : '';
          final Map<String, dynamic>? match =
              name.isNotEmpty ? byName[name] : null;
          _productIds[i] = match?['id'] as String?;
          _productLabels[i] = _labelForProductIndex(l10n, i);
          _unitPrices[i] = _parsePrice(match?['price']);
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

  String _labelForProductIndex(AppLocalizations l10n, int i) {
    if (widget.entryKind == StationSaleEntryKind.emptySale) {
      return i == 0
          ? l10n.stationSaleProductGallon
          : l10n.stationSaleProductBottle;
    }
    switch (i) {
      case 0:
        return l10n.stationSaleProductGallon;
      case 1:
        return l10n.stationSaleProductBottle;
      case 2:
        return l10n.stationSaleProductMahdi;
      case 3:
        return l10n.couponProduct;
      default:
        return '';
    }
  }

  Widget _productColumnsRow(
    BuildContext context, {
    required bool busy,
    required int start,
    required int end,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var i = start; i < end; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: i == start ? 0 : 6,
                end: i == end - 1 ? 0 : 6,
              ),
              child: _StationSaleColumn(
                index: i,
                productLabel: _productLabels[i],
                quantity: _quantities[i],
                onDecrement: () => _adjustQuantity(i, -1),
                onIncrement: () => _adjustQuantity(i, 1),
                busy: busy,
                showCouponButton: _showCouponUnderProduct1And2 && i < 2,
                couponActive: i == 0
                    ? _emptySaleCouponLine1On
                    : _emptySaleCouponLine2On,
                onCouponToggle: _showCouponUnderProduct1And2 && i < 2
                    ? () => setState(() {
                          if (i == 0) {
                            _emptySaleCouponLine1On = !_emptySaleCouponLine1On;
                          } else {
                            _emptySaleCouponLine2On = !_emptySaleCouponLine2On;
                          }
                        })
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  void _adjustQuantity(int index, int delta) {
    setState(() {
      final int next = _quantities[index] + delta;
      final int clamped = next < 0 ? 0 : next;
      _quantities[index] = clamped;
      if (clamped == 0 && (index == 0 || index == 1)) {
        if (index == 0) {
          _emptySaleCouponLine1On = false;
        } else {
          _emptySaleCouponLine2On = false;
        }
      }
    });
  }

  List<({String productId, int quantity, double unitPrice})>? _collectLines() {
    final l10n = context.l10n;
    final List<({String productId, int quantity, double unitPrice})> lines =
        <({String productId, int quantity, double unitPrice})>[];
    for (var i = 0; i < _colCount; i++) {
      final String? pid = _productIds[i];
      final int q = _quantities[i];
      final double? unit = _unitPrices[i];
      if (q <= 0) {
        continue;
      }
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
      lines.add(
        (
          productId: pid,
          quantity: q,
          unitPrice: unit,
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
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottom + 20,
        top: 8,
      ),
      child: BlocConsumer<StationSaleSubmitCubit, SubmitState>(
        listener: (BuildContext context, SubmitState state) {
          if (state is SubmitSuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.stationSalesRecorded)),
            );
          }
          if (state is SubmitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (BuildContext context, SubmitState state) {
          final bool busy = state is SubmitLoading;
          final ColorScheme scheme = Theme.of(context).colorScheme;
          if (_loading) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_error != null) {
            return Text(_error!);
          }
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.newStationSale,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.entryKind == StationSaleEntryKind.filling
                      ? l10n.stationSaleKindFilling
                      : l10n.stationSaleKindEmptySale,
                  textAlign: TextAlign.center,
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
                if (widget.entryKind == StationSaleEntryKind.filling &&
                    _colCount == 4) ...<Widget>[
                  _productColumnsRow(
                    context,
                    busy: busy,
                    start: 0,
                    end: 2,
                  ),
                  const SizedBox(height: 12),
                  _productColumnsRow(
                    context,
                    busy: busy,
                    start: 2,
                    end: 4,
                  ),
                ] else
                  _productColumnsRow(
                    context,
                    busy: busy,
                    start: 0,
                    end: _colCount,
                  ),
                if (widget.entryKind == StationSaleEntryKind.emptySale) ...<Widget>[
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => _withFilling = !_withFilling),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: _withFilling
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        foregroundColor: _withFilling
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                      child: Text(l10n.stationSaleWithFilling),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () {
                          final List<
                                  ({
                                    String productId,
                                    int quantity,
                                    double unitPrice
                                  })>? lines =
                              _collectLines();
                          if (lines == null) return;
                          context.read<StationSaleSubmitCubit>().submitLines(
                                lines: lines,
                              );
                        },
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.addStationSale),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StationSaleColumn extends StatelessWidget {
  const _StationSaleColumn({
    required this.index,
    required this.productLabel,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.busy,
    this.showCouponButton = false,
    this.couponActive = false,
    this.onCouponToggle,
  });

  final int index;
  final String productLabel;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool busy;
  final bool showCouponButton;
  final bool couponActive;
  final VoidCallback? onCouponToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
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
          productLabel.isNotEmpty ? productLabel : '—',
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
        if (showCouponButton &&
            quantity > 0 &&
            onCouponToggle != null) ...<Widget>[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onCouponToggle,
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    couponActive ? AppColors.success : Colors.transparent,
                foregroundColor: couponActive
                    ? Colors.white
                    : theme.colorScheme.primary,
                side: BorderSide(
                  color: couponActive
                      ? AppColors.success
                      : AppColors.outlineVariant,
                  width: couponActive ? 2 : 1,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
