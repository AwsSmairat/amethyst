import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/expenses/expense_aggregates.dart';
import 'package:amethyst/core/expenses/expense_category_match.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/widgets/expense_category_hints_section.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// شاشة المصاريف للأدمن/السوبر أدمن: مجموع المصاريف + التصنيفات.
class ExpensesHubPage extends StatefulWidget {
  const ExpensesHubPage({
    super.key,
    required this.basePath,
  });

  /// مثال: `/admin` أو `/super-admin`.
  final String basePath;

  @override
  State<ExpensesHubPage> createState() => _ExpensesHubPageState();
}

class _ExpensesHubPageState extends State<ExpensesHubPage> {
  bool _loadingTotals = true;
  String? _totalsError;
  double _totalAll = 0;
  double _totalToday = 0;
  double _totalMonth = 0;
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

      if (!mounted || generation != _loadGeneration) {
        return;
      }

      final ExpenseSummaryTotals summary = summarizeExpenseRows(all);
      final Map<String, CategoryExpenseTotals> byCategory =
          summarizeExpensesByCategory(
        rows: all,
        l10n: l10n,
        categoryKeys: expenseCategoryKeysForHub(includeStationExpense: true),
      );

      setState(() {
        _totalAll = summary.allTime;
        _totalToday = summary.today;
        _totalMonth = summary.month;
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
        title: Text(l10n.titleExpenses),
        actions: <Widget>[
          IconButton(
            onPressed: _loadingTotals ? null : _loadTotals,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _ExpensesTotalsBanner(
              loading: _loadingTotals,
              error: _totalsError,
              totalAll: _totalAll,
              totalToday: _totalToday,
              totalMonth: _totalMonth,
              formatAmount: _formatAmount,
              onRetry: _loadTotals,
            ),
          ),
          ExpenseCategoryHintsSection(
            includeStationExpense: true,
            categoryTotals: _categoryTotals,
            formatAmount: _formatAmount,
            onCategoryTap: (String key) async {
              await context.push('${widget.basePath}/expenses/report/$key');
              if (mounted) {
                await _loadTotals();
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ExpensesTotalsBanner extends StatelessWidget {
  const _ExpensesTotalsBanner({
    required this.loading,
    required this.error,
    required this.totalAll,
    required this.totalToday,
    required this.totalMonth,
    required this.formatAmount,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final double totalAll;
  final double totalToday;
  final double totalMonth;
  final String Function(double value) formatAmount;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    if (loading) {
      return const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.expensesGrandTotal,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.amountDinars(formatAmount(totalAll)),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TotalChip(
                    label: l10n.expensesToday,
                    value: l10n.amountDinars(formatAmount(totalToday)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TotalChip(
                    label: l10n.monthlyExpenses,
                    value: l10n.amountDinars(formatAmount(totalMonth)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
