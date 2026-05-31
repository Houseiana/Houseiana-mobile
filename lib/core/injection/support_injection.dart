import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/support_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/support/presentation/cubit/support_cubit.dart';

Future<void> initSupport() async {
  sl.registerFactory(() => SupportCubit(
        sl<SupportService>(),
        sl<UserSession>(),
      ));
}