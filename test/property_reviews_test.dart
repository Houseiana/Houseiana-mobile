import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/core/models/property_ratings.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/property_reviews_section.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// The reviews block on the property page and the payload behind it.
///
/// `GET /api/ratings/property/{propertyId}` answers with the rows **and** the
/// aggregates in one envelope. Reading only `data` — what the screen used to do
/// before the block was wired up — threw away `averageRating`, `totalRatings`
/// and the six category averages, which are precisely what the web listing
/// draws its score line and bars from.
const _swaggerSample = {
  'success': true,
  'message': 'Ratings retrieved successfully',
  'data': [
    {
      'id': '6d80747c-78cd-4685-81c5-827da9dd0bec',
      'guestId': 'user_3Dicv0NUs4ETM6UtmupRsw5bJTH',
      'guestName': 'Nadeen Ismail',
      'guestImage': null,
      'hostId': null,
      'propertyId': '55ea8a85-8220-4e9f-9d0c-6140421e1f1e',
      'rating': 4,
      'comment': 'bi',
      'cleanliness': null,
      'accuracy': null,
      'checkIn': null,
      'communication': null,
      'location': null,
      'value': null,
      'createdAt': '2026-08-23T23:24:47.4261373',
    },
  ],
  'averageRating': 4,
  'totalRatings': 1,
  'averageCleanliness': 0,
  'averageAccuracy': 0,
  'averageCheckIn': 0,
  'averageCommunication': 0,
  'averageLocation': 0,
  'averageValue': 0,
};

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.runAsync(
      () => AppLocalizations.load(AppLocale.fromCode(locale.languageCode)));

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PropertyRatings.fromJson', () {
    test('reads the rows and the aggregates out of the same envelope', () {
      final ratings = PropertyRatings.fromJson(_swaggerSample);

      expect(ratings.reviews, hasLength(1));
      expect(ratings.averageRating, 4);
      expect(ratings.totalRatings, 1);

      final review = ratings.reviews.single;
      // The endpoint names these `guestName` / `guestImage` / `guestId`.
      expect(review.userName, 'Nadeen Ismail');
      expect(review.userAvatar, isNull);
      expect(review.userId, 'user_3Dicv0NUs4ETM6UtmupRsw5bJTH');
      expect(review.rating, 4);
      expect(review.comment, 'bi');
      expect(review.createdAt?.year, 2026);
      expect(review.createdAt?.month, 8);
    });

    test('an all-zero summary is not treated as scored categories', () {
      expect(PropertyRatings.fromJson(_swaggerSample).hasCategoryScores,
          isFalse);
    });

    test('category averages are read when the backend has them', () {
      final ratings = PropertyRatings.fromJson({
        ..._swaggerSample,
        'averageCleanliness': 4.5,
        'averageAccuracy': 4,
        'averageCheckIn': 5,
        'averageCommunication': 3.5,
        'averageLocation': 4,
        'averageValue': 4.25,
      });

      expect(ratings.hasCategoryScores, isTrue);
      expect(ratings.cleanliness, 4.5);
      expect(ratings.checkIn, 5);
      expect(ratings.value, 4.25);
    });

    test('a summary-less payload still yields a score and a count', () {
      final ratings = PropertyRatings.fromJson([
        {'id': 'a', 'rating': 5, 'comment': 'great'},
        {'id': 'b', 'rating': 4, 'comment': 'good'},
      ]);

      expect(ratings.totalRatings, 2);
      expect(ratings.averageRating, 4.5);
    });

    test('nothing to show is empty, never an exception', () {
      expect(PropertyRatings.fromJson(null).isEmpty, isTrue);
      expect(PropertyRatings.fromJson({'success': true, 'data': null}).isEmpty,
          isTrue);
      expect(PropertyRatings.fromJson('unexpected').isEmpty, isTrue);
    });
  });

  group('PropertyReviewsSection', () {
    testWidgets('shows the endpoint score, the count and the review',
        (tester) async {
      await _pump(
        tester,
        PropertyReviewsSection(
          ratings: PropertyRatings.fromJson(_swaggerSample),
          onShowAll: () {},
        ),
      );

      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('1 review'), findsOneWidget);
      expect(find.text('Nadeen Ismail'), findsOneWidget);
      expect(find.text('bi'), findsOneWidget);
      // Month and year, the stamp the web reviews carry.
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('hides the category bars when nothing was scored',
        (tester) async {
      await _pump(
        tester,
        PropertyReviewsSection(ratings: PropertyRatings.fromJson(_swaggerSample)),
      );

      // Six bars reading 0.0 would be noise, not information: a guest can
      // submit an overall star with every category left null, and that is what
      // today's reviews look like.
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Cleanliness'), findsNothing);
    });

    testWidgets('draws all six bars once any category is scored',
        (tester) async {
      await _pump(
        tester,
        PropertyReviewsSection(
          ratings: PropertyRatings.fromJson({
            ..._swaggerSample,
            'averageCleanliness': 4.5,
          }),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNWidgets(6));
      expect(find.text('Cleanliness'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
    });

    testWidgets('only offers "show all" when reviews are held back',
        (tester) async {
      final many = List.generate(
        5,
        (i) => {
          'id': 'r$i',
          'guestName': 'Guest $i',
          'rating': 5,
          'comment': 'stay $i',
          'createdAt': '2026-08-0${i + 1}T10:00:00',
        },
      );

      await _pump(
        tester,
        PropertyReviewsSection(
          ratings: PropertyRatings.fromJson({
            'data': many,
            'averageRating': 5,
            'totalRatings': 5,
          }),
          onShowAll: () {},
        ),
      );

      expect(find.text('Show all 5 reviews'), findsOneWidget);
      expect(find.text('stay 0'), findsOneWidget);
      expect(find.text('stay 2'), findsOneWidget);
      // Held back — the fourth and fifth live on the all-reviews screen.
      expect(find.text('stay 3'), findsNothing);
    });

    testWidgets('reads Arabic in Arabic, month name included', (tester) async {
      await _pump(
        tester,
        PropertyReviewsSection(
          ratings: PropertyRatings.fromJson({
            ..._swaggerSample,
            'averageCleanliness': 4,
          }),
        ),
        locale: const Locale('ar'),
      );

      expect(find.text('أغسطس 2026'), findsOneWidget);
      expect(find.text('النظافة'), findsOneWidget);
    });
  });
}
