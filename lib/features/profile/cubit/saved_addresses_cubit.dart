import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/saved_addresses_state.dart';

class SavedAddressesCubit extends Cubit<SavedAddressesState> {
  final UserService _userService;
  final UserSession _userSession;

  SavedAddressesCubit(this._userService, this._userSession)
      : super(SavedAddressesInitial());

  Future<void> loadAddresses() async {
    emit(SavedAddressesLoading());
    final userId = _userSession.userId;
    if (userId == null) {
      emit(const SavedAddressesError('User not found'));
      return;
    }
    try {
      final addresses = await _userService.getAddresses(userId);
      emit(SavedAddressesLoaded(addresses));
    } catch (e) {
      emit(SavedAddressesError('Failed to load addresses: $e'));
    }
  }

  Future<void> addAddress({
    required String label,
    required String street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool isDefault = false,
  }) async {
    final currentState = this.state;
    final addresses = currentState is SavedAddressesLoaded
        ? currentState.addresses
        : <AddressModel>[];
    emit(SavedAddressAdding(addresses));

    final userId = _userSession.userId;
    if (userId == null) {
      emit(const SavedAddressesError('User not found'));
      return;
    }

    final body = {
      'label': label,
      'street': street,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (country != null) 'country': country,
      'isDefault': isDefault,
    };

    try {
      final result = await _userService.addAddress(userId, body);
      if (result != null) {
        final updated = List<AddressModel>.from(addresses)..add(result);
        emit(SavedAddressesLoaded(updated));
      } else {
        emit(SavedAddressesError('Failed to add address'));
        emit(SavedAddressesLoaded(addresses));
      }
    } catch (e) {
      emit(SavedAddressesError('Failed to add address: $e'));
      emit(SavedAddressesLoaded(addresses));
    }
  }

  Future<void> updateAddress({
    required String addressId,
    required String label,
    required String street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool? isDefault,
  }) async {
    final currentState = this.state;
    if (currentState is! SavedAddressesLoaded) return;
    final addresses = currentState.addresses;
    emit(SavedAddressUpdating(addresses, addressId));

    final userId = _userSession.userId;
    if (userId == null) {
      emit(const SavedAddressesError('User not found'));
      return;
    }

    final body = {
      'label': label,
      'street': street,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (country != null) 'country': country,
      if (isDefault != null) 'isDefault': isDefault,
    };

    try {
      final result = await _userService.updateAddress(userId, addressId, body);
      if (result != null) {
        final updated = addresses
            .map((address) => address.id == addressId ? result : address)
            .toList();
        emit(SavedAddressesLoaded(updated));
      } else {
        emit(const SavedAddressesError('Failed to update address'));
        emit(SavedAddressesLoaded(addresses));
      }
    } catch (e) {
      emit(SavedAddressesError('Failed to update address: $e'));
      emit(SavedAddressesLoaded(addresses));
    }
  }

  Future<void> deleteAddress(String addressId) async {
    final currentState = state;
    if (currentState is! SavedAddressesLoaded) return;
    final addresses = currentState.addresses;

    emit(SavedAddressDeleting(addresses, addressId));

    final userId = _userSession.userId;
    if (userId == null) {
      emit(const SavedAddressesError('User not found'));
      return;
    }

    try {
      final success = await _userService.deleteAddress(userId, addressId);
      if (success) {
        final updated = addresses.where((a) => a.id != addressId).toList();
        emit(SavedAddressesLoaded(updated));
      } else {
        emit(const SavedAddressesError('Failed to delete address'));
        emit(SavedAddressesLoaded(addresses));
      }
    } catch (e) {
      emit(SavedAddressesError('Failed to delete address: $e'));
      emit(SavedAddressesLoaded(addresses));
    }
  }
}
