import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/booking/cubit/booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final UserService _userService;
  final PropertyService _propertyService;
  final UserSession _userSession;

  BookingCubit(this._userService, this._propertyService, this._userSession)
      : super(BookingInitial());

  Future<void> createBooking({
    required String propertyId,
    required String hostId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    String? message,
  }) async {
    emit(BookingLoading());
    if (!_userSession.isLoggedIn) {
      emit(const BookingError('Please sign in to continue with your booking.'));
      return;
    }

    try {
      final availability = await _propertyService.getAvailability(
        propertyId,
        checkIn: checkIn.toIso8601String(),
        checkOut: checkOut.toIso8601String(),
      );
      final isAvailable = availability == null ||
          availability['isAvailable'] == true ||
          availability['available'] == true;
      if (!isAvailable) {
        emit(const BookingError(
          'Selected dates are not available. Please choose different dates.',
        ));
        return;
      }

      final now = DateTime.now();
      DateTime adjustedCheckIn = checkIn;
      if (checkIn.year == now.year && checkIn.month == now.month && checkIn.day == now.day) {
         adjustedCheckIn = now.add(const Duration(hours: 1));
      } else {
         adjustedCheckIn = DateTime(checkIn.year, checkIn.month, checkIn.day, 14, 0, 0);
      }
      DateTime adjustedCheckOut = DateTime(checkOut.year, checkOut.month, checkOut.day, 11, 0, 0);

      final booking = await _userService.createBooking({
        'propertyId': propertyId,
        'guestId': _userSession.userId,
        'hostId': hostId,
        'checkIn': adjustedCheckIn.toUtc().toIso8601String(),
        'checkOut': adjustedCheckOut.toUtc().toIso8601String(),
        'guests': guests,
        if (message != null && message.isNotEmpty) 'message': message,
      });
      if (booking != null) {
        emit(BookingCreated(booking));
      } else {
        emit(const BookingError('Failed to create booking'));
      }
    } on ServerException catch (e) {
      emit(BookingError(e.message));
    } catch (e) {
      emit(BookingError('Failed to create booking: $e'));
    }
  }

  void reset() => emit(BookingInitial());
}
