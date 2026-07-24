import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/utils/discount_utils.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_state.dart';

/// A nightly price and its discount, all three values read off the same API
/// payload so they always describe each other.
class ResolvedNightlyPricing {
  final double price;
  final double? priceWithoutDiscount;
  final int discountPercent;

  const ResolvedNightlyPricing({
    required this.price,
    this.priceWithoutDiscount,
    this.discountPercent = 0,
  });
}

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
  /// [listRow] is the raw `/api/property-search` row the tapped card was
  /// rendered from (passed through `arguments['property']`). It matters for
  /// pricing: `/api/property-search/{id}` returns the listing's **stored base
  /// price** and always reports no discount, while the list endpoint, the guest
  /// calendar (`/nightly-prices`) and the booking quote (`/availability`) all
  /// price off the host's calendar. Rendering the details payload as-is is what
  /// made one unit read 3000 on the details page, 1400 on the card and
  /// 2000/1400 in the calendar.
  Future<void> getPropertyDetails(
    String id, {
    String? userId,
    String? checkIn,
    String? checkOut,
    Map<String, dynamic>? listRow,
  }) async {
    emit(PropertyDetailsLoading());
    try {
      final property = await _propertyService.getPropertyById(
        id,
        userId: userId,
        checkIn: checkIn,
        checkOut: checkOut,
        cancelToken: _cancelToken,
      );
      if (property != null) {
        final priced = await _applyNightlyPricing(id, property, listRow);
        if (isClosed) return;
        emit(PropertyDetailsLoaded(property: priced));
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

  /// Replaces the details payload's nightly price with a calendar-aware one.
  ///
  /// Order of preference:
  /// 1. [listRow] — the exact keys the card the user just tapped was rendered
  ///    from, so the price outside and inside always match.
  /// 2. `/nightly-prices` — the same source the guest calendar renders, for
  ///    entry points that carry no row (host listings, owner profile, trips,
  ///    deep links).
  /// 3. The details payload as-is, when neither source answers.
  Future<PropertyModel> _applyNightlyPricing(
    String id,
    PropertyModel property,
    Map<String, dynamic>? listRow,
  ) async {
    final resolved = _fromListRow(listRow) ?? await _fromCalendar(id);
    if (resolved == null) return property;
    return property.copyWithPricing(
      pricePerNight: resolved.price,
      priceWithoutDiscount: resolved.priceWithoutDiscount,
      discountPercent: resolved.discountPercent,
    );
  }

  ResolvedNightlyPricing? _fromListRow(Map<String, dynamic>? listRow) {
    if (listRow == null) return null;
    final price = nightlyPrice(listRow);
    if (price == null || price <= 0) return null;
    return ResolvedNightlyPricing(
      price: price,
      priceWithoutDiscount: originalNightlyPrice(listRow),
      discountPercent: effectiveDiscountPercent(listRow),
    );
  }

  /// Cheapest upcoming night from the calendar — the same "from" price the
  /// search list advertises. `/nightly-prices` is paged by month with page 1 =
  /// January, so the current month is page `month`; when nothing on that page
  /// is still upcoming (the month is over) the next month is read instead.
  Future<ResolvedNightlyPricing?> _fromCalendar(String id) async {
    try {
      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);

      var page = await _propertyService.getNightlyPrices(id, page: now.month);
      var upcoming = page.items.where((n) => !n.date.isBefore(today)).toList();
      if (upcoming.isEmpty && page.page < page.totalPages) {
        page = await _propertyService.getNightlyPrices(id, page: page.page + 1);
        upcoming = page.items.where((n) => !n.date.isBefore(today)).toList();
      }
      if (upcoming.isEmpty) return null;

      final cheapest = upcoming
          .reduce((a, b) => b.effectivePrice < a.effectivePrice ? b : a);
      if (cheapest.effectivePrice <= 0) return null;
      return ResolvedNightlyPricing(
        price: cheapest.effectivePrice,
        priceWithoutDiscount: cheapest.hasDiscount ? cheapest.price : null,
        discountPercent:
            cheapest.hasDiscount ? (cheapest.discountPercent ?? 0) : 0,
      );
    } catch (_) {
      // Pricing here is a refinement — a failed calendar read must not break
      // the screen, it just leaves the details payload's own price in place.
      return null;
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
