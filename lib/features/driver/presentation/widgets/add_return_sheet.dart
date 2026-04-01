import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/return_submit_cubit.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showAddReturnSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => BlocProvider(
      create: (_) => ReturnSubmitCubit(sl<CreateReturnUseCase>()),
      child: const _AddReturnBody(),
    ),
  );
}

class _AddReturnBody extends StatefulWidget {
  const _AddReturnBody();

  @override
  State<_AddReturnBody> createState() => _AddReturnBodyState();
}

class _AddReturnBodyState extends State<_AddReturnBody> {
  final _qty = TextEditingController();
  List<Map<String, dynamic>> _loads = <Map<String, dynamic>>[];
  String? _loadId;
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
      final current = await api.driverCurrentLoad();
      final loads = (current['loads'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _loads = loads;
        _loadId = loads.isNotEmpty ? loads.first['id'] as String? : null;
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
      child: BlocConsumer<ReturnSubmitCubit, SubmitState>(
        listener: (context, state) {
          if (state is SubmitSuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.returnLogged)),
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
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_error != null) {
            return Text(_error!);
          }
          if (_loads.isEmpty) {
            return Text(context.l10n.noOpenLoadsToReturn);
          }
          final l10n = context.l10n;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.logReturnSheetTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _loadId,
                decoration: InputDecoration(labelText: l10n.loadField),
                items: _loads
                    .map(
                      (l) => DropdownMenuItem<String>(
                        value: l['id'] as String,
                        child: Text(
                          l10n.loadDropdownItem(
                            '${l['product']?['name'] ?? l10n.product}',
                            '${l['remaining'] ?? ''}',
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: busy
                    ? null
                    : (v) => setState(() => _loadId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.quantityReturned),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy
                    ? null
                    : () {
                        final q = int.tryParse(_qty.text.trim());
                        if (q == null || q < 1 || _loadId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.selectLoadAndQuantity),
                            ),
                          );
                          return;
                        }
                        context.read<ReturnSubmitCubit>().submit(
                              vehicleLoadId: _loadId!,
                              quantityReturned: q,
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
