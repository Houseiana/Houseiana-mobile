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
  });

  factory NightlyPricesState.initial(DateTime month, String currency) =>
      NightlyPricesState(leftMonth: month, currency: currency);

  DateTime get rightMonth =>
      DateTime(leftMonth.year, leftMonth.month + 1, 1);

  bool get hasCompleteRange => checkIn != null && checkOut != null;

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
    bool clearCheckIn = false,
    bool clearCheckOut = false,
    bool clearFatalError = false,
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
      ];
}
