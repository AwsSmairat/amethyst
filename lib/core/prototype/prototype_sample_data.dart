import 'dart:async';

import 'package:amethyst/core/prototype/prototype_credentials.dart';
import 'package:amethyst/core/prototype/prototype_local_store.dart';
import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/core/firebase/station_stock_skip.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/firebase/date_range_utils.dart';
import 'package:amethyst/core/expenses/profit_vehicle_expense_deduction.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_aggregates.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_catalog.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sales_aggregates.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';

part 'prototype_sample_core.dart';
part 'prototype_sample_catalog.dart';
part 'prototype_sample_sales.dart';
part 'prototype_sample_loads.dart';
part 'prototype_sample_expenses.dart';
part 'prototype_sample_dash.dart';
part 'prototype_sample_reports.dart';
part 'prototype_sample_notes.dart';

abstract class _PrototypeSampleDataBase {}

/// Sample maps for UI prototype with optional local persistence.
final class PrototypeSampleData extends _PrototypeSampleDataBase
    with
        _PrototypeSampleCore,
        _PrototypeSampleCatalog,
        _PrototypeSampleSales,
        _PrototypeSampleLoads,
        _PrototypeSampleExpenses,
        _PrototypeSampleDash,
        _PrototypeSampleReports,
        _PrototypeSampleNotes {
  PrototypeSampleData._();

  static final PrototypeSampleData instance = PrototypeSampleData._();
}
