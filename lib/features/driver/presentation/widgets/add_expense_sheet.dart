import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:amethyst/features/driver/presentation/models/driver_expense_category.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/expense_submit_cubit.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// يعرض خيارات التصنيف ثم نموذج المبلغ؛ بعد الحفظ يستدعي [onListReload] لتحديث القائمة.
Future<void> startDriverExpenseEntry(
  BuildContext context, {
  required VoidCallback onListReload,
}) async {
  final DriverExpenseCategory? cat =
      await showDriverExpenseCategoryPicker(context);
  if (!context.mounted || cat == null) return;
  await showAddExpenseSheet(
    context,
    category: cat,
    onRecorded: onListReload,
  );
}

Future<DriverExpenseCategory?> showDriverExpenseCategoryPicker(
  BuildContext context,
) {
  final l10n = context.l10n;
  return showModalBottomSheet<DriverExpenseCategory>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              l10n.chooseExpenseCategory,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_gas_station_outlined),
            title: Text(l10n.gasolineExpenses),
            onTap: () =>
                Navigator.of(ctx).pop(DriverExpenseCategory.gasoline),
          ),
          ListTile(
            leading: const Icon(Icons.handyman_outlined),
            title: Text(l10n.carRepairExpenses),
            onTap: () =>
                Navigator.of(ctx).pop(DriverExpenseCategory.carRepair),
          ),
          ListTile(
            leading: const Icon(Icons.more_horiz),
            title: Text(l10n.otherExpenses),
            onTap: () => Navigator.of(ctx).pop(DriverExpenseCategory.other),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> showAddExpenseSheet(
  BuildContext context, {
  required DriverExpenseCategory category,
  VoidCallback? onRecorded,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => BlocProvider(
      create: (_) => ExpenseSubmitCubit(sl<CreateExpenseUseCase>()),
      child: _AddExpenseBody(
        category: category,
        onRecorded: onRecorded,
      ),
    ),
  );
}

class _AddExpenseBody extends StatefulWidget {
  const _AddExpenseBody({
    required this.category,
    this.onRecorded,
  });

  final DriverExpenseCategory category;
  final VoidCallback? onRecorded;

  @override
  State<_AddExpenseBody> createState() => _AddExpenseBodyState();
}

class _AddExpenseBodyState extends State<_AddExpenseBody> {
  final _amount = TextEditingController();
  String? _vehicleId;
  Uint8List? _receiptBytes;
  String? _receiptFilename;

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
    super.dispose();
  }

  String _categoryLabel(AppLocalizations l10n) {
    switch (widget.category) {
      case DriverExpenseCategory.gasoline:
        return l10n.gasolineExpenses;
      case DriverExpenseCategory.carRepair:
        return l10n.carRepairExpenses;
      case DriverExpenseCategory.other:
        return l10n.otherExpenses;
    }
  }

  String _composedNote(AppLocalizations l10n) {
    final base = _categoryLabel(l10n);
    switch (widget.category) {
      case DriverExpenseCategory.gasoline:
      case DriverExpenseCategory.carRepair:
        return base;
      case DriverExpenseCategory.other:
        return base;
    }
  }

  Future<void> _pickReceipt() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (!mounted || picked == null) return;

      final bytes = await picked.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1280,
        minHeight: 1280,
        quality: 60,
        format: CompressFormat.jpeg,
      );

      if (!mounted) return;
      setState(() {
        _receiptBytes = Uint8List.fromList(compressed);
        _receiptFilename =
            'expense_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: bottom + 20, top: 8),
      child: BlocConsumer<ExpenseSubmitCubit, SubmitState>(
        listener: (context, state) {
          if (state is SubmitSuccess) {
            widget.onRecorded?.call();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.expenseSaved)),
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
                l10n.newExpense,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _categoryLabel(l10n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.amount),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : _pickReceipt,
                icon: const Icon(Icons.photo_camera_back_outlined),
                label: Text(l10n.attachReceiptOptional),
              ),
              if (_receiptBytes != null) ...<Widget>[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _receiptBytes!,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                            _receiptBytes = null;
                            _receiptFilename = null;
                          }),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.removeReceipt),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy
                    ? null
                    : () {
                        final a = double.tryParse(_amount.text.trim());
                        if (a == null || a <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.enterValidAmount),
                            ),
                          );
                          return;
                        }
                        context.read<ExpenseSubmitCubit>().submit(
                              vehicleId: _vehicleId,
                              amount: a,
                              note: _composedNote(l10n),
                              receiptBytes: _receiptBytes,
                              receiptFilename: _receiptFilename,
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
