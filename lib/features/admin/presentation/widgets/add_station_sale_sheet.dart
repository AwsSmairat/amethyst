import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/station_sale_submit_cubit.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showAddStationSaleSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => BlocProvider(
      create: (_) => StationSaleSubmitCubit(sl<CreateStationSaleUseCase>()),
      child: const _AddStationSaleBody(),
    ),
  );
}

class _AddStationSaleBody extends StatefulWidget {
  const _AddStationSaleBody();

  @override
  State<_AddStationSaleBody> createState() => _AddStationSaleBodyState();
}

class _AddStationSaleBodyState extends State<_AddStationSaleBody> {
  static const int _colCount = 3;

  static const List<String> _kFixedProductNames = <String>[
    'Water Gallon',
    'Water Bottle',
    'Water Carton',
  ];

  final List<int> _quantities = List<int>.filled(_colCount, 0);
  final List<String?> _productIds = List<String?>.filled(_colCount, null);
  final List<String> _productLabels = List<String>.filled(_colCount, '');
  final List<double?> _unitPrices = List<double?>.filled(_colCount, null);

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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
      setState(() {
        for (var i = 0; i < _colCount; i++) {
          final String name =
              i < _kFixedProductNames.length ? _kFixedProductNames[i] : '';
          final Map<String, dynamic>? match =
              name.isNotEmpty ? byName[name] : null;
          _productIds[i] = match?['id'] as String?;
          _productLabels[i] = match?['name']?.toString() ?? name;
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

  void _adjustQuantity(int index, int delta) {
    setState(() {
      final int next = _quantities[index] + delta;
      _quantities[index] = next < 0 ? 0 : next;
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
                            start: i == 0 ? 0 : 6,
                            end: i == _colCount - 1 ? 0 : 6,
                          ),
                          child: _StationSaleColumn(
                            index: i,
                            productLabel: _productLabels[i],
                            quantity: _quantities[i],
                            onDecrement: () => _adjustQuantity(i, -1),
                            onIncrement: () => _adjustQuantity(i, 1),
                            busy: busy,
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
  });

  final int index;
  final String productLabel;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool busy;

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
      ],
    );
  }
}

double? _parsePrice(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
