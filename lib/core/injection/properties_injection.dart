import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/services/host_calendar_service.dart';
import 'package:houseiana_mobile_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/cubit/properties_cubit.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/nightly_prices_cubit.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_cubit.dart';
import 'package:houseiana_mobile_app/features/properties/cubit/search_cubit.dart';

void initProperties() {
  sl.registerLazySingleton(() => HostCalendarService());
  sl.registerFactory(
      () => PropertiesCubit(sl<PropertyService>(), sl<UserSession>()));
  sl.registerFactory(() => PropertyDetailsCubit(sl<PropertyService>()));
  sl.registerFactory(
      () => FavoritesCubit(sl<UserService>(), sl<UserSession>()));
  sl.registerFactory(() =>
      SearchCubit(sl<PropertyService>(), sl<UserService>(), sl<UserSession>()));
  sl.registerFactoryParam<NightlyPricesCubit, String, void>(
    (propertyId, _) => NightlyPricesCubit(sl<PropertyService>(), propertyId),
  );
}
