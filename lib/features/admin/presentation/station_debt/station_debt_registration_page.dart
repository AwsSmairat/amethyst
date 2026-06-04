import 'dart:math' as math;

import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_api_error.dart';
import 'package:amethyst/features/admin/presentation/station_debt/cubit/station_debt_registration_cubit.dart';
import 'package:amethyst/features/admin/presentation/station_debt/cubit/station_debt_registration_state.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_registration_nav.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_product_columns.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_vehicle_place.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_product_labels.dart';
import 'package:amethyst/features/admin/presentation/station_sale/widgets/station_sale_product_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class StationDebtRegistrationPage extends StatefulWidget {
  const StationDebtRegistrationPage({super.key});

  @override
  State<StationDebtRegistrationPage> createState() =>
      _StationDebtRegistrationPageState();
}

class _StationDebtRegistrationPageState
    extends State<StationDebtRegistrationPage> {
  final TextEditingController _debtorNameController = TextEditingController();

  @override
  void dispose() {
    _debtorNameController.dispose();
    super.dispose();
  }

  String _submitMessage(String? err, AppLocalizations l10n) {
    if (err == null || err.isEmpty) {
      return '';
    }
    switch (err) {
      case kStationDebtNeedName:
        return l10n.stationDebtValidationNeedName;
      case kStationDebtNeedLine:
        return l10n.stationDebtValidationNeedLine;
      case kStationDebtMissingProduct:
        return l10n.stationDebtValidationMissingProduct;
      case kStationDebtInsufficientStockSubmitMarker:
        return l10n.stationSaleSubmitInsufficientStock;
      case kStationDebtApiRouteMissingMarker:
        return l10n.stationDebtErrorApiRouteMissing;
      case kStationDebtForbiddenMarker:
        return l10n.stationDebtErrorForbidden;
      default:
        return err;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final StationDebtVehiclePlace? routeVehiclePlace =
        context.read<StationDebtRegistrationCubit>().vehiclePlace;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          routeVehiclePlace != null
              ? l10n.stationDebtVehicleRegistrationTitle
              : l10n.stationDebtRegistrationTitle,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<StationDebtRegistrationCubit,
            StationDebtRegistrationState>(
          listenWhen: (StationDebtRegistrationState p,
                  StationDebtRegistrationState c) =>
              (!p.submitSucceeded && c.submitSucceeded) ||
              (c.submitError != null && c.submitError != p.submitError),
          listener: (BuildContext context, StationDebtRegistrationState state) {
            if (state.submitSucceeded) {
              _debtorNameController.clear();
              context.read<StationDebtRegistrationCubit>().clearSubmitSucceeded();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.stationDebtRecorded)),
              );
              final String path = GoRouterState.of(context).uri.path;
              final String home = path.startsWith('/super-admin')
                  ? '/super-admin/dashboard'
                  : path.startsWith('/driver')
                      ? '/driver/dashboard'
                      : '/admin/dashboard';
              Future<void>.delayed(const Duration(milliseconds: 500), () {
                if (!context.mounted) {
                  return;
                }
                context.go(home);
              });
            } else if (state.submitError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_submitMessage(state.submitError, l10n)),
                ),
              );
            }
          },
          builder: (BuildContext context, StationDebtRegistrationState state) {
            final bool busy = state.submitting;
            if (state.loadingProducts) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.loadError != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(state.loadError!),
              );
            }
            final StationDebtVehiclePlace? vehiclePlace =
                context.read<StationDebtRegistrationCubit>().vehiclePlace;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.stationDebtDebtorNameLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _debtorNameController,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: l10n.stationDebtDebtorNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (vehiclePlace != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      vehiclePlace == StationDebtVehiclePlace.store
                          ? l10n.vehicleSaleFromStore
                          : l10n.vehicleSaleFromHome,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    l10n.stationDebtProductsSection,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (state.useVehicleProductLabels)
                    for (var start = 0;
                        start < state.columnCount;
                        start += 3) ...<Widget>[
                      if (start > 0) const SizedBox(height: 12),
                      _productRow(
                        context,
                        state: state,
                        busy: busy,
                        start: start,
                        end: math.min(start + 3, state.columnCount),
                      ),
                    ]
                  else ...<Widget>[
                    for (final ({int start, int end}) band
                        in stationDebtAdminLayoutBands(
                          entryKind: context
                              .read<StationDebtRegistrationCubit>()
                              .stationEntryKind,
                          columnCount: state.columnCount,
                        ))
                      if (band.start < state.columnCount) ...<Widget>[
                        if (band.start > 0) const SizedBox(height: 12),
                        _productRow(
                          context,
                          state: state,
                          busy: busy,
                          start: band.start,
                          end: math.min(band.end, state.columnCount),
                        ),
                      ],
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () {
                            context.read<StationDebtRegistrationCubit>().submit(
                                  _debtorNameController.text,
                                );
                          },
                    child: busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.stationDebtSubmit),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _productRow(
    BuildContext context, {
    required StationDebtRegistrationState state,
    required bool busy,
    required int start,
    required int end,
  }) {
    final cubit = context.read<StationDebtRegistrationCubit>();
    final StationDebtVehiclePlace? vehiclePlace = cubit.vehiclePlace;
    final l10n = context.l10n;
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
                badgeLabel: state.useVehicleProductLabels &&
                        vehiclePlace != null
                    ? (vehicleProductBadgeLabel(
                          vehiclePlace == StationDebtVehiclePlace.home
                              ? VehicleProductColumnPlace.home
                              : VehicleProductColumnPlace.store,
                          i,
                        ) ??
                        l10n.productRow(i + 1))
                    : null,
                productLabel: state.useVehicleProductLabels &&
                        i < state.columnProductNames.length &&
                        state.columnProductNames[i].isNotEmpty
                    ? state.columnProductNames[i]
                    : stationSaleProductLabel(
                        cubit.stationEntryKind,
                        i,
                        l10n,
                      ),
                quantity: state.quantities[i],
                onDecrement: () => cubit.adjustQuantity(i, -1),
                onIncrement: () => cubit.adjustQuantity(i, 1),
                busy: busy,
                showCouponButton: false,
                stationStockAvailable: () {
                  if (!state.useVehicleProductLabels || vehiclePlace == null) {
                    if (i < state.columnSkipsStationStock.length &&
                        !state.columnSkipsStationStock[i]) {
                      return i < state.columnStationStock.length
                          ? state.columnStationStock[i]
                          : null;
                    }
                    return null;
                  }
                  final VehicleProductColumnPlace columnPlace =
                      vehiclePlace == StationDebtVehiclePlace.store
                          ? VehicleProductColumnPlace.store
                          : VehicleProductColumnPlace.home;
                  final int vehicle = i < state.columnVehicleRemaining.length
                      ? state.columnVehicleRemaining[i]
                      : 0;
                  final int station = i < state.columnStationStock.length
                      ? state.columnStationStock[i]
                      : 0;
                  final bool skipStation = i < state.columnSkipsStationStock.length &&
                      state.columnSkipsStationStock[i];
                  return vehicleDebtDisplayedStock(
                    place: columnPlace,
                    columnIndex: i,
                    vehicleRemaining: vehicle,
                    stationStock: station,
                    skipsStationStock: skipStation,
                  );
                }(),
                stockSourceLabel: state.useVehicleProductLabels &&
                        vehiclePlace != null
                    ? vehicleDebtLoadStockSourceLabel(
                        vehiclePlace == StationDebtVehiclePlace.store
                            ? VehicleProductColumnPlace.store
                            : VehicleProductColumnPlace.home,
                        i,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
