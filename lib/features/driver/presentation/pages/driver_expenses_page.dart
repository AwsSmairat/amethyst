import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/expenses/expense_aggregates.dart';
import 'package:amethyst/core/expenses/expense_category_match.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/widgets/expense_category_hints_section.dart';
import 'package:amethyst/core/widgets/fab_hero_tags.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:amethyst/features/driver/presentation/widgets/add_expense_sheet.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DriverExpensesPage extends StatefulWidget {
  const DriverExpensesPage({super.key});

  @override
  State<DriverExpensesPage> createState() => _DriverExpensesPageState();
}

class _DriverExpensesPageState extends State<DriverExpensesPage> {
  bool _loadingTotals = true;
  String? _totalsError;
  Map<String, CategoryExpenseTotals> _categoryTotals =
      <String, CategoryExpenseTotals>{};
  bool _didScheduleInitialLoad = false;
  int _loadGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didScheduleInitialLoad) {
      return;
    }
    _didScheduleInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTotals();
      }
    });
  }

  String? _currentDriverId() {
    final AuthState auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      return auth.user.id;
    }
    return null;
  }

  Future<void> _loadTotals() async {
    final int generation = ++_loadGeneration;
    if (!mounted) {
      return;
    }
    setState(() {
      _loadingTotals = true;
      _totalsError = null;
    });

    try {
      final AppLocalizations l10n = context.l10n;
      final AmethystApi api = sl<AmethystApi>();
      final List<Map<String, dynamic>> all = await fetchAllExpenseRows(api);
      final List<Map<String, dynamic>> mine = expenseRowsForDriver(
        all,
        driverId: _currentDriverId(),
      );

      if (!mounted || generation != _loadGeneration) {
        return;
      }

      final Map<String, CategoryExpenseTotals> byCategory =
          summarizeExpensesByCategory(
        rows: mine,
        l10n: l10n,
        categoryKeys: kDriverExpenseUiCategoryKeys,
      );

      setState(() {
        _categoryTotals = byCategory;
        _loadingTotals = false;
        _totalsError = null;
      });
    } on Object catch (e) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _totalsError = errorMessageFrom(e);
        _loadingTotals = false;
      });
    }
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myExpenses),
        actions: <Widget>[
          IconButton(
            onPressed: _loadingTotals ? null : _loadTotals,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: FabHeroTags.driverExpenses,
        onPressed: () => startDriverExpenseEntry(
          context,
          onListReload: _loadTotals,
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
        backgroundColor: AppColors.error,
      ),
      body: ListView(
        children: <Widget>[
          if (_loadingTotals)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_totalsError != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  Text(_totalsError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadTotals,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            )
          else
            ExpenseCategoryHintsSection(
              includeOtherExpense: false,
              categoryTotals: _categoryTotals,
              formatAmount: _formatAmount,
              onCategoryTap: (String key) async {
                await context.push('/driver/expenses/report/$key');
                if (mounted) {
                  await _loadTotals();
                }
              },
            ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}
