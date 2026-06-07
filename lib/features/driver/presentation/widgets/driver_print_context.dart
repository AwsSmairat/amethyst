import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class DriverPrintContext {
  const DriverPrintContext({
    required this.driverName,
    required this.vehicleName,
  });

  final String driverName;
  final String vehicleName;
}

Future<DriverPrintContext?> loadDriverPrintContext(BuildContext context) async {
  final AuthState auth = context.read<AuthCubit>().state;
  final String fallbackDriver = context.l10n.driver;
  final String driverName =
      auth is AuthAuthenticated ? auth.user.fullName : fallbackDriver;
  try {
    final Map<String, dynamic> dash =
        await sl<AmethystApi>().getDashboardDriver();
    final Map<String, dynamic>? vehicle =
        dash['assignedVehicle'] as Map<String, dynamic>?;
    final String vehicleName =
        vehicle?['vehicleNumber']?.toString().trim() ?? '';
    if (vehicleName.isEmpty) {
      return null;
    }
    return DriverPrintContext(
      driverName: driverName,
      vehicleName: vehicleName,
    );
  } on Object {
    return null;
  }
}
