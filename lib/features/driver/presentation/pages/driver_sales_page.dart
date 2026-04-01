import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:amethyst/features/catalog/presentation/pages/json_list_page.dart';
import 'package:amethyst/features/driver/presentation/widgets/add_vehicle_sale_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriverSalesPage extends StatelessWidget {
  const DriverSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          JsonListCubit(() => sl<AmethystApi>().listVehicleSales())..load(),
      child: JsonListPageWithFab(
        title: context.l10n.myVehicleSales,
        subtitleBuilder: (ctx, m) => ctx.l10n.qtyAmountSubtitle(
          '${m['quantity'] ?? ''}',
          '${m['totalAmount'] ?? ''}',
        ),
        fab: FloatingActionButton.extended(
          onPressed: () => showAddVehicleSaleSheet(context),
          icon: const Icon(Icons.add),
          label: Text(context.l10n.addSale),
          backgroundColor: AppColors.primaryContainer,
        ),
      ),
    );
  }
}
