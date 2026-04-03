import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_vehicles_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showAddSuperAdminVehicleSheet(BuildContext context) {
  final SuperAdminVehiclesCubit cubit = context.read<SuperAdminVehiclesCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => BlocProvider.value(
      value: cubit,
      child: const _AddVehicleBody(),
    ),
  );
}

class _AddVehicleBody extends StatefulWidget {
  const _AddVehicleBody();

  @override
  State<_AddVehicleBody> createState() => _AddVehicleBodyState();
}

class _AddVehicleBodyState extends State<_AddVehicleBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  String? _driverId;
  List<Map<String, dynamic>> _drivers = <Map<String, dynamic>>[];
  bool _loadingDrivers = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final AmethystApi api = sl<AmethystApi>();
      final Map<String, dynamic> data = await api.listUsers(limit: 100);
      final raw = data['items'];
      final list = <Map<String, dynamic>>[];
      if (raw is List<dynamic>) {
        for (final dynamic e in raw) {
          if (e is Map<String, dynamic> && e['role'] == 'driver') {
            list.add(e);
          }
        }
      }
      if (mounted) {
        setState(() {
          _drivers = list;
          _loadingDrivers = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() => _loadingDrivers = false);
      }
    }
  }

  @override
  void dispose() {
    _number.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final String? err =
        await context.read<SuperAdminVehiclesCubit>().createVehicle(
              vehicleNumber: _number.text.trim(),
              driverId: _driverId,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.vehicleCreated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottom + 24,
        top: 8,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.addVehicle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _number,
                textAlign: TextAlign.right,
                decoration: InputDecoration(labelText: l10n.vehicleNumberLabel),
                validator: (String? v) =>
                    v == null || v.trim().isEmpty ? ' ' : null,
              ),
              const SizedBox(height: 12),
              if (_loadingDrivers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                DropdownButtonFormField<String?>(
                  value: _driverId,
                  decoration: InputDecoration(labelText: l10n.driverOptionalLabel),
                  items: <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.noDriver),
                    ),
                    ..._drivers.map(
                      (Map<String, dynamic> d) => DropdownMenuItem<String?>(
                        value: d['id']?.toString(),
                        child: Text(
                          d['fullName']?.toString() ??
                              d['email']?.toString() ??
                              '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (String? v) => setState(() => _driverId = v),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                textAlign: TextAlign.right,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.vehicleNotesOptional),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
