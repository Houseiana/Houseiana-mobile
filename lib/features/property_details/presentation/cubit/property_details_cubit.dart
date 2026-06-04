import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_state.dart';

class PropertyDetailsCubit extends Cubit<PropertyDetailsState> {
  final PropertyService _propertyService;

  PropertyDetailsCubit(this._propertyService) : super(PropertyDetailsInitial());

  Future<void> getPropertyDetails(
    String id, {
    String? userId,
    String? checkIn,
    String? checkOut,
  }) async {
    emit(PropertyDetailsLoading());
    try {
      final property = await _propertyService.getPropertyById(
        id,
        userId: userId,
        checkIn: checkIn,
        checkOut: checkOut,
      );
      if (property != null) {
        emit(PropertyDetailsLoaded(property: property));
      } else {
        emit(const PropertyDetailsError(message: 'propertyDetails.propertyNotFound'));
      }
    } catch (e) {
      emit(PropertyDetailsError(message: e.toString()));
    }
  }

  Future<void> loadRatings(String propertyId, {bool loadMore = false}) async {
    final current = state;
    if (current is! PropertyDetailsLoaded) return;

    final nextPage = loadMore ? current.ratingsPage + 1 : 1;
    const limit = 10;

    try {
      final allRatings = await _propertyService.getRatingsPaginated(
        propertyId,
        page: nextPage,
        limit: limit,
      );
      final hasMore = allRatings.length >= limit;
      final ratings =
          loadMore ? [...current.ratings, ...allRatings] : allRatings;
      emit(current.copyWith(
        ratings: ratings,
        ratingsPage: nextPage,
        hasMoreRatings: hasMore,
      ));
    } catch (e) {
      emit(PropertyDetailsError(message: e.toString()));
    }
  }
}
