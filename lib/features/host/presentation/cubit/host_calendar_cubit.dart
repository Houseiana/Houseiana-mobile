import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/host_calendar_service.dart';

/// States for host calendar
abstract class HostCalendarState {
  const HostCalendarState();
}

class HostCalendarInitial extends HostCalendarState {}

class HostCalendarLoading extends HostCalendarState {}

class HostCalendarLoaded extends HostCalendarState {
  final List<DateTime> blockedDates;
  final List<Map<String, dynamic>> bookings;
  final DateTime focusedMonth;

  const HostCalendarLoaded({
    required this.blockedDates,
    required this.bookings,
    required this.focusedMonth,
  });
}

class HostCalendarError extends HostCalendarState {
  final String message;
  const HostCalendarError({required this.message});
}

class HostCalendarUpdating extends HostCalendarState {
  final List<DateTime> currentBlockedDates;
  final List<Map<String, dynamic>> bookings;

  const HostCalendarUpdating({
    required this.currentBlockedDates,
    required this.bookings,
  });
}

/// Cubit for managing host availability calendar.
class HostCalendarCubit extends Cubit<HostCalendarState> {
  final HostCalendarService _calendarService;

  String? _currentPropertyId;
  String? _currentHostId;

  HostCalendarCubit({HostCalendarService? calendarService})
      : _calendarService = calendarService ?? HostCalendarService(),
        super(HostCalendarInitial());

  /// Loads the calendar for a property.
  Future<void> loadCalendar({
    required String propertyId,
    required String hostId,
    DateTime? focusedMonth,
  }) async {
    emit(HostCalendarLoading());
    try {
      _currentPropertyId = propertyId;
      _currentHostId = hostId;
      final month = focusedMonth ?? DateTime.now();

      // Fetch calendar data
      final calendarData =
          await _calendarService.getAvailabilityCalendar(propertyId);

      // Parse blocked dates
      final blockedDates = _parseBlockedDates(calendarData);

      // Fetch bookings for this month
      final bookings =
          await _calendarService.getPropertyBookings(propertyId);

      emit(HostCalendarLoaded(
        blockedDates: blockedDates,
        bookings: bookings,
        focusedMonth: month,
      ));
    } catch (e) {
      emit(HostCalendarError(message: e.toString()));
    }
  }

  /// Blocks a date range.
  Future<void> blockDates({
    required List<DateTime> dates,
  }) async {
    if (_currentPropertyId == null || _currentHostId == null) return;

    final currentState = state;
    if (currentState is HostCalendarLoaded) {
      emit(HostCalendarUpdating(
        currentBlockedDates: currentState.blockedDates,
        bookings: currentState.bookings,
      ));

      try {
        final blockedDatesStrings =
            dates.map((d) => d.toIso8601String().split('T').first).toList();

        final result = await _calendarService.updateBlockedDates(
          propertyId: _currentPropertyId!,
          blockedDates: blockedDatesStrings,
          hostId: _currentHostId!,
        );

        if (result['success'] == true) {
          // Reload calendar
          await loadCalendar(
            propertyId: _currentPropertyId!,
            hostId: _currentHostId!,
          );
        } else {
          emit(HostCalendarError(
            message: result['message']?.toString() ?? 'Failed to block dates',
          ));
        }
      } catch (e) {
        emit(HostCalendarError(message: e.toString()));
      }
    }
  }

  /// Unblocks a date range.
  Future<void> unblockDates({
    required List<DateTime> dates,
  }) async {
    if (_currentPropertyId == null || _currentHostId == null) return;

    final currentState = state;
    if (currentState is HostCalendarLoaded) {
      emit(HostCalendarUpdating(
        currentBlockedDates: currentState.blockedDates,
        bookings: currentState.bookings,
      ));

      try {
        final datesStrings =
            dates.map((d) => d.toIso8601String().split('T').first).toList();

        final result = await _calendarService.unblockDates(
          propertyId: _currentPropertyId!,
          datesToUnblock: datesStrings,
          hostId: _currentHostId!,
        );

        if (result['success'] == true) {
          // Reload calendar
          await loadCalendar(
            propertyId: _currentPropertyId!,
            hostId: _currentHostId!,
          );
        } else {
          emit(HostCalendarError(
            message: result['message']?.toString() ?? 'Failed to unblock dates',
          ));
        }
      } catch (e) {
        emit(HostCalendarError(message: e.toString()));
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  List<DateTime> _parseBlockedDates(Map<String, dynamic>? data) {
    if (data == null) return [];
    final dates = data['blockedDates'] as List<dynamic>?;
    if (dates == null) return [];
    return dates
        .whereType<String>()
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .toList();
  }
}
