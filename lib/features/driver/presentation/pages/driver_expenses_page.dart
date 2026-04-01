import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/widgets/expense_category_hints_section.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:amethyst/features/catalog/presentation/pages/json_list_page.dart';
import 'package:amethyst/features/driver/presentation/widgets/add_expense_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriverExpensesPage extends StatelessWidget {
  const DriverExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) =>
          JsonListCubit(() => sl<AmethystApi>().listExpenses())..load(),
      child: JsonListPageWithFab(
        title: l10n.myExpenses,
        topSection: const ExpenseCategoryHintsSection(),
        titleBuilder: (BuildContext ctx, Map<String, dynamic> m) {
          final note = m['note']?.toString().trim() ?? '';
          if (note.isNotEmpty) return note;
          return '${m['amount'] ?? ''}';
        },
        subtitleBuilder: (BuildContext ctx, Map<String, dynamic> m) {
          final note = m['note']?.toString().trim() ?? '';
          if (note.isEmpty) return '';
          return '${m['amount'] ?? ''}';
        },
        fab: FloatingActionButton.extended(
          onPressed: () => startDriverExpenseEntry(
            context,
            onListReload: () => context.read<JsonListCubit>().load(),
          ),
          icon: const Icon(Icons.add),
          label: Text(l10n.addExpense),
          backgroundColor: AppColors.error,
        ),
      ),
    );
  }
}
