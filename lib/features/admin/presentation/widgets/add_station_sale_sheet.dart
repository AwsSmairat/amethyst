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

  final List<TextEditingController> _qtyCtrls =
      List<TextEditingController>.generate(
    _colCount,
    (_) => TextEditingController(),
  );
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

  @override
  void dispose() {
    for (final TextEditingController c in _qtyCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<({String productId, int quantity, double unitPrice})>? _collectLines() {
    final l10n = context.l10n;
    final List<({String productId, int quantity, double unitPrice})> lines =
        <({String productId, int quantity, double unitPrice})>[];
    for (var i = 0; i < _colCount; i++) {
      final String? pid = _productIds[i];
      final String raw = _qtyCtrls[i].text.trim();
      final double? unit = _unitPrices[i];
      if (pid == null && raw.isEmpty) {
        continue;
      }
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vehicleLoadInvalidRow)),
        );
        return null;
      }
      final int? q = int.tryParse(raw);
      if (q == null || q < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vehicleLoadInvalidRow)),
        );
        return null;
      }
      if (unit == null || unit <= 0) {
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
                            quantityController: _qtyCtrls[i],
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
    required this.quantityController,
    required this.busy,
  });

  final int index;
  final String productLabel;
  final TextEditingController quantityController;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.productRow(index + 1),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: quantityController,
          enabled: !busy,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: l10n.quantity,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
          ),
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
