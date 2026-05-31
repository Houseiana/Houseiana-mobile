import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/host_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_bookings_state.dart';

class HostBookingsCubit extends Cubit<HostBookingsState> {
  final HostService _hostService;
  final UserSession _session;

  HostBookingsCubit(this._hostService, this._session)
      : super(HostBookingsInitial());

  List<Map<String, dynamic>> _cachedStatuses = [];
  int? _currentStatusId;
  String? _currentGuestName;
  String? _currentPropertyId;

  Future<void> loadBookings() async {
    final userId = _session.userId;
    if (userId == null) {
      emit(const HostBookingsError('Not logged in'));
      return;
    }

    emit(HostBookingsLoading());
    try {
      if (_cachedStatuses.isEmpty) {
        _cachedStatuses = await _hostService.getBookingStatuses();
      }

      final bookings = await _hostService.getHostBookings(
        userId,
        statusId: _currentStatusId,
        guestName: _currentGuestName,
        propertyId: _currentPropertyId,
      );

      emit(HostBookingsLoaded(
        bookings: bookings,
        statuses: _cachedStatuses,
        selectedStatusId: _currentStatusId,
      ));
    } catch (e) {
      emit(HostBookingsError(e.toString()));
    }
  }

  void filterByStatus(int? statusId) {
    _currentStatusId = statusId;
    loadBookings();
  }

  void search({String? guestName, String? propertyId}) {
    _currentGuestName = guestName;
    _currentPropertyId = propertyId;
    loadBookings();
  }

  Future<void> acceptBooking(String bookingId) async {
    try {
      final hostId = _session.userId;
      if (hostId == null) {
        emit(const HostBookingsError('Not logged in'));
        return;
      }
      await _hostService.approveBooking(bookingId, hostId: hostId);
      await loadBookings();
    } catch (e) {
      emit(HostBookingsError(e.toString()));
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      final userId = _session.userId;
      if (userId == null) {
        emit(const HostBookingsError('Not logged in'));
        return;
      }
      await _hostService.cancelBooking(bookingId, userId: userId);
      await loadBookings();
    } catch (e) {
      emit(HostBookingsError(e.toString()));
    }
  }
}
