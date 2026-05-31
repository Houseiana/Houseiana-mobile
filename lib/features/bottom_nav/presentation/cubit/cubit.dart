import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/states.dart';

class BottomNavCubit extends Cubit<BottomNavState> {
  BottomNavCubit() : super(const BottomNavState(index: 0));

  void changeIndex(int index) {
    emit(BottomNavState(index: index));
  }
}
