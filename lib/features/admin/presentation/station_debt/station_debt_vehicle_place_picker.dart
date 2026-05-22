import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// اختيار منزل / متجر قبل تسجيل دين من المركبة (نفس منطق بيع المركبة).
Future<void> showVehicleDebtPlacePicker(
  BuildContext context, {
  required String registrationPath,
}) async {
  final l10n = context.l10n;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
              child: Text(
                l10n.driverVehicleDebtSheetTitle,
                style: Theme.of(sheetCtx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(l10n.vehicleSalePlaceHome),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push(
                  registrationPath,
                  extra: <String, dynamic>{'vehiclePlace': 'home'},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(l10n.vehicleSalePlaceStore),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push(
                  registrationPath,
                  extra: <String, dynamic>{'vehiclePlace': 'store'},
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// مسؤول / سوبر أدمن: دين محطة (تعبئة) أو دين مركبة منزل / متجر.
Future<void> showAdminDebtRegistrationPicker(
  BuildContext context, {
  required String stationDebtPath,
  required String vehicleDebtPath,
}) async {
  final l10n = context.l10n;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
              child: Text(
                l10n.stationDebtRegistrationTitle,
                style: Theme.of(sheetCtx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: Text(l10n.stationDebtKindStation),
              subtitle: Text(l10n.stationSaleKindFilling),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push(stationDebtPath);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(l10n.vehicleSalePlaceHome),
              subtitle: Text(l10n.stationDebtVehicleRegistrationTitle),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push(
                  vehicleDebtPath,
                  extra: <String, dynamic>{'vehiclePlace': 'home'},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(l10n.vehicleSalePlaceStore),
              subtitle: Text(l10n.stationDebtVehicleRegistrationTitle),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push(
                  vehicleDebtPath,
                  extra: <String, dynamic>{'vehiclePlace': 'store'},
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
