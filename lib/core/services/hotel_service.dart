import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exception_model.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_booking.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_details.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_quote.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_review.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';
import 'package:houseiana_mobile_app/core/models/nearby_place.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/core/network/api/status_code.dart';

/// The hotels endpoints are not deployed on the backend this build talks to.
///
/// Distinct from a plain [ServerException] so screens can render a "coming
/// soon" state instead of a retryable error — retrying cannot help, the feature
/// simply is not there. Its message is a translation key, which the UI wraps in
/// `context.tr` like every other cubit message in this app.
class HotelsUnavailableException extends ServerException {
  const HotelsUnavailableException()
      : super(
          exceptionModel: const ExceptionModel(
            statusCode: StatusCode.notFound,
            message: 'hotels.unavailableHere',
          ),
        );
}

/// Guest-facing hotels API.
///
/// One thing makes this service unlike the others: **its errors arrive as HTTP
/// 200.** Every endpoint answers 200 even when it failed, carrying
/// `success:false` plus a reason. The status code is useless here; [_data]
/// treats the flag as the contract.
///
/// Note the endpoints are deployed to STAGING only — a build pointed at
/// production 404s on every hotel path, which is what [available] exists for.
class HotelService {
  final ApiConsumer _api;

  HotelService(this._api);

  /// Process-wide availability latch.
  ///
  /// Flips off the first time `/api/hotel-search` answers 404 — the signature of
  /// "this backend has no hotels deployed" (every production build, today).
  /// Never persisted: a backend deploy fixes it on the next launch.
  ///
  /// It exists to stop every visit to the Hotels segment paying a full timeout
  /// against a backend that will never answer. It does NOT hide the segment —
  /// see the home screen's toggle for why.
  static final ValueNotifier<bool> available = ValueNotifier<bool>(true);

  /// Re-arms the latch so the next call hits the network again.
  ///
  /// A 404 means "this backend has no hotels deployed", which is normally true
  /// for the whole session — but it is also true right up until someone
  /// deploys them, and a guest who taps Retry deserves a real attempt rather
  /// than a cached verdict. Never call this on a loop; it is a user gesture.
  static void retryAvailability() => available.value = true;

  /// Every hotel endpoint takes a plain calendar day. Never `toIso8601String()`
  /// — an ISO timestamp here is the same class of bug as the `dd-MM-yyyy` dates
  /// that produced year 0001 on the host calendar.
  static String apiDate(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Wraps every call: short-circuits when hotels are known to be unavailable,
  /// and normalizes errors.
  ///
  /// Clause ORDER is load-bearing. [RequestCancelledException] extends
  /// [ServerException], so it has to be caught first or a cancelled request
  /// would be reported as a failure.
  Future<T> _guard<T>(
    Future<T> Function() run, {
    bool latchOn404 = false,
  }) async {
    if (!available.value) throw const HotelsUnavailableException();
    try {
      return await run();
    } on RequestCancelledException {
      rethrow;
    } on HotelsUnavailableException {
      rethrow;
    } on ServerException catch (e) {
      if (latchOn404 &&
          e.exceptionModel.statusCode == StatusCode.notFound) {
        available.value = false;
        if (kDebugMode) {
          debugPrint('[Hotels] disabled for this session — hotel-search 404 on '
              '${EndPoints.baseUrl}');
        }
        throw const HotelsUnavailableException();
      }
      rethrow;
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// Unwraps the `{ success, message, data }` envelope.
  ///
  /// Hotels answer HTTP 200 even on failure, with `success:false` and the real
  /// reason in `message` ("Rate plan not found.", "User not found.", "Every
  /// selection must provide one lead guest per room."). Surfacing that reason
  /// verbatim is deliberate — the wizard-error work established that a backend
  /// reason beats a generic localized string.
  dynamic _data(dynamic response) {
    if (response is! Map) throw ServerException.msg('hotels.loadFailed');
    final map = Map<String, dynamic>.from(response);
    if (map['success'] == false) {
      final reason = (map['message'] ?? '').toString().trim();
      throw ServerException.msg(reason.isEmpty ? 'hotels.loadFailed' : reason);
    }
    return map['data'];
  }

  /// GET /api/hotel-search — grouped hotel results.
  ///
  /// The ONLY call that can flip the availability latch: a 404 here means the
  /// feature is not deployed, whereas a 404 on a details/quote path just means
  /// that particular hotel or rate plan is gone.
  Future<HotelSearchPage> searchHotels(
    HotelSearchParams params, {
    CancelToken? cancelToken,
  }) {
    return _guard(
      () async {
        final query = params.toQueryParams();
        final response = await _api.get(
          EndPoints.hotelSearch,
          queryParameters: query,
          cancelToken: cancelToken,
        );
        final data = _data(response);

        // Explicit key path only. The "first list found in the payload"
        // heuristic that property search used to run is documented there as the
        // cause of a silent empty-results bug — and here it would happily match
        // the GROUP objects and hand back nonsense.
        final rawGroups = data is Map ? data['hotels'] : null;
        final groups = (rawGroups is List ? rawGroups : const [])
            .whereType<Map>()
            .map((e) => HotelGroup.fromJson(Map<String, dynamic>.from(e)))
            .where((g) => g.name.trim().isNotEmpty)
            .toList();

        final pagination = response is Map ? response['pagination'] : null;
        final page = HotelSearchPage(
          groups: groups,
          totalGroups: data is Map
              ? asHotelInt(data['totalGroups'], groups.length)
              : groups.length,
          page: pagination is Map
              ? asHotelInt(pagination['page'], params.page)
              : params.page,
          limit: pagination is Map
              ? asHotelInt(pagination['limit'], params.limit)
              : params.limit,
          total: pagination is Map ? asHotelInt(pagination['total']) : 0,
          totalPages: pagination is Map
              ? asHotelInt(pagination['totalPages'])
              : (groups.isEmpty ? 0 : 1),
        );

        if (kDebugMode) {
          debugPrint('[HotelSearch] $query → groups=${groups.length} '
              'hotels=${page.flatHotels.length} total=${page.total} '
              'pages=${page.totalPages}');
        }
        return page;
      },
      latchOn404: true,
    );
  }

  /// GET /api/hotels/{id}/details — the hotel plus its room types and rate plans.
  ///
  /// Passing both dates is what makes the backend fill `nights`, `stayPrice` and
  /// `serviceFee`; without them only `basePrice` is meaningful.
  Future<HotelDetails> getHotelDetails(
    String hotelId, {
    String? checkIn,
    String? checkOut,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final inDate = HotelSearchParams.dateOnly(checkIn);
      final outDate = HotelSearchParams.dateOnly(checkOut);
      final response = await _api.get(
        EndPoints.hotelDetails(hotelId),
        queryParameters: {
          if (inDate != null) 'checkIn': inDate,
          if (outDate != null) 'checkOut': outDate,
        },
        cancelToken: cancelToken,
      );
      final data = _data(response);
      if (data is! Map) throw ServerException.msg('hotels.hotelNotFound');
      return HotelDetails.fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// POST /api/hotel-quote — priced total for a set of rate-plan selections.
  ///
  /// Needs no authentication (verified anonymously), but still goes through the
  /// auth interceptor, which simply omits the header when there is no token.
  ///
  /// Every selection carries the occupancy of ONE room, and the endpoint prices
  /// it: children are charged through the hotel's age bands and come back as
  /// `childrenTotalPerRoom`. [HotelSelection] derives `children` from
  /// `childrenAges` so the mismatch the backend refuses cannot be built.
  Future<HotelQuote> getQuote({
    required String checkIn,
    required String checkOut,
    required List<HotelSelection> selections,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _api.post(
        EndPoints.hotelQuote,
        body: {
          'checkIn': HotelSearchParams.dateOnly(checkIn),
          'checkOut': HotelSearchParams.dateOnly(checkOut),
          'selections': [for (final s in selections) s.toJson()],
        },
        cancelToken: cancelToken,
      );
      final data = _data(response);
      if (data is! Map) throw ServerException.msg('hotels.quoteFailed');
      return HotelQuote.fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// POST /api/hotel-bookings/create.
  ///
  /// [HotelBookingRequest.isValid] already enforces the backend's one-lead-guest-
  /// per-room rule, so an invalid request never reaches the wire.
  Future<HotelBookingResult> createBooking(HotelBookingRequest request) {
    return _guard(() async {
      final response = await _api.post(
        EndPoints.createHotelBooking,
        body: request.toJson(),
      );
      final data = _data(response);
      if (data is Map) {
        return HotelBookingResult.fromJson(Map<String, dynamic>.from(data));
      }
      // `success:true` with no payload still means the booking was taken; the
      // trips list is the source of truth for it either way.
      return const HotelBookingResult();
    });
  }

  /// GET /api/hotels/{hotelId}/reviews — `data` is an ARRAY here, not an object.
  Future<List<HotelReview>> getReviews(
    String hotelId, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _api.get(
        EndPoints.hotelReviews(hotelId),
        queryParameters: {'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
      final data = _data(response);
      if (data is! List) return const <HotelReview>[];
      return data
          .whereType<Map>()
          .map((e) => HotelReview.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  /// POST /api/hotels/{hotelId}/reviews/create.
  Future<void> createReview(
    String hotelId,
    HotelReviewDraft draft, {
    required String guestId,
  }) {
    return _guard(() async {
      final response = await _api.post(
        EndPoints.createHotelReview(hotelId),
        body: draft.toJson(guestId),
      );
      _data(response);
    });
  }

  /// GET /api/hotels/{hotelId}/nearby-places?categoryId={id} — `data` is an
  /// ARRAY, like [getReviews].
  ///
  /// [categoryId] is required in practice: without it the endpoint answers 404
  /// "Category not found." even though Swagger marks it optional. The category
  /// ids come from `/api/Lookups/NearbyCategories`, which properties and hotels
  /// share — see `PropertyService.getNearbyCategories`.
  ///
  /// These rows arrive fully SERVER-LOCALIZED, `priceLevel` and `timeOfDay`
  /// included, so those two are display text rather than enums here.
  /// [NearbyPlace] parses leniently and keeps the raw string for exactly this
  /// reason.
  Future<List<NearbyPlace>> getNearbyPlaces(
    String hotelId, {
    required int categoryId,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _api.get(
        EndPoints.hotelNearbyPlaces(hotelId),
        queryParameters: {'categoryId': categoryId},
        cancelToken: cancelToken,
      );
      final data = _data(response);
      if (data is! List) return const <NearbyPlace>[];
      return NearbyPlace.listFrom(data);
    });
  }

  /// POST /api/hotels/{hotelId}/favorite — toggles, and `data` is the resulting
  /// boolean state (not a success flag).
  Future<bool> toggleFavorite({
    required String hotelId,
    required String userId,
  }) {
    return _guard(() async {
      final response = await _api.post(
        EndPoints.hotelFavorite(hotelId),
        body: {'userId': userId},
      );
      return _data(response) == true;
    });
  }
}
