import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/property_ratings.dart';
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

  /// Loads the reviews block for a property: the rows plus the aggregates the
  /// category bars are drawn from.
  ///
  /// A failure here deliberately does **not** emit [PropertyDetailsError]. This
  /// is a secondary call that lands after the page is already on screen, and
  /// letting it fail used to swap a perfectly good listing for a full-screen
  /// error. The page keeps its content and simply shows no reviews.
  Future<void> loadRatings(String propertyId) async {
    if (state is! PropertyDetailsLoaded) return;

    PropertyRatings ratings;
    try {
      ratings = await _propertyService.getPropertyRatings(propertyId);
    } catch (e) {
      if (kDebugMode) debugPrint('[PropertyRatings] load failed: $e');
      // Settled as "none" rather than left pending, so the section stops
      // waiting on a call that has already failed.
      ratings = PropertyRatings.empty;
    }

    if (isClosed) return;
    // Re-read: the guest may have navigated the cubit elsewhere while this was
    // in flight, and the ratings belong to the property that was loaded then.
    final latest = state;
    if (latest is! PropertyDetailsLoaded) return;
    if (latest.property.id != propertyId) return;
    emit(latest.copyWith(ratings: ratings));
  }
}
