import 'package:equatable/equatable.dart';

sealed class ListLoadState extends Equatable {
  const ListLoadState();

  @override
  List<Object?> get props => <Object?>[];
}

final class ListLoadInitial extends ListLoadState {
  const ListLoadInitial();
}

final class ListLoadLoading extends ListLoadState {
  const ListLoadLoading();
}

final class ListLoadLoaded extends ListLoadState {
  const ListLoadLoaded(this.items);

  final List<Map<String, dynamic>> items;

  @override
  List<Object?> get props => <Object?>[items];
}

final class StationSalesListLoaded extends ListLoadState {
  const StationSalesListLoaded({
    required this.sales,
    required this.debtEntries,
  });

  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> debtEntries;

  @override
  List<Object?> get props => <Object?>[sales, debtEntries];
}

final class ListLoadFailure extends ListLoadState {
  const ListLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
