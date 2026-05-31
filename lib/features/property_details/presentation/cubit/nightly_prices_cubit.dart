import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/models/nightly_price_model.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/nightly_prices_state.dart';

class NightlyPricesCubit extends Cubit<NightlyPricesState> {
  final PropertyService _service;
  final String propertyId;

  NightlyPricesCubit(this._service, this.propertyId)
      : super(NightlyPricesState.initial(
          DateTime(DateTime.now().year, DateTime.now().month, 1),
          'EGP',
        ));

  Future<void> open({required String currency}) async {
    final now = DateTime.now();
    final initialMonth = DateTime(now.year, now.month, 1);
    emit(NightlyPricesState.initial(initialMonth, currency));
    // Fire booked-dates in parallel with the first price page.
    final bookedFuture = _loadBookedDates();
    await _fetchPage(1);
    await bookedFuture;
    final s = state;
    if (s.initialized) {
      // Make sure both the current month and the next month are loaded,
      // even if the API's page 1 returned a different base month.
      await _ensureMonth(s.leftMonth);
      await _ensureMonth(s.rightMonth);
    }
  }

  Future<void> _loadBookedDates() async {
    try {
      final dates = await _service.getBookedDates(propertyId);
      if (kDebugMode) {
        debugPrint(
          '[NightlyPrices] booked-dates received ${dates.length} blocked days',
        );
      }
      emit(state.copyWith(bookedDates: dates));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NightlyPrices] booked-dates error: $e');
      }
    }
  }

  Future<void> ensureMonth(DateTime month) async {
    await _ensureMonth(DateTime(month.year, month.month, 1));
  }

  void goNext() {
    final next = DateTime(state.leftMonth.year, state.leftMonth.month + 1, 1);
    if (!_canShowMonth(next)) return;
    emit(state.copyWith(leftMonth: next));
    _ensureMonth(next);
    _ensureMonth(DateTime(next.year, next.month + 1, 1));
  }

  void goPrev() {
    final prev = DateTime(state.leftMonth.year, state.leftMonth.month - 1, 1);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    if (prev.isBefore(currentMonth)) return;
    emit(state.copyWith(leftMonth: prev));
    _ensureMonth(prev);
    _ensureMonth(DateTime(prev.year, prev.month + 1, 1));
  }

  bool canGoNext() {
    final nextRight =
        DateTime(state.leftMonth.year, state.leftMonth.month + 2, 1);
    return _canShowMonth(nextRight);
  }

  bool canGoPrev() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    return state.leftMonth.isAfter(currentMonth);
  }

  void tapDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (d.isBefore(todayOnly)) return;
    if (state.bookedDates.contains(d)) return;

    final ci = state.checkIn;
    final co = state.checkOut;

    if (ci == null) {
      emit(state.copyWith(checkIn: d, clearCheckOut: true));
      return;
    }
    if (co == null) {
      if (d.isAfter(ci)) {
        // Reject ranges that span any booked night.
        if (_rangeCrossesBooked(ci, d)) {
          emit(state.copyWith(checkIn: d, clearCheckOut: true));
          return;
        }
        emit(state.copyWith(checkOut: d));
      } else {
        emit(state.copyWith(checkIn: d));
      }
      return;
    }
    emit(state.copyWith(checkIn: d, clearCheckOut: true));
  }

  bool _rangeCrossesBooked(DateTime start, DateTime end) {
    var d = DateTime(start.year, start.month, start.day)
        .add(const Duration(days: 1));
    final endOnly = DateTime(end.year, end.month, end.day);
    while (d.isBefore(endOnly)) {
      if (state.bookedDates.contains(d)) return true;
      d = d.add(const Duration(days: 1));
    }
    return false;
  }

  void clearSelection() {
    emit(state.copyWith(clearCheckIn: true, clearCheckOut: true));
  }

  Future<void> retryMonth(DateTime month) async {
    final key = NightlyPricesPage.monthKeyFromDate(month);
    final updatedErrors = Map<String, String>.from(state.errorsByMonth)
      ..remove(key);
    emit(state.copyWith(errorsByMonth: updatedErrors));
    await _ensureMonth(month);
  }

  bool _canShowMonth(DateTime month) {
    final base = state.baseMonthKey;
    final total = state.totalPages;
    if (base == null || total == null) return true;
    final parts = base.split('-');
    final baseYear = int.parse(parts[0]);
    final baseMonth = int.parse(parts[1]);
    final diff =
        (month.year * 12 + month.month) - (baseYear * 12 + baseMonth);
    final page = diff + 1;
    return page >= 1 && page <= total;
  }

  int? _pageForMonth(DateTime month) {
    final base = state.baseMonthKey;
    if (base == null) return null;
    final parts = base.split('-');
    final baseYear = int.parse(parts[0]);
    final baseMonth = int.parse(parts[1]);
    final diff =
        (month.year * 12 + month.month) - (baseYear * 12 + baseMonth);
    final page = diff + 1;
    final total = state.totalPages ?? 12;
    if (page < 1 || page > total) return null;
    return page;
  }

  Future<void> _ensureMonth(DateTime month) async {
    final key = NightlyPricesPage.monthKeyFromDate(month);
    if (state.pricesByMonth.containsKey(key)) return;
    if (state.loadingMonths.contains(key)) return;
    final page = _pageForMonth(month);
    if (page == null) return;
    await _fetchPage(page, expectedMonthKey: key);
  }

  Future<void> _fetchPage(int page, {String? expectedMonthKey}) async {
    final loadingKey = expectedMonthKey ?? 'page-$page';
    final updatedLoading = Set<String>.from(state.loadingMonths)
      ..add(loadingKey);
    emit(state.copyWith(loadingMonths: updatedLoading));

    try {
      final result = await _service.getNightlyPrices(propertyId, page: page);
      final responseKey = result.monthKey;

      if (kDebugMode) {
        debugPrint(
          '[NightlyPrices] page=$page received ${result.items.length} items, '
          'monthKey=$responseKey, totalPages=${result.totalPages}, '
          'first=${result.items.isNotEmpty ? result.items.first.date.toIso8601String() : "-"}, '
          'last=${result.items.isNotEmpty ? result.items.last.date.toIso8601String() : "-"}',
        );
      }

      // Distribute items into their actual month buckets (a page may span 2 months).
      final byMonth = <String, List<NightlyPrice>>{};
      for (final item in result.items) {
        final key = NightlyPricesPage.monthKeyFromDate(item.date);
        byMonth.putIfAbsent(key, () => []).add(item);
      }

      final newPrices =
          Map<String, List<NightlyPrice>>.from(state.pricesByMonth);
      byMonth.forEach((key, items) {
        final existing = newPrices[key] ?? const <NightlyPrice>[];
        final merged = <DateTime, NightlyPrice>{};
        for (final e in existing) {
          merged[e.date] = e;
        }
        for (final e in items) {
          merged[e.date] = e;
        }
        final sorted = merged.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        newPrices[key] = sorted;
      });

      final newLoading = Set<String>.from(state.loadingMonths)
        ..remove(loadingKey);
      for (final k in byMonth.keys) {
        newLoading.remove(k);
      }

      final newErrors = Map<String, String>.from(state.errorsByMonth);
      for (final k in byMonth.keys) {
        newErrors.remove(k);
      }

      String? baseKey = state.baseMonthKey;
      if (page == 1 && responseKey != null) {
        baseKey = responseKey;
      }

      emit(state.copyWith(
        pricesByMonth: newPrices,
        loadingMonths: newLoading,
        errorsByMonth: newErrors,
        baseMonthKey: baseKey,
        totalPages: result.totalPages,
        initialized: true,
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NightlyPrices] page=$page error: $e');
      }
      final newLoading = Set<String>.from(state.loadingMonths)
        ..remove(loadingKey);
      final newErrors = Map<String, String>.from(state.errorsByMonth);
      if (expectedMonthKey != null) {
        newErrors[expectedMonthKey] = e.toString();
      }
      emit(state.copyWith(
        loadingMonths: newLoading,
        errorsByMonth: newErrors,
        fatalError: page == 1 && !state.initialized ? e.toString() : null,
      ));
    }
  }
}
