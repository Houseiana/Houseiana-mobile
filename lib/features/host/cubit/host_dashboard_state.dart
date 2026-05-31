import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';

abstract class HostDashboardState extends Equatable {
  const HostDashboardState();

  @override
  List<Object?> get props => [];
}

class HostDashboardInitial extends HostDashboardState {}

class HostDashboardLoading extends HostDashboardState {}

class HostDashboardLoaded extends HostDashboardState {
  final List<PropertyModel> properties;
  final List<BookingModel> bookings;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> earnings;

  const HostDashboardLoaded({
    required this.properties,
    required this.bookings,
    required this.stats,
    required this.earnings,
  });

  int get propertiesCount => properties.length;
  int get bookingsCount => bookings.length;

  double get averageRating {
    if (properties.isEmpty) return 0;
    final ratings = properties
        .map((p) => p.rating ?? 0)
        .where((r) => r > 0)
        .toList();
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  double get totalEarnings {
    final total = earnings['total'] ??
        earnings['totalEarnings'] ??
        earnings['amount'] ??
        0;
    return (total is num) ? total.toDouble() : 0;
  }

  List<PropertyModel> get recentProperties => properties.take(3).toList();

  List<BookingModel> get recentBookings => bookings.take(3).toList();

  @override
  List<Object?> get props => [properties, bookings, stats, earnings];
}

class HostDashboardError extends HostDashboardState {
  final String message;
  const HostDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
