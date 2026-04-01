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

final class ListLoadFailure extends ListLoadState {
  const ListLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
