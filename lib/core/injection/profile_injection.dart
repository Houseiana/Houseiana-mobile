import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/identity_verification_cubit.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/payment_methods_cubit.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/saved_addresses_cubit.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/cubit/owner_profile_cubit.dart';

Future<void> initProfile() async {
  sl.registerFactory(() => IdentityVerificationCubit(
        sl<UserService>(),
        sl<UserSession>(),
      ));
  sl.registerFactory(() => SavedAddressesCubit(
        sl<UserService>(),
        sl<UserSession>(),
      ));
  sl.registerFactory(() => PaymentMethodsCubit(
        sl<UserService>(),
        sl<UserSession>(),
      ));
  sl.registerFactory(() => OwnerProfileCubit());
}
