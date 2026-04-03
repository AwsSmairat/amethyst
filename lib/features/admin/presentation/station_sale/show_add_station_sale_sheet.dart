import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_sale/cubit/station_sale_form_cubit.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';
import 'package:amethyst/features/admin/presentation/station_sale/widgets/station_sale_form_view.dart';
import 'package:amethyst/features/admin/presentation/station_sale/widgets/station_sale_kind_picker.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showAddStationSaleSheet(BuildContext context) async {
  while (context.mounted) {
    final StationSaleEntryKind? kind =
        await showModalBottomSheet<StationSaleEntryKind>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => const StationSaleKindPicker(),
    );
    if (!context.mounted || kind == null) {
      return;
    }
    final bool? backToKind = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => BlocProvider<StationSaleFormCubit>(
        create: (_) => StationSaleFormCubit(
          entryKind: kind,
          listProductItems: sl<ListProductItemsUseCase>(),
          createStationSale: sl<CreateStationSaleUseCase>(),
        ),
        child: StationSaleFormView(
          onBackPressed: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (!context.mounted || backToKind != true) {
      return;
    }
  }
}
