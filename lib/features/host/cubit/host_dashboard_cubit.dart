import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/services/host_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_dashboard_state.dart';

class HostDashboardCubit extends Cubit<HostDashboardState> {
  final _hostService = sl<HostService>();
  final _session = sl<UserSession>();

  HostDashboardCubit() : super(HostDashboardInitial());

  Future<void> loadDashboard() async {
    if (!_session.isLoggedIn) {
      emit(const HostDashboardError('Not logged in'));
      return;
    }

    emit(HostDashboardLoading());

    final userId = _session.userId!;

    try {
      final listingsFuture = _hostService.getHostListings(userId);
      final bookingsFuture = _hostService.getHostBookings(userId);
      final statsFuture = _hostService.getHostStats(userId);

      final properties = await listingsFuture;
      final bookings = await bookingsFuture;
      final stats = await statsFuture;

      emit(HostDashboardLoaded(
        properties: properties,
        bookings: bookings,
        stats: stats,
        earnings: _calculateEarnings(bookings),
      ));
    } catch (e) {
      emit(HostDashboardError(e.toString()));
    }
  }

  Map<String, dynamic> _calculateEarnings(List<BookingModel> bookings) {
    double total = 0;
    for (final booking in bookings) {
      if (booking.status == 'CONFIRMED') {
        total += booking.totalPrice;
      }
    }
    return {'total': total};
  }
}
