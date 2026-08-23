import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_booking.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_details.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_quote.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_review.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';

/// The payloads below are VERBATIM from a live probe of the staging API on
/// 2026-08-23 — not invented fixtures. If the backend shape changes, these are
/// the tests that should fail first.
void main() {
  group('HotelSummary', () {
    Map<String, dynamic> row({int nights = 0}) => {
          'hotelId': '4d1f8935-2d4d-4a66-bf1c-8be1aab1319a',
          'name': 'first hotel',
          'starRating': 5,
          'coverPhoto': 'https://example.com/cover.jpg',
          'cityName': 'Hammam',
          'countryName': 'Egypt',
          'reviewScore': null,
          'reviewCount': 0,
          'isFavorite': false,
          'isGuestFavorite': true,
          'price': 1500.00,
          'currencyCode': 'EGP',
          'nights': nights,
          'availableRoomTypes': 2,
          'amenities': [
            {'id': 1, 'name': 'WiFi'},
            {'id': 2, 'name': 'Kitchen'},
          ],
        };

    test('parses the verified search row', () {
      final hotel = HotelSummary.fromJson(row());

      expect(hotel.hotelId, '4d1f8935-2d4d-4a66-bf1c-8be1aab1319a');
      expect(hotel.name, 'first hotel');
      expect(hotel.starRating, 5);
      expect(hotel.cityName, 'Hammam');
      expect(hotel.price, 1500);
      expect(hotel.currencyCode, 'EGP');
      expect(hotel.availableRoomTypes, 2);
      expect(hotel.amenities.map((a) => a.name), ['WiFi', 'Kitchen']);
      expect(hotel.location, 'Hammam, Egypt');
    });

    test('nights == 0 means the price is a nightly rate, not a stay total', () {
      expect(HotelSummary.fromJson(row()).isStayTotal, isFalse);
      expect(HotelSummary.fromJson(row(nights: 3)).isStayTotal, isTrue);
    });

    test('separates the wishlist heart from the guest-favourite badge', () {
      final hotel = HotelSummary.fromJson(row());
      // The live row really is isFavorite:false + isGuestFavorite:true. Seeding
      // a heart from the badge would light up a hotel the user never saved.
      expect(hotel.isFavorite, isFalse);
      expect(hotel.isGuestFavorite, isTrue);
    });

    test('hides the rating until there is at least one review', () {
      expect(HotelSummary.fromJson(row()).hasRating, isFalse);
      final rated = HotelSummary.fromJson(
        row()..addAll({'reviewScore': 4.5, 'reviewCount': 12}),
      );
      expect(rated.hasRating, isTrue);
      expect(rated.reviewScore, 4.5);
    });

    test('round-trips through toJson so a page survives the cache', () {
      final original = HotelSummary.fromJson(row(nights: 3));
      final restored = HotelSummary.fromJson(original.toJson());

      expect(restored.hotelId, original.hotelId);
      expect(restored.price, original.price);
      expect(restored.nights, original.nights);
      expect(restored.currencyCode, original.currencyCode);
      expect(restored.isGuestFavorite, original.isGuestFavorite);
      expect(restored.amenities.length, original.amenities.length);
    });

    test('tolerates money and counts arriving as strings', () {
      final hotel = HotelSummary.fromJson({
        'hotelId': 'x',
        'name': 'n',
        'price': '1500.5',
        'starRating': '4',
        'nights': '2',
      });
      expect(hotel.price, 1500.5);
      expect(hotel.starRating, 4);
      expect(hotel.nights, 2);
      // Absent currency must not become an empty string — Money.format would
      // then silently drop the currency from every price on the card.
      expect(hotel.currencyCode, 'EGP');
    });
  });

  group('HotelGroup', () {
    test('a region group carries regionId and can be drilled into', () {
      final group = HotelGroup.fromJson({
        'regionId': 1,
        'name': 'North Coast',
        'totalCount': 1,
        'hotels': [
          {'hotelId': 'a', 'name': 'first hotel'},
        ],
      });
      expect(group.regionId, 1);
      expect(group.canDrillDown, isTrue);
      expect(group.hotels.single.hotelId, 'a');
    });

    test('a city group omits regionId entirely and cannot be drilled into', () {
      // This is the real shape once the search is already scoped by regionId.
      final group = HotelGroup.fromJson({
        'name': 'Hammam',
        'totalCount': 1,
        'hotels': const [],
      });
      expect(group.regionId, isNull);
      expect(group.canDrillDown, isFalse);
    });

    test('drops rows with no hotelId rather than rendering blank cards', () {
      final group = HotelGroup.fromJson({
        'name': 'x',
        'hotels': [
          {'hotelId': 'a', 'name': 'ok'},
          {'name': 'no id'},
        ],
      });
      expect(group.hotels.length, 1);
    });
  });

  group('HotelSearchPage', () {
    test('derives hasMore from the page counters (there is no hasMore flag)', () {
      const page = HotelSearchPage(page: 1, totalPages: 3);
      expect(page.hasMore, isTrue);
      const last = HotelSearchPage(page: 3, totalPages: 3);
      expect(last.hasMore, isFalse);
      const none = HotelSearchPage(page: 1, totalPages: 0);
      expect(none.hasMore, isFalse);
    });
  });

  group('HotelSearchParams', () {
    test('sends camelCase checkIn/checkOut, unlike property search', () {
      const params = HotelSearchParams(
        checkIn: '2026-09-10',
        checkOut: '2026-09-13',
        adults: 2,
        rooms: 1,
        regionId: 1,
        page: 2,
        limit: 20,
      );
      final query = params.toQueryParams();
      expect(query['checkIn'], '2026-09-10');
      expect(query['checkOut'], '2026-09-13');
      expect(query.containsKey('checkin'), isFalse);
      expect(query['regionId'], 1);
      expect(query['page'], 2);
    });

    test('truncates an ISO timestamp to a plain calendar day', () {
      const params = HotelSearchParams(checkIn: '2026-09-10T14:00:00.000Z');
      expect(params.toQueryParams()['checkIn'], '2026-09-10');
    });

    test('omits empty and zero filters instead of sending them', () {
      const params = HotelSearchParams(userId: '', adults: 0, rooms: 0);
      final query = params.toQueryParams();
      expect(query.containsKey('userId'), isFalse);
      expect(query.containsKey('adults'), isFalse);
      expect(query.containsKey('rooms'), isFalse);
    });

    test('copyWith preserves every filter while paging', () {
      const params = HotelSearchParams(
        checkIn: '2026-09-10',
        checkOut: '2026-09-13',
        adults: 2,
        children: 1,
        rooms: 2,
        regionId: 10,
      );
      final next = params.copyWith(page: 3);
      expect(next.page, 3);
      expect(next.checkIn, '2026-09-10');
      expect(next.adults, 2);
      expect(next.children, 1);
      expect(next.rooms, 2);
      expect(next.regionId, 10);
    });
  });

  group('HotelDetails', () {
    // Trimmed from the verified /api/hotels/{id}/details response.
    final json = <String, dynamic>{
      'hotelId': '4d1f8935-2d4d-4a66-bf1c-8be1aab1319a',
      'name': 'first hotel',
      'description': 'first hotel in our websits ',
      'starRating': 5,
      'coverPhoto': 'https://example.com/cover.jpg',
      'photos': [
        {'id': 'p1', 'url': 'https://example.com/1.jpeg'},
      ],
      'cityName': 'Hammam',
      'countryName': 'Egypt',
      'streetAddress': 'North coast ',
      'latitude': 30.8268055,
      'longitude': 29.1893279,
      'checkInTime': '12:00 PM',
      'checkOutTime': '10:00 AM',
      'amenities': [
        {'id': 1, 'name': 'WiFi'},
      ],
      'reviewScore': null,
      'reviewCount': 0,
      'nights': 2,
      'roomTypes': [
        {
          'id': '9ff04468-19a5-46a1-87f8-12867870fd7e',
          'name': 'Standard Room',
          'roomCategory': 'Standard',
          'viewType': 'Pool View',
          'sizeSqm': 50,
          'baseOccupancy': 2,
          'coverPhoto': 'https://example.com/std.png',
          'photos': const [],
          'beds': [
            {'bedType': 'Double Bed', 'count': 1},
          ],
          'amenities': const [],
          'availableUnits': 15,
          'ratePlans': [
            {
              'id': 'dab0a9f8-8551-46d0-9539-e1c86783f7b6',
              'boardBasis': 'Room Only',
              'basePrice': 1500,
              'currencyCode': 'EGP',
              'cancellationPolicyType': 'FLEXIBLE',
              'freeCancellationHours': 24,
              'freeCancellationDays': 0,
              'stayPrice': 3000,
              'serviceFee': 300,
            },
          ],
        },
        {
          'id': '8e8eafc5-6ec4-43a0-a926-9d301cb8c852',
          'name': 'Deluxe Room',
          'baseOccupancy': 4,
          'availableUnits': 10,
          'ratePlans': [
            {
              'id': '7274c5d3-2e35-4c26-a2db-e289af8a49d9',
              'boardBasis': 'Bed & Breakfast',
              'basePrice': 1900,
              // The SAME hotel really does quote a second currency here.
              'currencyCode': 'QAR',
              'cancellationPolicyType': 'FLEXIBLE',
              'freeCancellationHours': 48,
              'stayPrice': 3800,
              'serviceFee': 380,
            },
          ],
        },
      ],
    };

    test('parses the whole verified tree', () {
      final hotel = HotelDetails.fromJson(json);
      expect(hotel.name, 'first hotel');
      expect(hotel.nights, 2);
      expect(hotel.roomTypes.length, 2);
      expect(hotel.roomTypes.first.ratePlans.single.stayPrice, 3000);
      expect(hotel.roomTypes.first.beds.single.bedType, 'Double Bed');
      expect(hotel.hasCoordinates, isTrue);
      expect(hotel.hasBookableRooms, isTrue);
    });

    test('detects the mixed-currency hotel so no bogus "from" price is shown', () {
      expect(HotelDetails.fromJson(json).hasMixedCurrencies, isTrue);
    });

    test('gallery puts the cover first and de-duplicates', () {
      final hotel = HotelDetails.fromJson({
        ...json,
        'photos': [
          {'id': 'a', 'url': 'https://example.com/cover.jpg'},
          {'id': 'b', 'url': 'https://example.com/other.jpg'},
        ],
      });
      expect(hotel.galleryUrls, [
        'https://example.com/cover.jpg',
        'https://example.com/other.jpg',
      ]);
    });

    test('a DATELESS response reports unknown stock, not sold out', () {
      // Verified live: /api/hotels/{id}/details WITHOUT dates answers
      // availableUnits:null for every room type. Mapping that to 0 branded
      // every room "Sold out" on every visit, since no entry point sends dates.
      final room = HotelRoomType.fromJson({
        'id': 'x',
        'name': 'Standard Room',
        'availableUnits': null,
        'ratePlans': [
          {'id': 'rp', 'basePrice': 1500},
        ],
      });
      expect(room.availableUnits, isNull);
      expect(room.hasKnownAvailability, isFalse);
      expect(room.isSoldOut, isFalse);
      // The stepper still has to move, so it falls back to a sane cap.
      expect(room.maxSelectableRooms, greaterThan(0));
    });

    test('a stock the backend really reported as zero IS sold out', () {
      final room = HotelRoomType.fromJson({
        'id': 'x',
        'name': 'x',
        'availableUnits': 0,
        'ratePlans': [
          {'id': 'rp'},
        ],
      });
      expect(room.hasKnownAvailability, isTrue);
      expect(room.isSoldOut, isTrue);
      expect(room.maxSelectableRooms, 0);
    });

    test('a sold-out room type is one with no units or no rate plans', () {
      final soldOut = HotelRoomType.fromJson({
        'id': 'x',
        'name': 'x',
        'availableUnits': 0,
        'ratePlans': const [],
      });
      expect(soldOut.isSoldOut, isTrue);
      expect(HotelDetails.fromJson(json).roomTypes.first.isSoldOut, isFalse);
    });

    test('free cancellation counts BACK from check-in, not forward from booking', () {
      final plan = HotelDetails.fromJson(json).roomTypes.first.ratePlans.single;
      expect(plan.hasFreeCancellation, isTrue);
      final checkIn = DateTime(2026, 9, 10, 14);
      expect(
        plan.freeCancellationDeadline(checkIn),
        DateTime(2026, 9, 9, 14),
      );
      // Without a check-in date there is no concrete deadline to promise.
      expect(plan.freeCancellationDeadline(null), isNull);
    });

    test('a non-refundable plan reports no free-cancellation window', () {
      final plan = HotelRatePlan.fromJson({
        'id': 'x',
        'freeCancellationHours': 0,
        'freeCancellationDays': 0,
      });
      expect(plan.hasFreeCancellation, isFalse);
      expect(plan.freeCancellationDeadline(DateTime(2026, 9, 10)), isNull);
    });

    test('falls back to the nightly base when the call carried no dates', () {
      final plan = HotelRatePlan.fromJson({
        'id': 'x',
        'basePrice': 1500,
        'stayPrice': 0,
      });
      expect(plan.effectiveStayPrice, 1500);
    });
  });

  group('HotelQuote', () {
    test('parses the verified quote response', () {
      final quote = HotelQuote.fromJson({
        'hotelId': '4d1f8935-2d4d-4a66-bf1c-8be1aab1319a',
        'checkIn': '2026-09-10',
        'checkOut': '2026-09-12',
        'nights': 2,
        'lines': [
          {
            'ratePlanId': 'dab0a9f8-8551-46d0-9539-e1c86783f7b6',
            'roomTypeId': '9ff04468-19a5-46a1-87f8-12867870fd7e',
            'roomTypeName': 'Standard Room',
            'boardBasis': 'Room Only',
            'rooms': 2,
            'stayPricePerRoom': 3000.00,
            'subtotal': 6000.00,
          },
        ],
        'roomsSubtotal': 6000.00,
        'serviceFee': 600.00,
        'total': 6600.00,
        'currencyCode': 'EGP',
      });

      expect(quote.nights, 2);
      expect(quote.lines.single.roomTypeName, 'Standard Room');
      expect(quote.roomsSubtotal, 6000);
      expect(quote.serviceFee, 600);
      // Unlike the property /availability contract, the hotel subtotal is NOT
      // pre-discounted: total is a plain subtotal + fee.
      expect(quote.total, quote.roomsSubtotal + quote.serviceFee);
      expect(quote.totalRooms, 2);
    });

    test('the signature ignores selection order so it is stable', () {
      const a = HotelSelection(ratePlanId: 'a', rooms: 1);
      const b = HotelSelection(ratePlanId: 'b', rooms: 2);
      expect(
        HotelQuote.signatureOf('2026-09-10', '2026-09-12', [a, b]),
        HotelQuote.signatureOf('2026-09-10', '2026-09-12', [b, a]),
      );
    });

    test('the signature changes with rooms and with dates', () {
      const one = HotelSelection(ratePlanId: 'a', rooms: 1);
      const two = HotelSelection(ratePlanId: 'a', rooms: 2);
      expect(
        HotelQuote.signatureOf('2026-09-10', '2026-09-12', [one]),
        isNot(HotelQuote.signatureOf('2026-09-10', '2026-09-12', [two])),
      );
      expect(
        HotelQuote.signatureOf('2026-09-10', '2026-09-12', [one]),
        isNot(HotelQuote.signatureOf('2026-09-11', '2026-09-12', [one])),
      );
    });
  });

  group('HotelBookingRequest', () {
    HotelLeadGuest guest([String first = 'Ali']) =>
        HotelLeadGuest(firstName: first, lastName: 'Hassan', phone: '0100000000');

    test('rejects a selection with fewer lead guests than rooms', () {
      // The backend rejects this with "Every selection must provide one lead
      // guest per room" — catching it here keeps the request off the wire.
      final selection = HotelBookingSelection(
        ratePlanId: 'rp',
        rooms: 2,
        leadGuests: [guest()],
      );
      expect(selection.isValid, isFalse);
    });

    test('rejects a lead guest with a blank field', () {
      final selection = HotelBookingSelection(
        ratePlanId: 'rp',
        rooms: 1,
        leadGuests: const [HotelLeadGuest(firstName: 'Ali', lastName: '  ')],
      );
      expect(selection.isValid, isFalse);
    });

    test('accepts exactly one complete lead guest per room', () {
      final selection = HotelBookingSelection(
        ratePlanId: 'rp',
        rooms: 2,
        leadGuests: [guest('Ali'), guest('Mona')],
      );
      expect(selection.isValid, isTrue);

      final request = HotelBookingRequest(
        guestId: 'user_1',
        checkIn: '2026-09-10',
        checkOut: '2026-09-12',
        selections: [selection],
      );
      expect(request.isValid, isTrue);
      expect(request.totalRooms, 2);

      final body = request.toJson();
      expect(body['guestId'], 'user_1');
      expect(body['checkIn'], '2026-09-10');
      expect((body['selections'] as List).single['leadGuests'], hasLength(2));
    });

    test('an empty selection list is never a valid booking', () {
      const request = HotelBookingRequest(
        guestId: 'user_1',
        checkIn: '2026-09-10',
        checkOut: '2026-09-12',
      );
      expect(request.isValid, isFalse);
    });

    test('trims typed whitespace out of the payload', () {
      const g = HotelLeadGuest(
        firstName: ' Ali ',
        lastName: ' Hassan ',
        phone: ' 0100 ',
      );
      expect(g.toJson(), {
        'firstName': 'Ali',
        'lastName': 'Hassan',
        'phone': '0100',
      });
    });
  });

  group('HotelBookingResult', () {
    test('reads the booking id through every plausible alias', () {
      expect(HotelBookingResult.fromJson({'bookingId': 'a'}).bookingId, 'a');
      expect(HotelBookingResult.fromJson({'id': 'b'}).bookingId, 'b');
      expect(HotelBookingResult.fromJson({'bookingCode': 'c'}).bookingId, 'c');
    });

    test('never throws on an unknown response shape', () {
      // The success shape is unverified, so a missing key must degrade rather
      // than blow up after the booking has already been taken.
      final result = HotelBookingResult.fromJson(const {});
      expect(result.hasBookingId, isFalse);
      expect(result.total, isNull);
      expect(result.currencyCode, isNull);
    });

    test('keeps the untouched payload for whatever the screen needs', () {
      final result = HotelBookingResult.fromJson({'id': 'a', 'extra': 42});
      expect(result.raw['extra'], 42);
    });
  });

  group('HotelReview', () {
    test('parses an empty row without throwing', () {
      // The reviews endpoint was only ever probed against an EMPTY dataset, so
      // the row shape is unverified and every field has to be optional.
      final review = HotelReview.fromJson(const {});
      expect(review.id, '');
      expect(review.rating, 0);
      expect(review.hasComment, isFalse);
    });

    test('reads the guest name from a nested guest object', () {
      final review = HotelReview.fromJson({
        'id': 'r1',
        'ratingValue': 5,
        'comment': 'Great stay',
        'guest': {'firstName': 'Ali', 'lastName': 'Hassan'},
        'createdAt': '2026-08-10T00:00:00Z',
      });
      expect(review.guestName, 'Ali Hassan');
      expect(review.rating, 5);
      expect(review.createdAt, isNotNull);
    });
  });

  group('HotelReviewDraft', () {
    const complete = HotelReviewDraft(
      ratingValue: 5,
      comment: 'Great',
      cleanliness: 5,
      accuracy: 5,
      checkIn: 5,
      communication: 5,
      location: 5,
      value: 5,
    );

    test('is incomplete until every category is scored', () {
      expect(complete.isComplete, isTrue);
      expect(complete.copyWith(location: 0).isComplete, isFalse);
      expect(complete.copyWith(ratingValue: 0).isComplete, isFalse);
      expect(complete.copyWith(comment: '   ').isComplete, isFalse);
    });

    test('withAllCategories fills all six at once', () {
      final draft = const HotelReviewDraft(ratingValue: 4, comment: 'ok')
          .withAllCategories(4);
      expect(draft.categoryScores, [4, 4, 4, 4, 4, 4]);
      expect(draft.isComplete, isTrue);
    });

    test('sends guestId (not userId) and an int ratingValue', () {
      final body = complete.toJson('user_1');
      expect(body['guestId'], 'user_1');
      expect(body.containsKey('userId'), isFalse);
      expect(body['ratingValue'], isA<int>());
      expect(body.containsKey('bookingId'), isFalse);
    });
  });
}
