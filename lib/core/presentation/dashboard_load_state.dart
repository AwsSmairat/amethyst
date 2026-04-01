import 'package:equatable/equatable.dart';

sealed class DashboardLoadState extends Equatable {
  const DashboardLoadState();

  @override
  List<Object?> get props => <Object?>[];
}

final class DashboardLoadInitial extends DashboardLoadState {
  const DashboardLoadInitial();
}

final class DashboardLoadLoading extends DashboardLoadState {
  const DashboardLoadLoading();
}

final class DashboardLoadSuccess extends DashboardLoadState {
  const DashboardLoadSuccess(this.data);

  final Map<String, dynamic> data;

  @override
  List<Object?> get props => <Object?>[data];
}

final class DashboardLoadFailure extends DashboardLoadState {
  const DashboardLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
