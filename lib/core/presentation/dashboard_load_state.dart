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
  const DashboardLoadLoading({this.previousData});

  /// آخر بيانات ناجحة — تُعرض أثناء التحديث دون إخفاء اللوحة.
  final Map<String, dynamic>? previousData;

  @override
  List<Object?> get props => <Object?>[previousData];
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
