import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/features/host/data/models/block_reason_model.dart';
import 'package:houseiana_mobile_app/features/host/data/models/calendar_day_model.dart';

abstract class HostCalendarManagementState extends Equatable {
  const HostCalendarManagementState();

  @override
  List<Object?> get props => [];
}

class HostCalendarManagementInitial extends HostCalendarManagementState {
  const HostCalendarManagementInitial();
}

class HostCalendarManagementLoading extends HostCalendarManagementState {
  const HostCalendarManagementLoading();
}

class HostCalendarManagementError extends HostCalendarManagementState {
  final String message;
  const HostCalendarManagementError(this.message);

  bool get isNotLoggedIn => message == 'not-logged-in';

  @override
  List<Object?> get props => [message];
}

class HostCalendarManagementLoaded extends HostCalendarManagementState {
  final List<PropertyModel> properties;
  final PropertyModel? selectedProperty;

  /// Keyed by `yyyy-MM-dd`.
  final Map<String, CalendarDay> dailyRates;
  final Set<DateTime> blockedDates;
  final List<CalendarBooking> bookings;
  final String currency;

  /// First day of the visible month.
  final DateTime focusedMonth;
  final int minNights;
  final List<BlockReason> reasons;

  /// Currently selected (normalized) days.
  final Set<DateTime> selectedDates;

  // Busy flags
  final bool calendarLoading;
  final bool busyBlock;
  final bool busyPrice;
  final bool busyMinNights;

  // One-shot message for the screen listener (keyed by [messageTick]).
  final String? message;
  final bool messageIsError;
  final int messageTick;

  const HostCalendarManagementLoaded({
    required this.properties,
    required this.selectedProperty,
    required this.dailyRates,
    required this.blockedDates,
    required this.bookings,
    required this.currency,
    required this.focusedMonth,
    required this.minNights,
    required this.reasons,
    required this.selectedDates,
    this.calendarLoading = false,
    this.busyBlock = false,
    this.busyPrice = false,
    this.busyMinNights = false,
    this.message,
    this.messageIsError = false,
    this.messageTick = 0,
  });

  bool get hasSelection => selectedDates.isNotEmpty;

  bool get hasProperties => properties.isNotEmpty;

  /// Selected days sorted ascending.
  List<DateTime> get sortedSelection =>
      selectedDates.toList()..sort((a, b) => a.compareTo(b));

  /// True when every selected day is currently blocked (→ offer Unblock).
  bool get selectionAllBlocked =>
      selectedDates.isNotEmpty &&
      selectedDates.every((d) => blockedDates.contains(d));

  /// Days that are check-out days (the day after a reservation's last night).
  Set<DateTime> get checkoutDays =>
      bookings.map((b) => b.checkoutDay).toSet();

  /// Price currently applied to the selected range (first selected day).
  double? get selectedPrice {
    if (selectedDates.isEmpty) return null;
    final first = sortedSelection.first;
    return dailyRates[dayKey(first)]?.price;
  }

  HostCalendarManagementLoaded copyWith({
    List<PropertyModel>? properties,
    PropertyModel? selectedProperty,
    Map<String, CalendarDay>? dailyRates,
    Set<DateTime>? blockedDates,
    List<CalendarBooking>? bookings,
    String? currency,
    DateTime? focusedMonth,
    int? minNights,
    List<BlockReason>? reasons,
    Set<DateTime>? selectedDates,
    bool? calendarLoading,
    bool? busyBlock,
    bool? busyPrice,
    bool? busyMinNights,
    String? message,
    bool? messageIsError,
    int? messageTick,
  }) {
    return HostCalendarManagementLoaded(
      properties: properties ?? this.properties,
      selectedProperty: selectedProperty ?? this.selectedProperty,
      dailyRates: dailyRates ?? this.dailyRates,
      blockedDates: blockedDates ?? this.blockedDates,
      bookings: bookings ?? this.bookings,
      currency: currency ?? this.currency,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      minNights: minNights ?? this.minNights,
      reasons: reasons ?? this.reasons,
      selectedDates: selectedDates ?? this.selectedDates,
      calendarLoading: calendarLoading ?? this.calendarLoading,
      busyBlock: busyBlock ?? this.busyBlock,
      busyPrice: busyPrice ?? this.busyPrice,
      busyMinNights: busyMinNights ?? this.busyMinNights,
      message: message ?? this.message,
      messageIsError: messageIsError ?? this.messageIsError,
      messageTick: messageTick ?? this.messageTick,
    );
  }

  @override
  List<Object?> get props => [
        properties,
        selectedProperty,
        dailyRates,
        blockedDates,
        bookings,
        currency,
        focusedMonth,
        minNights,
        reasons,
        selectedDates,
        calendarLoading,
        busyBlock,
        busyPrice,
        busyMinNights,
        message,
        messageIsError,
        messageTick,
      ];
}
