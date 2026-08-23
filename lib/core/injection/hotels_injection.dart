import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/services/hotel_favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/hotel_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_booking_cubit.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_details_cubit.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_review_cubit.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_search_cubit.dart';

void initHotels() {
  // Hotels ride the app-wide client, so they follow `AppConfig.environment`
  // like every other feature — which is also why they only work on a build
  // pointed at staging: production has none of these endpoints deployed and
  // 404s on all of them. `HotelService.available` is what keeps that from
  // costing a full timeout on every visit.
  sl.registerLazySingleton(() => HotelService(sl<ApiConsumer>()));

  // Hotel wishlist ids live in their own notifier — see the class doc for why
  // they cannot share FavoritesNotifier.
  sl.registerLazySingleton(() => HotelFavoritesNotifier());

  // Cubits are factories — they hold per-screen state.
  sl.registerFactory(
    () => HotelSearchCubit(sl<HotelService>(), sl<UserSession>()),
  );
  sl.registerFactoryParam<HotelDetailsCubit, String, void>(
    (hotelId, _) =>
        HotelDetailsCubit(sl<HotelService>(), sl<UserSession>(), hotelId),
  );
  sl.registerFactory(
    () => HotelBookingCubit(sl<HotelService>(), sl<UserSession>()),
  );
  sl.registerFactoryParam<HotelReviewCubit, String, void>(
    (hotelId, _) =>
        HotelReviewCubit(sl<HotelService>(), sl<UserSession>(), hotelId),
  );
}
