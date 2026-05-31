import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';

abstract class PaymentMethodsState extends Equatable {
  const PaymentMethodsState();

  @override
  List<Object?> get props => [];
}

class PaymentMethodsInitial extends PaymentMethodsState {}

class PaymentMethodsLoading extends PaymentMethodsState {}

class PaymentMethodsLoaded extends PaymentMethodsState {
  final List<PaymentMethodModel> methods;

  const PaymentMethodsLoaded(this.methods);

  @override
  List<Object?> get props => [methods];
}

class PaymentMethodsError extends PaymentMethodsState {
  final String message;

  const PaymentMethodsError(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentMethodDeleting extends PaymentMethodsState {
  final List<PaymentMethodModel> methods;
  final String methodId;

  const PaymentMethodDeleting(this.methods, this.methodId);

  @override
  List<Object?> get props => [methods, methodId];
}
