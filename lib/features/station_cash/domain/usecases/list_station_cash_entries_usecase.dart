import 'package:amethyst/features/station_cash/domain/repositories/station_cash_repository.dart';

final class ListStationCashEntriesUseCase {
  const ListStationCashEntriesUseCase(this._repository);

  final StationCashRepository _repository;

  Future<List<Map<String, dynamic>>> call({int limit = 50}) =>
      _repository.listEntries(limit: limit);
}
