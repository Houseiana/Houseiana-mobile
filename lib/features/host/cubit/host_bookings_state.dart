import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';

abstract class HostBookingsState extends Equatable {
  const HostBookingsState();

  @override
  List<Object?> get props => [];
}

class HostBookingsInitial extends HostBookingsState {}

class HostBookingsLoading extends HostBookingsState {}

class HostBookingsLoaded extends HostBookingsState {
  final List<BookingModel> bookings;
  final List<Map<String, dynamic>> statuses;
  final int? selectedStatusId;
  final BookingStats stats;

  /// Host properties for the "All properties" filter dropdown, each `{id, name}`.
  final List<Map<String, dynamic>> properties;
  final String? selectedPropertyId;

  const HostBookingsLoaded({
    required this.bookings,
    required this.statuses,
    this.selectedStatusId,
    this.stats = BookingStats.empty,
    this.properties = const [],
    this.selectedPropertyId,
  });

  @override
  List<Object?> get props => [
        bookings,
        statuses,
        selectedStatusId,
        stats,
        properties,
        selectedPropertyId,
      ];
}

class HostBookingsError extends HostBookingsState {
  final String message;
  const HostBookingsError(this.message);

  @override
  List<Object?> get props => [message];
}
