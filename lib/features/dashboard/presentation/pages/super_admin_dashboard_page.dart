import 'dart:async';

import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/format_money.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_station_expense_sheet.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_dashboard_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amethyst/features/staff_note/presentation/widgets/send_staff_note_sheet.dart';
import 'package:go_router/go_router.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  late final SuperAdminDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<SuperAdminDashboardCubit>();
    final DashboardLoadState current = _cubit.state;
    if (current is DashboardLoadInitial) {
      _cubit.load();
    } else {
      _cubit.load(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SuperAdminDashboardCubit>.value(
      value: _cubit,
      child: const _SuperAdminDashboardBody(),
    );
  }
}

class _SuperAdminDashboardBody extends StatefulWidget {
  const _SuperAdminDashboardBody();

  @override
  State<_SuperAdminDashboardBody> createState() =>
      _SuperAdminDashboardBodyState();
}

class _SuperAdminDashboardBodyState extends State<_SuperAdminDashboardBody>
    with WidgetsBindingObserver {
  Timer? _nextMidnightTimer;
  Timer? _nextMonthTimer;
  bool _ignoreNextWebResume = kIsWeb;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleNextMidnightRefresh();
      _scheduleNextMonthRefresh();
    });
  }

  @override
  void dispose() {
    _nextMidnightTimer?.cancel();
    _nextMonthTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleNextMidnightRefresh() {
    _nextMidnightTimer?.cancel();
    final DateTime now = DateTime.now();
    final DateTime nextMidnight =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _nextMidnightTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      context.read<SuperAdminDashboardCubit>().load(showLoading: false);
      _scheduleNextMidnightRefresh();
    });
  }

  /// Refetch when the device calendar month changes (monthly KPIs reset on server).
  void _scheduleNextMonthRefresh() {
    _nextMonthTimer?.cancel();
    final DateTime now = DateTime.now();
    final DateTime nextMonthStart = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    _nextMonthTimer = Timer(nextMonthStart.difference(now), () {
      if (!mounted) return;
      context.read<SuperAdminDashboardCubit>().load(showLoading: false);
      _scheduleNextMonthRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    if (kIsWeb) {
      if (_ignoreNextWebResume) {
        _ignoreNextWebResume = false;
        return;
      }
      return;
    }
    context.read<SuperAdminDashboardCubit>().load(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuperAdminDashboardCubit, DashboardLoadState>(
      builder: (context, state) {
        if (state is DashboardLoadInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardLoadLoading && state.previousData == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardLoadFailure) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      context.read<SuperAdminDashboardCubit>().load(),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          );
        }
        final Map<String, dynamic> d = state is DashboardLoadSuccess
            ? state.data
            : (state as DashboardLoadLoading).previousData!;
        final salesToday = _dashboardKpiNum(d['totalSalesToday']);
        final profit = _dashboardKpiNum(d['totalProfitToday']);
        final profitMonth = _dashboardKpiNum(d['totalProfitMonth']);
        final expenses = _dashboardKpiNum(d['totalExpensesToday']);
        final monthlyExpenses = _dashboardKpiNum(d['totalMonthlyExpenses']);
        final monthly = _dashboardKpiNum(d['totalMonthlySales']);
        final monthlyCartons = _dashboardKpiNum(d['totalMonthlyCartonSales']);
        final cashToday = _dashboardKpiNum(d['stationCashTodayAmount']);
        final cashYesterday = _dashboardKpiNum(d['stationCashYesterdayAmount']);
        final List<_DebtGroup> debtPreview =
            _parseStationDebtOpenPreview(d['stationDebtOpenPreview']);
        final l10n = context.l10n;
        return RefreshIndicator(
          onRefresh: () =>
              context.read<SuperAdminDashboardCubit>().load(showLoading: false),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                l10n.overview,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              _KpiGrid(
                children: <Widget>[
                  _KpiCard(
                    label: l10n.kpiProductPrices,
                    value:
                        '${d['productsWithPrice'] ?? d['totalProducts'] ?? 0}',
                    icon: Icons.price_change_outlined,
                    onTap: () => context.push('/super-admin/product-prices'),
                  ),
                  _KpiCard(
                    label: l10n.salesToday,
                    value: salesToday.toStringAsFixed(0),
                    icon: Icons.trending_up,
                    onTap: () =>
                        context.push('/super-admin/sales-working-days'),
                  ),
                  _KpiCard(
                    label: l10n.profitToday,
                    value: profit.toStringAsFixed(0),
                    icon: Icons.savings,
                    onTap: () => context.push('/super-admin/kpi/profit-today'),
                  ),
                  _KpiCard(
                    label: l10n.profitMonth,
                    value: profitMonth.toStringAsFixed(0),
                    icon: Icons.savings_outlined,
                    onTap: () => context.push('/super-admin/kpi/profit-month'),
                  ),
                  _KpiCard(
                    label: l10n.expensesToday,
                    value: expenses.toStringAsFixed(0),
                    icon: Icons.payments,
                    onTap: () =>
                        context.push('/super-admin/kpi/expenses-today'),
                  ),
                  _KpiCard(
                    label: l10n.monthlyExpenses,
                    value: monthlyExpenses.toStringAsFixed(0),
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () =>
                        context.push('/super-admin/kpi/expenses-month'),
                  ),
                  _KpiCard(
                    label: l10n.monthlySales,
                    value: monthly.toStringAsFixed(0),
                    icon: Icons.calendar_month,
                    onTap: () => context.push('/super-admin/kpi/sales-month'),
                  ),
                  _KpiCard(
                    label: l10n.cartonSalesMonthly,
                    value: monthlyCartons.toStringAsFixed(0),
                    icon: Icons.inventory_2_outlined,
                    onTap: () =>
                        context.push('/super-admin/carton-sales'),
                  ),
                  _KpiCard(
                    label: l10n.stationCashBalanceYesterdayLabel,
                    value: formatMoneyAmount(cashYesterday),
                    icon: Icons.history_outlined,
                    onTap: () =>
                        context.push('/super-admin/station-cash-balance'),
                  ),
                  _KpiCard(
                    label: l10n.stationCashBalanceTodayLabel,
                    value: formatMoneyAmount(cashToday),
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () =>
                        context.push('/super-admin/station-cash-balance'),
                  ),
                  _KpiCard(
                    label: l10n.staffNoteKpi,
                    value: '✉',
                    icon: Icons.note_alt_outlined,
                    onTap: () => showSendStaffNoteSheet(context),
                  ),
                  _KpiCard(
                    label: l10n.addExpense,
                    value: '+',
                    icon: Icons.payments_outlined,
                    onTap: () => showAddStationExpenseSheet(
                      context,
                      onRecorded: () {
                        context
                            .read<SuperAdminDashboardCubit>()
                            .load(showLoading: false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StationDebtListPreviewCard(
                title: l10n.titleStationDebtList,
                caption: l10n.superAdminDebtListKpiCaption,
                groups: debtPreview,
                onTap: () => context.push('/super-admin/station-debt-list'),
              ),
            ],
          ),
        );
      },
    );
  }
}

double _dashboardKpiNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

final class _DebtLine {
  const _DebtLine({
    required this.productName,
    required this.quantity,
    this.kind,
  });

  final String productName;
  final int quantity;
  final String? kind;
}

final class _DebtGroup {
  const _DebtGroup({required this.debtorName, required this.lines});

  final String debtorName;
  final List<_DebtLine> lines;
}

List<_DebtGroup> _parseStationDebtOpenPreview(dynamic v) {
  if (v is! List) {
    return const <_DebtGroup>[];
  }
  final List<_DebtGroup> out = <_DebtGroup>[];
  for (final Object? item in v) {
    if (item is! Map) {
      continue;
    }
    final Map<String, dynamic> m = Map<String, dynamic>.from(item);
    final String name = m['debtorName']?.toString().trim() ?? '';
    final Object? rawLines = m['lines'];
    final List<_DebtLine> lines = <_DebtLine>[];
    if (rawLines is List) {
      for (final Object? ln in rawLines) {
        if (ln is! Map) {
          continue;
        }
        final Map<String, dynamic> lm = Map<String, dynamic>.from(ln);
        final String pn = lm['productName']?.toString() ?? '';
        final Object? q = lm['quantity'];
        final int iq = q is int
            ? q
            : int.tryParse(q?.toString() ?? '') ?? 0;
        if (pn.isNotEmpty && iq > 0) {
          lines.add(
            _DebtLine(
              productName: catalogProductArabicDisplayLabel(pn),
              quantity: iq,
              kind: lm['kind']?.toString(),
            ),
          );
        }
      }
    }
    if (name.isNotEmpty) {
      out.add(_DebtGroup(debtorName: name, lines: lines));
    }
  }
  return out;
}

class _StationDebtListPreviewCard extends StatelessWidget {
  const _StationDebtListPreviewCard({
    required this.title,
    required this.caption,
    required this.groups,
    required this.onTap,
  });

  final String title;
  final String caption;
  final List<_DebtGroup> groups;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget body = groups.isEmpty
        ? const SizedBox.shrink()
        : ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groups
                    .map(
                      (_DebtGroup g) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              g.debtorName,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (g.lines.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                g.lines
                                    .map(
                                      (_DebtLine l) {
                                        final String kindPrefix =
                                            l.kind == 'vehicle'
                                                ? '${context.l10n.stationDebtKindVehicle} · '
                                                : l.kind == 'station'
                                                    ? '${context.l10n.stationDebtKindStation} · '
                                                    : '';
                                        return '$kindPrefix${l.productName} ×${l.quantity}';
                                      },
                                    )
                                    .join(' · '),
                                style: textTheme.bodyMedium?.copyWith(
                                  height: 1.35,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          );

    final Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.list_alt, color: AppColors.brandPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                    height: 1.25,
                  ),
                ),
                if (groups.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  body,
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final int cross = w >= 900 ? 4 : 2;
        const double gap = 12;
        final double tileW = (w - gap * (cross - 1)) / cross;
        final int orphan = children.length % cross;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (int i = 0; i < children.length; i++)
              SizedBox(
                width: orphan != 0 && i >= children.length - orphan ? w : tileW,
                child: children[i] is _KpiCard
                    ? (children[i] as _KpiCard).copyWith(
                        wide: orphan != 0 && i >= children.length - orphan,
                      )
                    : children[i],
              ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool wide;

  _KpiCard copyWith({bool? wide}) {
    return _KpiCard(
      label: label,
      value: value,
      icon: icon,
      onTap: onTap,
      wide: wide ?? this.wide,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget iconBadge = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: AppColors.brandPrimary,
        size: 22,
      ),
    );

    final Widget content = wide
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                iconBadge,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryText,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_left,
                    size: 22,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    iconBadge,
                    const Spacer(),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.55,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryText,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          );

    final Widget card = Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );

    if (wide) {
      return SizedBox(height: 76, child: card);
    }
    return AspectRatio(aspectRatio: 1, child: card);
  }
}
