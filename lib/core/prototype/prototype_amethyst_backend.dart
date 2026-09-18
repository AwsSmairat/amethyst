import 'dart:async';
import 'dart:typed_data';

import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/station_debt/station_debt_entry_utils.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/prototype/prototype_sample_data.dart';
import 'package:amethyst/core/utils/parse_api_datetime.dart';
import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';


part 'prototype_amethyst_backend_catalog.dart';
part 'prototype_amethyst_backend_ops.dart';

abstract class _PrototypeAmethystBackendBase {
  String _requirePrototypeDriverId() {
    final String? id = PrototypeSession.current?.id;
    if (id == null || id.isEmpty) {
      throw ApiException('Driver not signed in', code: 'FORBIDDEN');
    }
    if (PrototypeSession.current?.role != 'driver') {
      throw ApiException('Driver access only', code: 'FORBIDDEN');
    }
    return id;
  }

  Map<String, dynamic> _paginate(
    List<Map<String, dynamic>> all, {
    required int page,
    required int limit,
  }) {
    final int safeLimit = limit.clamp(1, 100);
    final int safePage = page < 1 ? 1 : page;
    final int start = (safePage - 1) * safeLimit;
    final int end = start + safeLimit;
    final List<Map<String, dynamic>> slice = start >= all.length
        ? <Map<String, dynamic>>[]
        : all.sublist(start, end > all.length ? all.length : end);
    return <String, dynamic>{
      'items': slice,
      'total': all.length,
      'page': safePage,
      'limit': safeLimit,
    };
  }
}

final class PrototypeAmethystBackend extends _PrototypeAmethystBackendBase
    with _PrototypeBackendCatalogOps, _PrototypeBackendOps {}

