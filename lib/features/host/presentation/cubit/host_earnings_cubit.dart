import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/earnings_service.dart';

/// States for host earnings analytics
abstract class HostEarningsState {
  const HostEarningsState();
}

class HostEarningsInitial extends HostEarningsState {}

class HostEarningsLoading extends HostEarningsState {}

class HostEarningsLoaded extends HostEarningsState {
  final double totalEarnings;
  final double occupancyRate;
  final double averageDailyRate;
  final List<MonthlyEarning> monthlyEarnings;
  final int totalBookings;
  final int year;

  const HostEarningsLoaded({
    required this.totalEarnings,
    required this.occupancyRate,
    required this.averageDailyRate,
    required this.monthlyEarnings,
    required this.totalBookings,
    required this.year,
  });
}

class HostEarningsError extends HostEarningsState {
  final String message;
  const HostEarningsError({required this.message});
}

/// Monthly earnings data point
class MonthlyEarning {
  final int month;
  final double earnings;
  final int bookings;
  final double occupancy;

  const MonthlyEarning({
    required this.month,
    required this.earnings,
    required this.bookings,
    required this.occupancy,
  });

  factory MonthlyEarning.fromJson(Map<String, dynamic> json) {
    return MonthlyEarning(
      month: json['month'] as int? ?? 1,
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0,
      bookings: json['bookings'] as int? ?? 0,
      occupancy: (json['occupancy'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Cubit for host earnings analytics
class HostEarningsCubit extends Cubit<HostEarningsState> {
  final EarningsService _earningsService;

  HostEarningsCubit({EarningsService? earningsService})
      : _earningsService = earningsService ?? EarningsService(),
        super(HostEarningsInitial());

  /// Loads earnings data for a host
  Future<void> loadEarnings({
    required String hostId,
    int? year,
  }) async {
    emit(HostEarningsLoading());
    try {
      final targetYear = year ?? DateTime.now().year;

      final summaryFuture =
          _earningsService.getEarningsSummary(hostId, year: targetYear);
      final monthlyFuture =
          _earningsService.getMonthlyEarnings(hostId, year: targetYear);
      final occupancyFuture =
          _earningsService.getOccupancyRate(hostId, year: targetYear);
      final adrFuture =
          _earningsService.getAverageDailyRate(hostId, year: targetYear);

      final earningsData = await summaryFuture;
      final monthlyData = await monthlyFuture;
      final occupancyData = await occupancyFuture;
      final adrData = await adrFuture;

      final totalEarnings = (earningsData['totalEarnings'] as num?)?.toDouble() ?? 0;
      final totalBookings = earningsData['totalBookings'] as int? ?? 0;
      final occupancyRate = (occupancyData['occupancyRate'] as num?)?.toDouble() ?? 0;
      final averageDailyRate = (adrData['adr'] as num?)?.toDouble() ?? 0;

      final monthlyEarnings = monthlyData
          .map((m) => MonthlyEarning.fromJson(m))
          .toList();

      emit(HostEarningsLoaded(
        totalEarnings: totalEarnings,
        occupancyRate: occupancyRate,
        averageDailyRate: averageDailyRate,
        monthlyEarnings: monthlyEarnings,
        totalBookings: totalBookings,
        year: targetYear,
      ));
    } catch (e) {
      emit(HostEarningsError(message: e.toString()));
    }
  }
}
