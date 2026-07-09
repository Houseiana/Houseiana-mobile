import 'dart:async';

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
  List<Map<String, dynamic>> _cachedProperties = [];
  int? _currentStatusId;
  String? _currentGuestName;
  String? _currentPropertyId;
  Timer? _searchDebounce;

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

      // Property list for the "All properties" filter — non-fatal on failure.
      if (_cachedProperties.isEmpty) {
        try {
          final listings = await _hostService.getHostListings(userId);
          _cachedProperties = listings
              .map((p) => {'id': p.id, 'name': p.displayTitle})
              .toList();
        } catch (_) {
          _cachedProperties = [];
        }
      }

      final page = await _hostService.getHostBookingsPage(
        userId,
        statusId: _currentStatusId,
        guestName: _currentGuestName,
        propertyId: _currentPropertyId,
      );

      emit(HostBookingsLoaded(
        bookings: page.bookings,
        statuses: _cachedStatuses,
        selectedStatusId: _currentStatusId,
        stats: page.stats,
        properties: _cachedProperties,
        selectedPropertyId: _currentPropertyId,
      ));
    } catch (e) {
      emit(HostBookingsError(e.toString()));
    }
  }

  void filterByStatus(int? statusId) {
    _currentStatusId = statusId;
    loadBookings();
  }

  /// Filters by a single property; `null`/`'all'` clears the property filter.
  void filterByProperty(String? propertyId) {
    _currentPropertyId =
        (propertyId == null || propertyId == 'all') ? null : propertyId;
    loadBookings();
  }

  /// Debounced guest-name search (500ms), mirroring the web page. Only touches
  /// the guest filter so the active property/status filters are preserved.
  void search({String? guestName}) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _currentGuestName =
          (guestName == null || guestName.isEmpty) ? null : guestName;
      loadBookings();
    });
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
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
