import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_station_expense_sheet.dart';
import 'package:amethyst/features/station_cash/presentation/widgets/station_cash_balance_dashboard_card.dart';
import 'package:amethyst/features/admin/presentation/widgets/station_balance_dashboard_card.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_registration_nav.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_station_sale_sheet.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_vehicle_load_sheet.dart';
import 'package:amethyst/features/dashboard/presentation/utils/admin_daily_report_print.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _printingReport = false;

  Future<void> _printDailyReport() async {
    setState(() => _printingReport = true);
    try {
      await printAdminDailyReport(context);
    } finally {
      if (mounted) {
        setState(() => _printingReport = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            l10n.dashboard,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.print_outlined,
                        color: AppColors.brandPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.adminDailyReportCardTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.adminDailyReportCardSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _printingReport ? null : _printDailyReport,
                    icon: _printingReport
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.receipt_long_outlined),
                    label: Text(l10n.adminDailyReportPrintButton),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.brandPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.vehicleLoads,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.newVehicleLoad,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => showAddVehicleLoadSheet(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addLoad),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => context.push('/admin/vehicle-loads'),
                      child: Text(l10n.openVehicleLoadsList),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.storefront_outlined,
                        color: AppColors.brandPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.stationInsideSales,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.newStationSale,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => showAddStationSaleSheet(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addStationSale),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => context.push('/admin/station-sales'),
                      child: Text(l10n.openStationSalesList),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.brandPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.dashboardDebtRepaymentTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => openAdminStationDebtRegistration(
                      context,
                      registrationPath: '/admin/station-debt-registration',
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.dashboardDebtRepaymentAction),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => context.push('/admin/station-debt-list'),
                      child: Text(l10n.openStationDebtList),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.payments_outlined,
                        color: AppColors.brandPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.stationExpenses,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.recordStationExpense,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => showAddStationExpenseSheet(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addExpense),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => context.push('/admin/expenses'),
                      child: Text(l10n.openExpensesList),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const StationBalanceDashboardCard(),
          const SizedBox(height: 16),
          const StationCashBalanceDashboardCard(),
        ],
      ),
    );
  }
}
