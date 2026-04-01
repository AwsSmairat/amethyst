import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/expense_submit_cubit.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showAddExpenseSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => BlocProvider(
      create: (_) => ExpenseSubmitCubit(sl<CreateExpenseUseCase>()),
      child: const _AddExpenseBody(),
    ),
  );
}

class _AddExpenseBody extends StatefulWidget {
  const _AddExpenseBody();

  @override
  State<_AddExpenseBody> createState() => _AddExpenseBodyState();
}

class _AddExpenseBodyState extends State<_AddExpenseBody> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _vehicleId;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final dash = await sl<AmethystApi>().getDashboardDriver();
      final v = dash['assignedVehicle'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() => _vehicleId = v?['id'] as String?);
    } on Object {
      if (!mounted) return;
      setState(() => _vehicleId = null);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: bottom + 20, top: 8),
      child: BlocConsumer<ExpenseSubmitCubit, SubmitState>(
        listener: (context, state) {
          if (state is SubmitSuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense saved')),
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
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'New expense',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy
                    ? null
                    : () {
                        final a = double.tryParse(_amount.text.trim());
                        if (a == null || a <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter a valid amount')),
                          );
                          return;
                        }
                        final note = _note.text.trim();
                        context.read<ExpenseSubmitCubit>().submit(
                              vehicleId: _vehicleId,
                              amount: a,
                              note: note.isEmpty ? null : note,
                            );
                      },
                child: busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}
