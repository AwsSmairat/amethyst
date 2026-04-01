import 'package:equatable/equatable.dart';

sealed class SubmitState extends Equatable {
  const SubmitState();

  @override
  List<Object?> get props => <Object?>[];
}

final class SubmitIdle extends SubmitState {
  const SubmitIdle();
}

final class SubmitLoading extends SubmitState {
  const SubmitLoading();
}

final class SubmitSuccess extends SubmitState {
  const SubmitSuccess();
}

final class SubmitFailure extends SubmitState {
  const SubmitFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
