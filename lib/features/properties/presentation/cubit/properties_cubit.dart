import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/cubit/properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  PropertiesCubit() : super(PropertiesInitial());

  Future<void> getProperties() async {
    emit(PropertiesLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const PropertiesLoaded(properties: []));
    } catch (e) {
      emit(PropertiesError(message: e.toString()));
    }
  }

  Future<void> searchProperties(String query) async {
    emit(PropertiesLoading());
    try {
      // TODO: Implement actual search
      await Future.delayed(const Duration(seconds: 1));
      emit(const PropertiesLoaded(properties: []));
    } catch (e) {
      emit(PropertiesError(message: e.toString()));
    }
  }
}
