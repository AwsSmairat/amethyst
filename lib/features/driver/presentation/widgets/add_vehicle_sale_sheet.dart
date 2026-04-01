import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/vehicle_sale_submit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final _qty = TextEditingController();
  final _price = TextEditingController();
  String? _vehicleId;
  String? _productId;
  List<Map<String, dynamic>> _products = <Map<String, dynamic>>[];
  bool _loadingCtx = true;
  String? _ctxError;

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
      if (!mounted) return;
      setState(() {
        _vehicleId = vehicle?['id'] as String?;
        _products = items;
        if (_productId == null && items.isNotEmpty) {
          _productId = items.first['id'] as String?;
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

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: bottom + 20, top: 8),
      child: BlocConsumer<VehicleSaleSubmitCubit, SubmitState>(
        listener: (context, state) {
          if (state is SubmitSuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.saleRecorded)),
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
          final l10n = context.l10n;
          return Column(
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
              DropdownButtonFormField<String>(
                value: _productId,
                decoration: InputDecoration(labelText: l10n.product),
                items: _products
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p['id'] as String,
                        child: Text(p['name']?.toString() ?? ''),
                      ),
                    )
                    .toList(growable: false),
                onChanged: busy
                    ? null
                    : (v) => setState(() => _productId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.quantity),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.unitPrice),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy
                    ? null
                    : () {
                        final q = int.tryParse(_qty.text.trim());
                        final p = double.tryParse(_price.text.trim());
                        if (q == null || q < 1 || p == null || p <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.checkQtyPrice)),
                          );
                          return;
                        }
                        if (_productId == null) return;
                        context.read<VehicleSaleSubmitCubit>().submit(
                              vehicleId: _vehicleId!,
                              productId: _productId!,
                              quantity: q,
                              unitPrice: p,
                            );
                      },
                child: busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.submit),
              ),
            ],
          );
        },
      ),
    );
  }
}
