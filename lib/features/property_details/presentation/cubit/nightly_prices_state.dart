import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/nightly_price_model.dart';

class NightlyPricesState extends Equatable {
  final Map<String, List<NightlyPrice>> pricesByMonth;
  final Set<String> loadingMonths;
  final Map<String, String> errorsByMonth;
  final DateTime leftMonth;
  final String? baseMonthKey;
  final int? totalPages;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String currency;
  final bool initialized;
  final String? fatalError;
  final Set<DateTime> bookedDates;

  /// Raw `/property-search/{id}/availability` response for the selected range —
  /// the only source of the cleaning / service fees and the stay total. Null
  /// until a complete range is picked (or when the quote failed).
  final Map<String, dynamic>? quote;
  final bool quoteLoading;

  const NightlyPricesState({
    this.pricesByMonth = const {},
    this.loadingMonths = const {},
    this.errorsByMonth = const {},
    required this.leftMonth,
    this.baseMonthKey,
    this.totalPages,
    this.checkIn,
    this.checkOut,
    this.currency = 'EGP',
    this.initialized = false,
    this.fatalError,
    this.bookedDates = const {},
    this.quote,
    this.quoteLoading = false,
  });

  factory NightlyPricesState.initial(DateTime month, String currency) =>
      NightlyPricesState(leftMonth: month, currency: currency);

  DateTime get rightMonth =>
      DateTime(leftMonth.year, leftMonth.month + 1, 1);

  bool get hasCompleteRange => checkIn != null && checkOut != null;

  /// Sums the loaded nightly prices over the selected range (check-in
  /// inclusive, check-out exclusive): `original` is the pre-discount total and
  /// `effective` the total actually charged (discounted nights use their
  /// discounted price). Returns null unless a complete range is selected and
  /// every night in it has a loaded price.
  ({double original, double effective})? get selectedRangeTotals {
    final ci = checkIn;
    final co = checkOut;
    if (ci == null || co == null) return null;
    final end = DateTime(co.year, co.month, co.day);
    var day = DateTime(ci.year, ci.month, ci.day);
    double original = 0;
    double effective = 0;
    while (day.isBefore(end)) {
      final monthPrices =
          pricesByMonth[NightlyPricesPage.monthKeyFromDate(day)];
      if (monthPrices == null) return null;
      NightlyPrice? entry;
      for (final p in monthPrices) {
        if (p.date.year == day.year &&
            p.date.month == day.month &&
            p.date.day == day.day) {
          entry = p;
          break;
        }
      }
      if (entry == null) return null;
      original += entry.price;
      effective += entry.effectivePrice;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return (original: original, effective: effective);
  }

  NightlyPricesState copyWith({
    Map<String, List<NightlyPrice>>? pricesByMonth,
    Set<String>? loadingMonths,
    Map<String, String>? errorsByMonth,
    DateTime? leftMonth,
    String? baseMonthKey,
    int? totalPages,
    DateTime? checkIn,
    DateTime? checkOut,
    String? currency,
    bool? initialized,
    String? fatalError,
    Set<DateTime>? bookedDates,
    Map<String, dynamic>? quote,
    bool? quoteLoading,
    bool clearCheckIn = false,
    bool clearCheckOut = false,
    bool clearFatalError = false,
    bool clearQuote = false,
  }) {
    return NightlyPricesState(
      pricesByMonth: pricesByMonth ?? this.pricesByMonth,
      loadingMonths: loadingMonths ?? this.loadingMonths,
      errorsByMonth: errorsByMonth ?? this.errorsByMonth,
      leftMonth: leftMonth ?? this.leftMonth,
      baseMonthKey: baseMonthKey ?? this.baseMonthKey,
      totalPages: totalPages ?? this.totalPages,
      checkIn: clearCheckIn ? null : (checkIn ?? this.checkIn),
      checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
      currency: currency ?? this.currency,
      initialized: initialized ?? this.initialized,
      fatalError: clearFatalError ? null : (fatalError ?? this.fatalError),
      bookedDates: bookedDates ?? this.bookedDates,
      quote: clearQuote ? null : (quote ?? this.quote),
      quoteLoading: quoteLoading ?? this.quoteLoading,
    );
  }

  @override
  List<Object?> get props => [
        pricesByMonth,
        loadingMonths,
        errorsByMonth,
        leftMonth,
        baseMonthKey,
        totalPages,
        checkIn,
        checkOut,
        currency,
        initialized,
        fatalError,
        bookedDates,
        quote,
        quoteLoading,
      ];
}
