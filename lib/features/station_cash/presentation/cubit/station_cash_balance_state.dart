import 'package:equatable/equatable.dart';

sealed class StationCashBalanceState extends Equatable {
  const StationCashBalanceState();

  @override
  List<Object?> get props => <Object?>[];
}

final class StationCashBalanceInitial extends StationCashBalanceState {
  const StationCashBalanceInitial();
}

final class StationCashBalanceLoading extends StationCashBalanceState {
  const StationCashBalanceLoading();
}

final class StationCashBalanceLoaded extends StationCashBalanceState {
  const StationCashBalanceLoaded({
    required this.amount,
    required this.yesterdayAmount,
    required this.entries,
  });

  final double amount;
  final double yesterdayAmount;
  final List<Map<String, dynamic>> entries;

  @override
  List<Object?> get props => <Object?>[amount, yesterdayAmount, entries];
}

final class StationCashBalanceFailure extends StationCashBalanceState {
  const StationCashBalanceFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

final class StationCashBalanceSubmitting extends StationCashBalanceState {
  const StationCashBalanceSubmitting({
    required this.amount,
    required this.yesterdayAmount,
    required this.entries,
  });

  final double amount;
  final double yesterdayAmount;
  final List<Map<String, dynamic>> entries;

  @override
  List<Object?> get props => <Object?>[amount, yesterdayAmount, entries];
}
