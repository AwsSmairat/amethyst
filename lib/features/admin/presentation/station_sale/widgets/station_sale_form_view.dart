import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/features/admin/presentation/station_sale/cubit/station_sale_form_cubit.dart';
import 'package:amethyst/features/admin/presentation/station_sale/cubit/station_sale_form_state.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_product_labels.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_validation_message.dart';
import 'package:amethyst/features/admin/presentation/station_sale/widgets/station_sale_back_bar.dart';
import 'package:amethyst/features/admin/presentation/station_sale/widgets/station_sale_product_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StationSaleFormView extends StatelessWidget {
  const StationSaleFormView({
    super.key,
    required this.onBackPressed,
  });

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottom + 20,
        top: 8,
      ),
      child: BlocConsumer<StationSaleFormCubit, StationSaleFormState>(
        listenWhen: (StationSaleFormState p, StationSaleFormState c) =>
            (!p.submitSucceeded && c.submitSucceeded) ||
            (c.submitError != null && c.submitError != p.submitError),
        listener: (BuildContext context, StationSaleFormState state) {
          final l10n = context.l10n;
          if (state.submitSucceeded) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.stationSalesRecorded)),
            );
          } else if (state.submitError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.submitError!)),
            );
          }
        },
        builder: (BuildContext context, StationSaleFormState state) {
          final l10n = context.l10n;
          final ColorScheme scheme = Theme.of(context).colorScheme;
          final bool busy = state.submitting;

          if (state.loadingProducts) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StationSaleBackBar(onBack: onBackPressed),
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }
          if (state.loadError != null) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StationSaleBackBar(onBack: onBackPressed),
                Text(state.loadError!),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StationSaleBackBar(
                  onBack: onBackPressed,
                  enabled: !busy,
                ),
                Text(
                  l10n.newStationSale,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.entryKind == StationSaleEntryKind.filling
                      ? l10n.stationSaleKindFilling
                      : l10n.stationSaleKindEmptySale,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.vehicleLoadProductsSection,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                ),
                const SizedBox(height: 12),
                if (state.entryKind == StationSaleEntryKind.filling &&
                    state.colCount == 4) ...<Widget>[
                  _productRow(
                    context,
                    state: state,
                    busy: busy,
                    start: 0,
                    end: 2,
                  ),
                  const SizedBox(height: 12),
                  _productRow(
                    context,
                    state: state,
                    busy: busy,
                    start: 2,
                    end: 4,
                  ),
                ] else
                  _productRow(
                    context,
                    state: state,
                    busy: busy,
                    start: 0,
                    end: state.colCount,
                  ),
                if (state.entryKind == StationSaleEntryKind.emptySale) ...<Widget>[
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton(
                      onPressed: busy
                          ? null
                          : () => context
                              .read<StationSaleFormCubit>()
                              .toggleWithFilling(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: state.withFilling
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        foregroundColor: state.withFilling
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                      child: Text(l10n.stationSaleWithFilling),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () {
                          final StationSaleFormCubit cubit =
                              context.read<StationSaleFormCubit>();
                          final err = cubit.validate();
                          if (err != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  stationSaleValidationMessage(err, l10n),
                                ),
                              ),
                            );
                            return;
                          }
                          cubit.submit();
                        },
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.addStationSale),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _productRow(
    BuildContext context, {
    required StationSaleFormState state,
    required bool busy,
    required int start,
    required int end,
  }) {
    final cubit = context.read<StationSaleFormCubit>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var i = start; i < end; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: i == start ? 0 : 6,
                end: i == end - 1 ? 0 : 6,
              ),
              child: StationSaleProductColumn(
                index: i,
                productLabel: stationSaleProductLabel(
                  state.entryKind,
                  i,
                  context.l10n,
                ),
                quantity: state.quantities[i],
                onDecrement: () => cubit.adjustQuantity(i, -1),
                onIncrement: () => cubit.adjustQuantity(i, 1),
                busy: busy,
                showCouponButton: state.showCouponUnderProduct1And2 && i < 2,
                couponActive: i == 0
                    ? state.couponLine1On
                    : state.couponLine2On,
                onCouponToggle: state.showCouponUnderProduct1And2 && i < 2
                    ? () => cubit.toggleCouponLine(i)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
