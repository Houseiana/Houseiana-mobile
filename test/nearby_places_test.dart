import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_details.dart';
import 'package:houseiana_mobile_app/core/models/nearby_place.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';

/// The payloads below are VERBATIM from live probes on 2026-09-01 — staging
/// for the hotel rows and the first property, production for the Citystars
/// row. They are the reason this feature parses the way it does; if the
/// backend shape changes, these are the tests that should fail first.
///
/// The whole point of the group below is that the two stay kinds speak
/// different dialects of the same object. See `docs/nearby_places_contract.md`.
void main() {
  // ── Property dialect ──────────────────────────────────────────────────────
  //
  // Stable SCREAMING_SNAKE enums, `nameAR` alongside `name`, `image` present
  // and empty. Never server-localized.
  Map<String, dynamic> propertyRow() => {
        'id': 'a9e61c39-a33b-4ff7-b94b-0d8d5dd53cef',
        'propertyId': '55ea8a85-8220-4e9f-9d0c-6140421e1f1e',
        'categoryId': 1,
        'name': ' Starbucks',
        'nameAR': 'ستاربكس',
        'description': 'Starbucks coffee ',
        'descriptionAR': 'ستاربكس كافيه',
        'rating': 5,
        'reviewCount': 899,
        'distanceMeters': 1000,
        'walkMinutes': 15,
        'driveMinutes': 5,
        'googleMapsUrl': 'https://maps.app.goo.gl/ovtcLTx1K7qqQ9966',
        'priceLevel': 'EXPENSIVE',
        'displayOrder': 1,
        'timeOfDay': 'MORNING',
        'image': '',
      };

  // ── Hotel dialect ─────────────────────────────────────────────────────────
  //
  // `hotelId`, a `categoryName`, no `nameAR`, no `image`, and `priceLevel` /
  // `timeOfDay` as DISPLAY TEXT the backend localizes.
  Map<String, dynamic> hotelRowEn() => {
        'id': '895a5f29-0a4c-404a-b516-a1d096418b4d',
        'hotelId': 'e49a5b1a-dd23-4db6-a2b6-37d8b95acb2e',
        'categoryId': 1,
        'categoryName': 'coffee',
        'name': 'costa cafe',
        'description': 'costa coffee',
        'rating': 4,
        'reviewCount': 150,
        'distanceMeters': 800,
        'walkMinutes': 10,
        'driveMinutes': 4,
        'googleMapsUrl': 'test',
        'priceLevel': 'Moderately Priced',
        'displayOrder': 1,
        'timeOfDay': 'Late Morning',
      };

  Map<String, dynamic> hotelRowAr() => {
        'id': '424fd7fe-3dd6-48eb-bb86-688c2f947a90',
        'hotelId': 'e49a5b1a-dd23-4db6-a2b6-37d8b95acb2e',
        'categoryId': 2,
        'categoryName': 'فطور',
        'name': 'بريدفاست',
        'description': 'بريدفاست',
        'rating': 5,
        'reviewCount': 1500,
        'distanceMeters': 800,
        'walkMinutes': 10,
        'driveMinutes': 5,
        'googleMapsUrl': 'test',
        'priceLevel': 'متوسط السعر',
        'displayOrder': 2,
        'timeOfDay': 'قبل الظهر',
      };

  group('NearbyPlace — property dialect', () {
    test('parses the verified staging row', () {
      final place = NearbyPlace.fromJson(propertyRow());

      expect(place.id, 'a9e61c39-a33b-4ff7-b94b-0d8d5dd53cef');
      expect(place.stayId, '55ea8a85-8220-4e9f-9d0c-6140421e1f1e');
      expect(place.categoryId, 1);
      // The backend sends " Starbucks" with a leading space.
      expect(place.name, 'Starbucks');
      expect(place.nameAr, 'ستاربكس');
      expect(place.rating, 5);
      expect(place.reviewCount, 899);
      expect(place.walkMinutes, 15);
      expect(place.driveMinutes, 5);
      expect(place.priceLevel, NearbyPriceLevel.expensive);
      expect(place.timeOfDay, NearbyTimeOfDay.morning);
      expect(place.displayOrder, 1);
      expect(place.imageUrl, '');
    });

    test('picks the Arabic name and description in Arabic', () {
      final place = NearbyPlace.fromJson(propertyRow());

      expect(place.localizedName(isArabic: true), 'ستاربكس');
      expect(place.localizedDescription(isArabic: true), 'ستاربكس كافيه');
      expect(place.localizedName(isArabic: false), 'Starbucks');
      expect(place.localizedDescription(isArabic: false), 'Starbucks coffee');
    });

    test('parses a fractional rating — production sends 4.5, not an int', () {
      final place = NearbyPlace.fromJson({
        ...propertyRow(),
        'rating': 4.5,
        'reviewCount': 0,
        'driveMinutes': 0,
        'displayOrder': 0,
      });

      expect(place.rating, 4.5);
      // 0 review count and 0 drive minutes both mean "print nothing".
      expect(place.hasReviewCount, isFalse);
      expect(place.hasDriveMinutes, isFalse);
      expect(place.hasWalkMinutes, isTrue);
      // displayOrder 0 is a real value, not "missing".
      expect(place.displayOrder, 0);
    });
  });

  group('NearbyPlace — hotel dialect', () {
    test('reads hotelId as the stay id and survives the missing nameAR', () {
      final place = NearbyPlace.fromJson(hotelRowEn());

      expect(place.stayId, 'e49a5b1a-dd23-4db6-a2b6-37d8b95acb2e');
      expect(place.nameAr, '');
      expect(place.descriptionAr, '');
      expect(place.imageUrl, '');
      // With no Arabic field the localized name falls back to `name`, which
      // the hotels controller has already translated.
      expect(place.localizedName(isArabic: true), 'costa cafe');
    });

    test('parses the spaced English display text as the same enums', () {
      final place = NearbyPlace.fromJson(hotelRowEn());

      // 'Moderately Priced' and 'Late Morning' are what the hotel endpoint
      // really sends in English — the space is the whole reason _token
      // collapses separators. Deleting that must fail here.
      expect(place.priceLevel, NearbyPriceLevel.moderate);
      expect(place.timeOfDay, NearbyTimeOfDay.lateMorning);
    });

    test('accepts every separator spelling of the same token', () {
      for (final raw in [
        'LATE_MORNING',
        'Late Morning',
        'late-morning',
        'late   morning',
      ]) {
        expect(
          NearbyPlace.fromJson({...hotelRowEn(), 'timeOfDay': raw}).timeOfDay,
          NearbyTimeOfDay.lateMorning,
          reason: 'should parse "$raw"',
        );
      }
      for (final raw in ['MODERATELY_PRICED', 'Moderately Priced']) {
        expect(
          NearbyPlace.fromJson({...hotelRowEn(), 'priceLevel': raw}).priceLevel,
          NearbyPriceLevel.moderate,
          reason: 'should parse "$raw"',
        );
      }
    });

    test('keeps Arabic display text verbatim instead of guessing an enum', () {
      final place = NearbyPlace.fromJson(hotelRowAr());

      expect(place.priceLevel, isNull);
      expect(place.timeOfDay, isNull);
      expect(place.priceLevelLabel, 'متوسط السعر');
      expect(place.timeOfDayLabel, 'قبل الظهر');
      expect(place.localizedName(isArabic: true), 'بريدفاست');
    });

    test('tolerates the null reviewCount/displayOrder hotels can send', () {
      final place = NearbyPlace.fromJson({
        ...hotelRowEn(),
        'reviewCount': null,
        'displayOrder': null,
        'priceLevel': null,
        'timeOfDay': null,
      });

      expect(place.reviewCount, isNull);
      expect(place.hasReviewCount, isFalse);
      expect(place.displayOrder, isNull);
      expect(place.priceLevelLabel, '');
      expect(place.timeOfDayLabel, '');
    });
  });

  group('0-and-null guards', () {
    test('an unrated place prints no star — 0 means unset in this payload', () {
      expect(NearbyPlace.fromJson({...propertyRow(), 'rating': 0}).hasRating,
          isFalse);
      expect(NearbyPlace.fromJson({...propertyRow(), 'rating': null}).hasRating,
          isFalse);
      expect(NearbyPlace.fromJson({...propertyRow(), 'rating': 4.5}).hasRating,
          isTrue);
    });

    test('a numeric enum is dropped, not printed as a bare digit', () {
      // The admin DTOs express timeOfDay/priceLevel as ints. If a read
      // endpoint ever follows suit, the raw-text fallback would put a
      // payments icon next to '2'. A number is an id, not a label.
      final place = NearbyPlace.fromJson({
        ...propertyRow(),
        'priceLevel': 2,
        'timeOfDay': 3,
      });

      expect(place.priceLevel, isNull);
      expect(place.priceLevelLabel, '');
      expect(place.timeOfDay, isNull);
      expect(place.timeOfDayLabel, '');
    });
  });
  group('mapsUri', () {
    test('rejects the garbage the live rows actually carry', () {
      for (final junk in ['test', 'testinnng', '', '   ', 'maps.google.com']) {
        final place = NearbyPlace.fromJson({
          ...propertyRow(),
          'googleMapsUrl': junk,
        });
        expect(place.mapsUri, isNull, reason: 'should reject "$junk"');
      }
    });

    test('accepts a real link', () {
      final place = NearbyPlace.fromJson(propertyRow());
      expect(place.mapsUri, isNotNull);
      expect(place.mapsUri!.host, 'maps.app.goo.gl');
    });
  });

  group('ordering', () {
    List<NearbyPlace> places(List<Map<String, dynamic>> rows) =>
        rows.map(NearbyPlace.fromJson).toList();

    test('runs the day plan through the day, not by list order', () {
      final unordered = NearbyPlace.sorted(places([
        {...propertyRow(), 'categoryId': 3, 'timeOfDay': 'AFTERNOON'},
        {...propertyRow(), 'categoryId': 1, 'timeOfDay': 'MORNING'},
        {...propertyRow(), 'categoryId': 2, 'timeOfDay': 'LATE_MORNING'},
      ]));

      expect(
        unordered.map((p) => p.timeOfDay).toList(),
        [
          NearbyTimeOfDay.morning,
          NearbyTimeOfDay.lateMorning,
          NearbyTimeOfDay.afternoon,
        ],
      );
    });

    test('falls back to displayOrder when timeOfDay is unparseable', () {
      // Every hotel row in Arabic looks like this.
      final arabic = NearbyPlace.sorted(places([
        {...hotelRowAr(), 'displayOrder': 3, 'categoryId': 3},
        {...hotelRowAr(), 'displayOrder': 1, 'categoryId': 1},
        {...hotelRowAr(), 'displayOrder': 2, 'categoryId': 2},
      ]));

      expect(arabic.map((p) => p.displayOrder).toList(), [1, 2, 3]);
    });

    test('keeps the payload order for Arabic hotel rows that tie on everything',
        () {
      // The bug this pins: an Arabic hotel has no parseable timeOfDay AND a
      // null displayOrder, so every row ties. Breaking that tie on `name`
      // sorted the day alphabetically by Arabic name — the evening bar led the
      // chain while the card still said "start with coffee", and the same
      // hotel in English ordered correctly. The order must survive the switch.
      final rows = [
        {...hotelRowAr(), 'categoryId': 1, 'name': 'قهوة كوستا', 'timeOfDay': 'صباحاً', 'displayOrder': null},
        {...hotelRowAr(), 'categoryId': 2, 'name': 'فطور بريدفاست', 'timeOfDay': 'قبل الظهر', 'displayOrder': null},
        {...hotelRowAr(), 'categoryId': 6, 'name': 'سينما', 'timeOfDay': 'مساءً', 'displayOrder': null},
      ];

      expect(
        NearbyPlace.sorted(places(rows)).map((p) => p.name).toList(),
        ['قهوة كوستا', 'فطور بريدفاست', 'سينما'],
      );
      // And the English payload of the same hotel agrees, so the plan does not
      // reverse itself on a language switch.
      expect(
        NearbyPlace.sorted(places([
          {...hotelRowEn(), 'categoryId': 1, 'name': 'Costa', 'timeOfDay': 'Morning', 'displayOrder': null},
          {...hotelRowEn(), 'categoryId': 2, 'name': 'Breadfast', 'timeOfDay': 'Late Morning', 'displayOrder': null},
          {...hotelRowEn(), 'categoryId': 6, 'name': 'Cinema', 'timeOfDay': 'Evening', 'displayOrder': null},
        ])).map((p) => p.categoryId).toList(),
        [1, 2, 6],
      );
    });

    test('sorted() is stable — equal rows keep the order they arrived in', () {
      final rows = [
        for (var i = 0; i < 8; i++)
          {...hotelRowAr(), 'id': 'r$i', 'categoryId': 3, 'displayOrder': null},
      ];
      expect(
        NearbyPlace.sorted(places(rows)).map((p) => p.id).toList(),
        ['r0', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7'],
      );
    });

    test('sorts places with a known time before ones without', () {
      final mixed = NearbyPlace.sorted(places([
        {...hotelRowAr(), 'displayOrder': 1, 'categoryId': 1},
        {...propertyRow(), 'categoryId': 2, 'timeOfDay': 'EVENING'},
      ]));

      expect(mixed.first.timeOfDay, NearbyTimeOfDay.evening);
      expect(mixed.last.timeOfDay, isNull);
    });

    test('the day plan takes one place per category, capped', () {
      final plan = NearbyPlace.dayPlan(places([
        {...propertyRow(), 'categoryId': 1, 'timeOfDay': 'MORNING', 'displayOrder': 1},
        {...propertyRow(), 'categoryId': 1, 'timeOfDay': 'MORNING', 'displayOrder': 2},
        {...propertyRow(), 'categoryId': 2, 'timeOfDay': 'LATE_MORNING'},
        {...propertyRow(), 'categoryId': 3, 'timeOfDay': 'AFTERNOON'},
        {...propertyRow(), 'categoryId': 4, 'timeOfDay': 'EVENING'},
        {...propertyRow(), 'categoryId': 5, 'timeOfDay': 'EVENING'},
      ]));

      expect(plan.length, 4);
      expect(plan.map((p) => p.categoryId).toList(), [1, 2, 3, 4]);
      // The earlier displayOrder wins inside a category.
      expect(plan.first.displayOrder, 1);
    });
  });

  group('listFrom', () {
    test('ignores anything that is not a list of maps', () {
      expect(NearbyPlace.listFrom(null), isEmpty);
      expect(NearbyPlace.listFrom('nope'), isEmpty);
      expect(NearbyPlace.listFrom(const []), isEmpty);
      expect(NearbyPlace.listFrom([1, 'two', null]), isEmpty);
    });

    test('drops rows with no name at all', () {
      final parsed = NearbyPlace.listFrom([
        propertyRow(),
        {...propertyRow(), 'name': '', 'nameAR': ''},
      ]);
      expect(parsed, hasLength(1));
    });
  });

  group('NearbyCategory', () {
    test('parses the verified lookup payload', () {
      final categories = NearbyCategory.listFrom([
        {'id': 1, 'name': 'coffee'},
        {'id': 2, 'name': 'breakfast'},
        {'id': 0, 'name': 'bogus'},
      ]);

      expect(categories, hasLength(2));
      expect(categories.first.id, 1);
      expect(categories.first.name, 'coffee');
    });
  });

  group('the models that carry the places', () {
    test('PropertyModel keeps nearbyPlaces — it drops undeclared keys', () {
      final property = PropertyModel.fromJson({
        'id': '55ea8a85-8220-4e9f-9d0c-6140421e1f1e',
        'title': 'شالية جديد 3 غرف',
        'nearbyPlaces': [propertyRow()],
      });

      expect(property.nearbyPlaces, hasLength(1));
      expect(property.nearbyPlaces.first.name, 'Starbucks');
    });

    test('PropertyModel defaults to no places rather than null', () {
      final property = PropertyModel.fromJson({'id': 'x'});
      expect(property.nearbyPlaces, isEmpty);
    });

    test('HotelDetails keeps nearbyPlaces', () {
      final hotel = HotelDetails.fromJson({
        'hotelId': 'e49a5b1a-dd23-4db6-a2b6-37d8b95acb2e',
        'name': 'testing en name',
        'nearbyPlaces': [hotelRowEn(), hotelRowAr()],
      });

      expect(hotel.nearbyPlaces, hasLength(2));
      expect(hotel.nearbyPlaces.first.stayId,
          'e49a5b1a-dd23-4db6-a2b6-37d8b95acb2e');
    });

    test('HotelDetails defaults to no places', () {
      final hotel = HotelDetails.fromJson({'hotelId': 'x', 'name': 'y'});
      expect(hotel.nearbyPlaces, isEmpty);
    });
  });
}
