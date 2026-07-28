import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_state.dart';

class PropertyDetailsCubit extends Cubit<PropertyDetailsState> {
  final PropertyService _propertyService;

  PropertyDetailsCubit(this._propertyService) : super(PropertyDetailsInitial());

  /// Aborts the in-flight details request when the screen is popped
  /// mid-load (the cubit closes with it).
  final CancelToken _cancelToken = CancelToken();

  @override
  Future<void> close() {
    _cancelToken.cancel();
    return super.close();
  }

  /// Loads a property for the details screen.
  ///
  /// The nightly price shown comes straight from `/api/property-search/{id}` —
  /// its `pricePerNight` / `priceWithoutDiscount` / `discountPercent`, the same
  /// three keys the list rows carry. Nothing is substituted or recomputed here:
  /// whatever that endpoint returns is what the page shows.
  ///
  /// No user id is passed on: the endpoint prices personally when it gets one
  /// (see `PropertyService.getPropertyById`), which would make this page read a
  /// different nightly price for a signed-in guest than for everyone else.
  Future<void> getPropertyDetails(
    String id, {
    String? checkIn,
    String? checkOut,
  }) async {
    emit(PropertyDetailsLoading());
    try {
      final property = await _propertyService.getPropertyById(
        id,
        checkIn: checkIn,
        checkOut: checkOut,
        cancelToken: _cancelToken,
      );
      if (isClosed) return;
      if (property != null) {
        emit(PropertyDetailsLoaded(property: property));
      } else {
        emit(const PropertyDetailsError(
            message: 'propertyDetails.propertyNotFound'));
      }
    } on RequestCancelledException {
      return; // screen popped mid-load — nothing to show
    } catch (e) {
      if (isClosed) return;
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
