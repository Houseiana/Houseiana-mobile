import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/payment_methods_state.dart';

class PaymentMethodsCubit extends Cubit<PaymentMethodsState> {
  final UserService _userService;
  final UserSession _userSession;

  PaymentMethodsCubit(this._userService, this._userSession)
      : super(PaymentMethodsInitial());

  Future<void> loadPaymentMethods() async {
    emit(PaymentMethodsLoading());
    final userId = _userSession.userId;
    if (userId == null) {
      emit(const PaymentMethodsError('User not found'));
      return;
    }
    try {
      final methods = await _userService.getPaymentMethods(userId);
      emit(PaymentMethodsLoaded(methods));
    } catch (e) {
      emit(PaymentMethodsError('Failed to load payment methods: $e'));
    }
  }

  Future<void> deletePaymentMethod(String methodId) async {
    final currentState = state;
    if (currentState is! PaymentMethodsLoaded) return;
    final methods = currentState.methods;

    emit(PaymentMethodDeleting(methods, methodId));

    final userId = _userSession.userId;
    if (userId == null) {
      emit(const PaymentMethodsError('User not found'));
      return;
    }

    try {
      final success = await _userService.deletePaymentMethod(userId, methodId);
      if (success) {
        final updated = methods.where((m) => m.id != methodId).toList();
        emit(PaymentMethodsLoaded(updated));
      } else {
        emit(const PaymentMethodsError('Failed to delete payment method'));
        emit(PaymentMethodsLoaded(methods));
      }
    } catch (e) {
      emit(PaymentMethodsError('Failed to delete payment method: $e'));
      emit(PaymentMethodsLoaded(methods));
    }
  }

  Future<void> addCardPaymentMethod({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String cardholderName,
  }) async {
    final currentState = state;
    if (currentState is! PaymentMethodsLoaded) return;
    final methods = currentState.methods;

    final userId = _userSession.userId;
    if (userId == null) {
      emit(const PaymentMethodsError('User not found'));
      return;
    }

    final body = {
      'type': 'card',
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvc': cvc,
      'cardholderName': cardholderName,
    };

    try {
      final result = await _userService.addPaymentMethod(userId, body);
      if (result != null) {
        final updated = List<PaymentMethodModel>.from(methods)..add(result);
        emit(PaymentMethodsLoaded(updated));
      } else {
        emit(const PaymentMethodsError('Failed to add card'));
        emit(PaymentMethodsLoaded(methods));
      }
    } catch (e) {
      emit(PaymentMethodsError('Failed to add card: $e'));
      emit(PaymentMethodsLoaded(methods));
    }
  }

  Future<void> addPayPalPaymentMethod({
    required String email,
  }) async {
    final currentState = state;
    if (currentState is! PaymentMethodsLoaded) return;
    final methods = currentState.methods;

    final userId = _userSession.userId;
    if (userId == null) {
      emit(const PaymentMethodsError('User not found'));
      return;
    }

    final body = {
      'type': 'paypal',
      'email': email,
      'paypalEmail': email,
      'userId': userId,
    };

    try {
      final result = await _userService.addPaymentMethod(userId, body);
      if (result != null) {
        final updated = List<PaymentMethodModel>.from(methods)..add(result);
        emit(PaymentMethodsLoaded(updated));
      } else {
        emit(const PaymentMethodsError('Failed to add PayPal account'));
        emit(PaymentMethodsLoaded(methods));
      }
    } catch (e) {
      emit(PaymentMethodsError('Failed to add PayPal account: $e'));
      emit(PaymentMethodsLoaded(methods));
    }
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    final currentState = state;
    if (currentState is! PaymentMethodsLoaded) return;
    final methods = currentState.methods;

    final userId = _userSession.userId;
    if (userId == null) {
      emit(const PaymentMethodsError('User not found'));
      return;
    }

    try {
      final success =
          await _userService.setDefaultPaymentMethod(userId, methodId);
      if (success) {
        final updated = methods.map((m) {
          return PaymentMethodModel(
            id: m.id,
            type: m.type,
            last4: m.last4,
            brand: m.brand,
            expiryMonth: m.expiryMonth,
            expiryYear: m.expiryYear,
            email: m.email,
            isDefault: m.id == methodId,
          );
        }).toList();
        emit(PaymentMethodsLoaded(updated));
      } else {
        emit(const PaymentMethodsError('Failed to set default payment method'));
        emit(PaymentMethodsLoaded(methods));
      }
    } catch (e) {
      emit(PaymentMethodsError('Failed to set default payment method: $e'));
      emit(PaymentMethodsLoaded(methods));
    }
  }
}
