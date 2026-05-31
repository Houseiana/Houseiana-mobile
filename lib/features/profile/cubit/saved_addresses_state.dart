import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';

abstract class SavedAddressesState extends Equatable {
  const SavedAddressesState();

  @override
  List<Object?> get props => [];
}

class SavedAddressesInitial extends SavedAddressesState {}

class SavedAddressesLoading extends SavedAddressesState {}

class SavedAddressesLoaded extends SavedAddressesState {
  final List<AddressModel> addresses;

  const SavedAddressesLoaded(this.addresses);

  @override
  List<Object?> get props => [addresses];
}

class SavedAddressesError extends SavedAddressesState {
  final String message;

  const SavedAddressesError(this.message);

  @override
  List<Object?> get props => [message];
}

class SavedAddressAdding extends SavedAddressesState {
  final List<AddressModel> addresses;

  const SavedAddressAdding(this.addresses);

  @override
  List<Object?> get props => [addresses];
}

class SavedAddressDeleting extends SavedAddressesState {
  final List<AddressModel> addresses;
  final String addressId;

  const SavedAddressDeleting(this.addresses, this.addressId);

  @override
  List<Object?> get props => [addresses, addressId];
}

class SavedAddressUpdating extends SavedAddressesState {
  final List<AddressModel> addresses;
  final String addressId;

  const SavedAddressUpdating(this.addresses, this.addressId);

  @override
  List<Object?> get props => [addresses, addressId];
}
