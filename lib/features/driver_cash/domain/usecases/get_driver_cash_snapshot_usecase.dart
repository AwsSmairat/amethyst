import 'package:amethyst/features/driver_cash/domain/entities/driver_cash_balance_snapshot.dart';
import 'package:amethyst/features/driver_cash/domain/repositories/driver_cash_repository.dart';

final class GetDriverCashSnapshotUseCase {
  const GetDriverCashSnapshotUseCase(this._repository);

  final DriverCashRepository _repository;

  Future<DriverCashBalanceSnapshot> call() => _repository.getBalanceSnapshot();
}
