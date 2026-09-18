import 'package:amethyst/core/station_balance/station_balance_list_refresh.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/data/api_list_fetch.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_product_columns.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sale_payment_method.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_catalog.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/core/printer/printer_exception.dart';
import 'package:amethyst/core/printer/printer_service.dart';
import 'package:amethyst/core/printer/receipt_builder.dart';
import 'package:amethyst/core/printer/receipt_models.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:amethyst/features/driver/presentation/widgets/driver_receipt_factory.dart';
import 'package:amethyst/features/driver/presentation/widgets/print_receipt_prompt_sheet.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/vehicle_sale_submit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_vehicle_sale_sheet_body.dart';
part 'add_vehicle_sale_sheet_widgets.dart';

enum VehicleSalePlace {
  home,
  store,
}

Future<SaleReceiptData?> showAddVehicleSaleSheet(BuildContext context) async {
  final SaleReceiptData? receipt = await showModalBottomSheet<SaleReceiptData?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => BlocProvider(
      create: (_) => VehicleSaleSubmitCubit(
        sl<CreateVehicleSaleUseCase>(),
        sl<CreateVehicleSalesBatchUseCase>(),
      ),
      child: const _AddVehicleSaleBody(),
    ),
  );
  if (receipt != null && context.mounted) {
    await _completeSaleAndPrintInvoice(context, receipt);
  }
  return receipt;
}

Future<void> _completeSaleAndPrintInvoice(
  BuildContext context,
  SaleReceiptData receipt,
) async {
  final l10n = context.l10n;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.vehicleSalesRecorded)),
  );
  try {
    final List<int> bytes = await ReceiptBuilder.buildSaleReceipt(receipt);
    await sl<PrinterService>().printBytes(bytes);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.printerPrintSuccess)),
    );
  } on PrinterException catch (e) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
    await showPrintReceiptPromptSheet(
      context,
      buildReceiptBytes: () => ReceiptBuilder.buildSaleReceipt(receipt),
    );
  }
}
