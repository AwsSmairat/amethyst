import 'package:amethyst/core/data/amethyst_api.dart';
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
  final _qty = TextEditingController();
  String? _vehicleId;
  String? _driverId;
  String? _productId;
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _vehicles = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _drivers = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _products = <Map<String, dynamic>>[];
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
      setState(() {
        _vehicles = vehicles;
        _drivers = drivers;
        _products = products;
        _vehicleId = vehicles.isNotEmpty ? vehicles.first['id'] as String? : null;
        _driverId = drivers.isNotEmpty ? drivers.first['id'] as String? : null;
        _productId =
            products.isNotEmpty ? products.first['id'] as String? : null;
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
    _qty.dispose();
    super.dispose();
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
              const SnackBar(content: Text('Load created')),
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
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'New vehicle load',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle'),
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
                  decoration: const InputDecoration(labelText: 'Driver'),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _productId,
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: _products
                      .map(
                        (x) => DropdownMenuItem<String>(
                          value: x['id'] as String,
                          child: Text(x['name']?.toString() ?? ''),
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
                  decoration: const InputDecoration(labelText: 'Quantity loaded'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Load date'),
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
                          final q = int.tryParse(_qty.text.trim());
                          if (q == null ||
                              q < 1 ||
                              _vehicleId == null ||
                              _driverId == null ||
                              _productId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fill all fields')),
                            );
                            return;
                          }
                          context.read<VehicleLoadSubmitCubit>().submit(
                                vehicleId: _vehicleId!,
                                driverId: _driverId!,
                                productId: _productId!,
                                quantityLoaded: q,
                                loadDate: dateStr,
                              );
                        },
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create load'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
