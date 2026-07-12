import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/payment_service.dart';
import 'package:houseiana_mobile_app/core/services/paypal_payment_service.dart';
import 'package:houseiana_mobile_app/features/booking/cubit/booking_cubit.dart';

void initBooking() {
  // Services
  sl.registerLazySingleton(
      () => PaymentService(dio: sl(), lookups: sl<LookupsCache>()));
  sl.registerLazySingleton(() => PayPalPaymentService());

  // Cubit
  sl.registerFactory(() => BookingCubit(sl(), sl(), sl()));
}
