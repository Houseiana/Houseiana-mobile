import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/models/nightly_price_model.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/nightly_prices_state.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';

void main() {
  group('Money.format', () {
    test('puts the amount first and the currency after it, like the web', () {
      expect(Money.format(6300, 'EGP'), '6,300 EGP');
    });

    test('groups thousands', () {
      expect(Money.format(21000, 'EGP'), '21,000 EGP');
      expect(Money.format(1234567, 'EGP'), '1,234,567 EGP');
    });

    test('drops decimals on whole amounts and trims trailing zeros', () {
      expect(Money.format(3050, 'EGP'), '3,050 EGP');
      expect(Money.format(3050.0, 'EGP'), '3,050 EGP');
      expect(Money.format(3050.50, 'EGP'), '3,050.5 EGP');
      expect(Money.format(3050.55, 'EGP'), '3,050.55 EGP');
    });

    test('rounds to two places before formatting', () {
      expect(Money.format(2099.999, 'EGP'), '2,100 EGP');
    });

    test('treats null as zero and an empty currency as number-only', () {
      expect(Money.format(null, 'EGP'), '0 EGP');
      expect(Money.format(1500, ''), '1,500');
    });
  });

  group('Money.compact', () {
    test('shortens thousands and millions for calendar cells', () {
      expect(Money.compact(250), '250');
      expect(Money.compact(2000), '2K');
      expect(Money.compact(1500), '1.5K');
      expect(Money.compact(6825), '6.8K');
      expect(Money.compact(2500000), '2.5M');
    });
  });

  group('NightlyPricesState.nextAvailableNight', () {
    NightlyPrice night(DateTime date, double price, {double? discounted}) =>
        NightlyPrice(
          date: date,
          price: price,
          discountedPrice: discounted,
          isSpecialPrice: false,
        );

    test('is null before the calendar has loaded anything', () {
      final state = NightlyPricesState.initial(DateTime(2026, 7, 1), 'EGP');
      expect(state.nextAvailableNight, isNull);
    });

    test('picks the nearest future night and skips past and booked days', () {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final yesterday = todayOnly.subtract(const Duration(days: 1));
      final tomorrow = todayOnly.add(const Duration(days: 1));
      final dayAfter = todayOnly.add(const Duration(days: 2));

      final state = NightlyPricesState(
        leftMonth: DateTime(todayOnly.year, todayOnly.month, 1),
        pricesByMonth: {
          NightlyPricesPage.monthKeyFromDate(todayOnly): [
            night(yesterday, 900),
            night(todayOnly, 1000),
            night(tomorrow, 2000, discounted: 1400),
            night(dayAfter, 3000),
          ],
        },
        // Today is taken, so the nearest bookable night is tomorrow's.
        bookedDates: {todayOnly},
      );

      final next = state.nextAvailableNight;
      expect(next, isNotNull);
      expect(next!.date, tomorrow);
      expect(next.effectivePrice, 1400,
          reason: 'the header should quote what the guest would actually pay');
      expect(next.hasDiscount, isTrue);
    });
  });
}
