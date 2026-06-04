import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/earnings_service.dart';
import 'package:houseiana_mobile_app/core/services/host_calendar_management_service.dart';
import 'package:houseiana_mobile_app/core/services/host_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_bookings_cubit.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart'
    show ListingWizardCubit;
import 'package:houseiana_mobile_app/features/host/presentation/cubit/host_calendar_management_cubit.dart';
import 'package:houseiana_mobile_app/features/host/presentation/cubit/host_earnings_cubit.dart';

Future<void> initHost() async {
  sl.registerFactory(() => ListingWizardCubit());
  sl.registerFactory(() => HostBookingsCubit(
        sl<HostService>(),
        sl<UserSession>(),
      ));
  sl.registerFactory(
      () => HostEarningsCubit(earningsService: sl<EarningsService>()));

  // Host Calendar (management) — new web-parity calendar.
  sl.registerLazySingleton(
      () => HostCalendarManagementService(sl<ApiConsumer>()));
  sl.registerFactory(() => HostCalendarManagementCubit(
        sl<HostCalendarManagementService>(),
        sl<UserSession>(),
      ));
}
