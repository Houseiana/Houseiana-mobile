import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/states.dart';

class BottomNavCubit extends Cubit<BottomNavState> {
  BottomNavCubit() : super(const BottomNavState(index: 0));

  // Tab positions in the shell. Screens use these with a BlocListener to
  // refresh silently when their tab becomes visible (tabs stay mounted in a
  // lazy IndexedStack, so initState no longer re-runs on each switch).
  static const int homeTab = 0;
  static const int searchTab = 1;
  static const int countryTab = 2;
  static const int tripsTab = 3;
  static const int profileTab = 4;

  void changeIndex(int index) {
    emit(BottomNavState(index: index));
  }
}
