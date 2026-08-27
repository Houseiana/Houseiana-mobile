import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/models/trip_model.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';

/// Guards the two things the booking-confirmation card got wrong on a real
/// reservation:
///
/// * the reference read `#F2619C66` — the last eight characters of the internal
///   booking id, upper-cased on the device. It looked like a reservation number
///   the guest could quote to support, and matched nothing in the backend.
/// * the total read `دولار أمريكي $3300` for a stay priced in EGP: the screen
///   prefixed a hard-coded `$` on top of a `totalPaidValue` string that already
///   carried its own currency word.
void main() {
  Map<String, dynamic> bookingJson(Map<String, dynamic> extra) => {
        'id': 'b7c1a2f4-9d3e-4c88-9f10-0a1bF2619C66',
        'checkInDate': '2026-08-24T00:00:00.000Z',
        'checkOutDate': '2026-08-25T00:00:00.000Z',
        'guests': 8,
        'totalPrice': 3300,
        'status': 'CONFIRMED',
        ...extra,
      };

  group('BookingModel.reservationReference', () {
    test('uses the backend bookingCode verbatim when there is one', () {
      final booking =
          BookingModel.fromJson(bookingJson({'bookingCode': 'HSA-2026-000812'}));

      expect(booking.reservationReference, 'HSA-2026-000812');
    });

    test('falls back to confirmationCode before touching the id', () {
      final booking = BookingModel.fromJson(
          bookingJson({'confirmationCode': 'CNF-99213'}));

      expect(booking.reservationReference, 'CNF-99213');
    });

    test('prefers bookingCode over confirmationCode', () {
      final booking = BookingModel.fromJson(bookingJson({
        'bookingCode': 'HSA-2026-000812',
        'confirmationCode': 'CNF-99213',
      }));

      expect(booking.reservationReference, 'HSA-2026-000812');
    });

    test(
        'with no backend code it shows the whole booking id, never an '
        'id-derived shortening', () {
      final booking = BookingModel.fromJson(bookingJson({}));

      expect(booking.reservationReference,
          '#b7c1a2f4-9d3e-4c88-9f10-0a1bF2619C66');
      // The shape that shipped: the last 8 characters, upper-cased.
      expect(booking.reservationReference, isNot('#F2619C66'));
      expect(booking.reservationReference, isNot(booking.bookingRefShort));
    });

    test('is empty (row hidden) when the booking has no identifier at all', () {
      final booking = BookingModel.fromJson(bookingJson({'id': ''}));

      expect(booking.reservationReference, isEmpty);
    });
  });

  group('paid total keeps the booking currency', () {
    test('an EGP booking is quoted in EGP', () {
      final booking = BookingModel.fromJson(bookingJson({'currency': 'EGP'}));

      expect(Money.format(booking.totalPrice, booking.currencyLabel),
          '3,300 EGP');
    });

    test('a currency-less booking defaults to EGP, not USD', () {
      final booking = BookingModel.fromJson(bookingJson({}));

      expect(booking.currencyLabel, 'EGP');
      expect(Money.format(booking.totalPrice, booking.currencyLabel),
          isNot(contains(r'$')));
    });

    test('a genuinely non-EGP booking is quoted in its own currency', () {
      final booking = BookingModel.fromJson(bookingJson({'currency': 'USD'}));

      expect(Money.format(booking.totalPrice, booking.currencyLabel),
          '3,300 USD');
    });
  });

  test(
      'toJson carries the reference and the currency to the trip-details route',
      () {
    // Trip details rebuilds a BookingModel straight from this map and never
    // re-fetches, so anything dropped here changes what the same booking shows
    // one screen later.
    final booking = BookingModel.fromJson(bookingJson({
      'currency': 'EGP',
      'confirmationCode': 'CNF-99213',
      'bookingCode': 'HSA-2026-000812',
    }));

    final restored = BookingModel.fromJson(booking.toJson());

    expect(restored.reservationReference, 'HSA-2026-000812');
    expect(restored.currencyLabel, 'EGP');
    expect(restored.confirmationCode, 'CNF-99213');
  });

  group('TripModel.bookingIdFormatted', () {
    Map<String, dynamic> tripJson(Map<String, dynamic> extra) => {
          'id': 'b7c1a2f4-9d3e-4c88-9f10-0a1bF2619C66',
          'checkIn': '2026-08-24T00:00:00.000Z',
          'checkOut': '2026-08-25T00:00:00.000Z',
          'totalPrice': 3300,
          ...extra,
        };

    test('no longer truncates a real code into a #HOU- stub', () {
      final trip = TripModel.fromJson(tripJson({
        'confirmationCode': 'CNF-99213',
      }));

      expect(trip.bookingIdFormatted, 'CNF-99213');
      expect(trip.bookingIdFormatted, isNot(startsWith('#HOU-')));
    });

    test('matches the reference the booking screens show', () {
      final trip = TripModel.fromJson(tripJson({'bookingCode': 'HSA-2026-1'}));
      final booking =
          BookingModel.fromJson(bookingJson({'bookingCode': 'HSA-2026-1'}));

      expect(trip.bookingIdFormatted, booking.reservationReference);
    });

    test('falls back to the full booking id', () {
      final trip = TripModel.fromJson(tripJson({}));

      expect(trip.bookingIdFormatted, '#b7c1a2f4-9d3e-4c88-9f10-0a1bF2619C66');
    });
  });

  group('translations no longer hard-code a currency on the paid total', () {
    Map<String, dynamic> load(String locale) => (jsonDecode(
              File('lib/i18n/translations/$locale.json').readAsStringSync(),
            ) as Map<String, dynamic>)['booking']
        as Map<String, dynamic>;

    for (final locale in ['en', 'ar']) {
      test('$locale.json', () {
        final booking = load(locale);

        // The screen now renders Money.format(...), which already includes the
        // currency — a wrapper string would print it twice.
        expect(booking.containsKey('totalPaidValue'), isFalse);
        expect(booking['bookingSummaryTemplate'], contains('{total}'));
        expect(booking['bookingSummaryTemplate'], isNot(contains('EGP')));
        expect(booking['bookingSummaryTemplate'], isNot(contains('دولار')));
      });
    }
  });
}
