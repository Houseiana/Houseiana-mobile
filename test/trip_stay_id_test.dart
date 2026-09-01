import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/models/trip_model.dart';
import 'package:houseiana_mobile_app/core/utils/stay_ids.dart';

/// A review is addressed by the STAY, not by the booking:
/// `POST /api/hotels/{hotelId}/reviews/create` for a hotel and
/// `POST /api/ratings/property-by-guest` (body `propertyId`) for a property.
/// A past HOTEL trip came back from `GET /users/{id}/user-trips` flagged as a
/// hotel — pill, title, cover photo — with no hotel id under any key this app
/// read, which left the review button on "This hotel is no longer available".
/// These tests pin the id resolution that fixes it.
void main() {
  group('extractHotelId', () {
    test('reads the declared key', () {
      expect(extractHotelId({'hotelId': 'h-1'}), 'h-1');
      expect(extractHotelId({'hotel_id': 'h-2'}), 'h-2');
      expect(extractHotelId({'hotelID': 'h-3'}), 'h-3');
    });

    test('reads a nested hotel object', () {
      expect(extractHotelId({'hotel': {'id': 'h-4', 'name': 'first hotel'}}),
          'h-4');
      expect(extractHotelId({'hotelInfo': {'hotelId': 'h-5'}}), 'h-5');
    });

    test('reads a hotel id nested under a booking wrapper', () {
      expect(extractHotelId({'hotelBooking': {'hotelId': 'h-6'}}), 'h-6');
    });

    test('never mistakes the BOOKING id for the hotel', () {
      // Posting a booking id to /api/hotels/{id}/reviews/create would 404 —
      // or, worse, land on some unrelated hotel.
      expect(extractHotelId({'hotelBookingId': 'hb-1'}), '');
      expect(extractHotelId({'hotelRoomTypeId': 'rt-1'}), '');
      expect(extractHotelId({'hotelRatePlanId': 'rp-1'}), '');
    });

    test('treats empty, null-ish and zero ids as absent', () {
      expect(extractHotelId({'hotelId': null}), '');
      expect(extractHotelId({'hotelId': '   '}), '');
      expect(extractHotelId({'hotelId': 'null'}), '');
      expect(extractHotelId({'hotelId': 0}), '');
    });

    test('accepts a numeric id', () {
      expect(extractHotelId({'hotelId': 42}), '42');
    });

    test('finds nothing in a property row', () {
      expect(
        extractHotelId({
          'id': 'b-1',
          'propertyId': 'p-1',
          'propertyTitle': 'شاليه جديد 3 غرف',
        }),
        '',
      );
    });
  });

  /// The row that produced the bug: flagged HOTEL, titled and photographed
  /// through the property columns, with no hotel id of its own.
  Map<String, dynamic> hotelRowWithoutHotelId() => {
        'id': '2f1c9a55-1f0c-4a2e-9d3a-9f4b3a6d55aa',
        'propertyId': '4d1f8935-2d4d-4a66-bf1c-8be1aab1319a',
        'propertyTitle': 'testing en name',
        'propertyCoverPhoto': 'https://example.com/cover.jpg',
        'checkInDate': '2026-08-27T00:00:00Z',
        'checkOutDate': '2026-08-28T00:00:00Z',
        'status': 'PAST',
        'totalPrice': 3740,
        'currency': 'EGP',
        'bookingType': 'HOTEL',
      };

  group('TripModel.resolvedHotelId', () {
    test('falls back to the property column on a hotel row', () {
      final trip = TripModel.fromJson(hotelRowWithoutHotelId());

      expect(trip.isHotel, isTrue);
      expect(trip.hotelId, isNull, reason: 'the row declared none');
      expect(trip.resolvedHotelId, '4d1f8935-2d4d-4a66-bf1c-8be1aab1319a');
    });

    test('prefers a declared hotel id over the property column', () {
      final trip = TripModel.fromJson({
        ...hotelRowWithoutHotelId(),
        'hotelId': 'h-declared',
      });

      expect(trip.resolvedHotelId, 'h-declared');
    });

    test('stays empty for a property stay', () {
      final trip = TripModel.fromJson({
        'id': 'b-2',
        'propertyId': 'p-2',
        'checkInDate': '2026-06-28T00:00:00Z',
        'checkOutDate': '2026-07-01T00:00:00Z',
        'status': 'PAST',
      });

      expect(trip.isHotel, isFalse);
      expect(trip.resolvedHotelId, '',
          reason: 'a property id must never reach the hotel review endpoint');
      expect(trip.propertyId, 'p-2');
    });
  });

  group('the trip-details route boundary', () {
    test('carries the resolved hotel id into BookingModel', () {
      // The details screen rebuilds a BookingModel straight from this map.
      final trip = TripModel.fromJson(hotelRowWithoutHotelId());
      final booking = BookingModel.fromJson(trip.toJson());

      expect(booking.isHotel, isTrue);
      expect(booking.resolvedHotelId, '4d1f8935-2d4d-4a66-bf1c-8be1aab1319a');
    });

    test('a property trip crosses it without gaining a hotel id', () {
      final trip = TripModel.fromJson({
        'id': 'b-3',
        'propertyId': 'p-3',
        'checkInDate': '2026-05-23T00:00:00Z',
        'checkOutDate': '2026-06-01T00:00:00Z',
        'status': 'PAST',
      });
      final booking = BookingModel.fromJson(trip.toJson());

      expect(booking.isHotel, isFalse);
      expect(booking.resolvedHotelId, '');
      expect(booking.propertyId, 'p-3');
    });
  });
}
