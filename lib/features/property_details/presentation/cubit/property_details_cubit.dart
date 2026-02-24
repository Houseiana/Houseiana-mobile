import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_state.dart';

class PropertyDetailsCubit extends Cubit<PropertyDetailsState> {
  PropertyDetailsCubit() : super(PropertyDetailsInitial());

  Future<void> getPropertyDetails(String id) async {
    emit(PropertyDetailsLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const PropertyDetailsLoaded(property: null));
    } catch (e) {
      emit(PropertyDetailsError(message: e.toString()));
    }
  }
}
