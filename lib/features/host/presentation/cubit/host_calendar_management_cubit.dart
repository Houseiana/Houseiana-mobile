import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/services/host_calendar_management_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/host/presentation/cubit/host_calendar_management_state.dart';

/// Drives the host Calendar screen: loads the host's properties, fetches the
/// per-month calendar, and performs block / unblock / pricing / min-nights
/// mutations. Selection and busy flags live in the Loaded state.
class HostCalendarManagementCubit extends Cubit<HostCalendarManagementState> {
  final HostCalendarManagementService _service;
  final UserSession _session;

  HostCalendarManagementCubit(this._service, this._session)
      : super(const HostCalendarManagementInitial());

  int _msgTick = 0;

  HostCalendarManagementLoaded? get _loaded =>
      state is HostCalendarManagementLoaded
          ? state as HostCalendarManagementLoaded
          : null;

  String get _userId => _session.userId ?? '';

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> init({String? initialPropertyId}) async {
    if (!_session.isLoggedIn || _userId.isEmpty) {
      emit(const HostCalendarManagementError('not-logged-in'));
      return;
    }
    emit(const HostCalendarManagementLoading());
    try {
      final properties = await _service.getPropertiesByHost(_userId);
      final reasons = await _service.getBlockReasons();

      PropertyModel? selected;
      if (properties.isNotEmpty) {
        selected = (initialPropertyId != null && initialPropertyId.isNotEmpty)
            ? properties.firstWhere(
                (p) => p.id == initialPropertyId,
                orElse: () => properties.first,
              )
            : properties.first;
      }

      final now = DateTime.now();
      final focusedMonth = DateTime(now.year, now.month, 1);

      emit(HostCalendarManagementLoaded(
        properties: properties,
        selectedProperty: selected,
        dailyRates: const {},
        blockedDates: const {},
        bookings: const [],
        currency: selected?.currency ?? 'EGP',
        focusedMonth: focusedMonth,
        minNights: _resolveMin(selected),
        reasons: reasons,
        selectedDates: const {},
      ));

      if (selected != null) {
        await _fetchCalendar(selected, focusedMonth);
      }
    } catch (e) {
      emit(HostCalendarManagementError(e.toString()));
    }
  }

  Future<void> selectProperty(PropertyModel property) async {
    final s = _loaded;
    if (s == null || property.id == s.selectedProperty?.id) return;
    emit(s.copyWith(
      selectedProperty: property,
      selectedDates: <DateTime>{},
      minNights: _resolveMin(property),
      currency: property.currency ?? s.currency,
    ));
    await _fetchCalendar(property, s.focusedMonth);
  }

  Future<void> reloadCalendar() async {
    final s = _loaded;
    if (s?.selectedProperty == null) return;
    await _fetchCalendar(s!.selectedProperty!, s.focusedMonth);
  }

  Future<void> _fetchCalendar(PropertyModel property, DateTime month) async {
    final s = _loaded;
    if (s == null) return;
    emit(s.copyWith(calendarLoading: true));
    try {
      final data = await _service.getPropertyCalendar(
        propertyId: property.id,
        userId: _userId,
        month: month,
      );
      final cur = _loaded;
      if (cur == null) return;
      emit(cur.copyWith(
        dailyRates: data.dailyRates,
        blockedDates: data.blockedDates,
        bookings: data.bookings,
        currency: data.currency,
        calendarLoading: false,
      ));
    } catch (e) {
      final cur = _loaded;
      if (cur == null) {
        emit(HostCalendarManagementError(e.toString()));
        return;
      }
      emit(cur.copyWith(
        calendarLoading: false,
        message: 'load-error',
        messageIsError: true,
        messageTick: ++_msgTick,
      ));
    }
  }

  void prevMonth() => _changeMonth(-1);

  void nextMonth() => _changeMonth(1);

  void _changeMonth(int delta) {
    final s = _loaded;
    if (s == null) return;
    final month = DateTime(s.focusedMonth.year, s.focusedMonth.month + delta, 1);
    emit(s.copyWith(focusedMonth: month, selectedDates: <DateTime>{}));
    if (s.selectedProperty != null) {
      _fetchCalendar(s.selectedProperty!, month);
    }
  }

  // ── Selection ───────────────────────────────────────────────────────────

  /// A tap selects a single start day; the range length is then driven by the
  /// duration stepper in the action sheet (which is modal). Tapping the same
  /// single day again clears the selection.
  void toggleDateSelection(DateTime day) {
    final s = _loaded;
    if (s == null || s.selectedProperty == null) return;
    final d = DateTime(day.year, day.month, day.day);
    if (d.isBefore(_today)) return; // past guard (today stays selectable)

    if (s.selectedDates.length == 1 && s.selectedDates.first == d) {
      emit(s.copyWith(selectedDates: <DateTime>{}));
    } else {
      emit(s.copyWith(selectedDates: {d}));
    }
  }

  /// Sets the selection to [nights] consecutive days from the current start
  /// day. Used by the duration stepper in the action sheet.
  void setDurationNights(int nights) {
    final s = _loaded;
    if (s == null || s.selectedDates.isEmpty) return;
    final start = s.sortedSelection.first;
    final n = nights.clamp(1, 60);
    final out = <DateTime>{};
    var d = DateTime(start.year, start.month, start.day);
    for (var i = 0; i < n; i++) {
      out.add(d);
      d = d.add(const Duration(days: 1));
    }
    emit(s.copyWith(selectedDates: out));
  }

  void clearSelection() {
    final s = _loaded;
    if (s == null || s.selectedDates.isEmpty) return;
    emit(s.copyWith(selectedDates: <DateTime>{}));
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> blockSelected({required int reasonId, String? reasonText}) =>
      _mutateStatus(
          reasonId: reasonId, reasonText: reasonText, successMsg: 'blocked');

  Future<void> unblockSelected() =>
      _mutateStatus(reasonId: null, reasonText: null, successMsg: 'unblocked');

  Future<void> _mutateStatus({
    required int? reasonId,
    String? reasonText,
    required String successMsg,
  }) async {
    final s = _loaded;
    if (s == null || s.selectedProperty == null || s.selectedDates.isEmpty) {
      return;
    }
    final sorted = s.sortedSelection;
    emit(s.copyWith(busyBlock: true));
    try {
      await _service.updateStatus(
        propertyId: s.selectedProperty!.id,
        userId: _userId,
        fromDate: sorted.first,
        toDate: sorted.last,
        reasonId: reasonId,
        reasonText: reasonText,
      );
      final cur = _loaded;
      if (cur != null) {
        emit(cur.copyWith(
          busyBlock: false,
          selectedDates: <DateTime>{},
          message: successMsg,
          messageIsError: false,
          messageTick: ++_msgTick,
        ));
      }
      await reloadCalendar();
    } catch (_) {
      _emitActionError(busyBlockOff: true);
    }
  }

  Future<void> saveSpecialPrice(double amount) async {
    final s = _loaded;
    if (s == null || s.selectedProperty == null || s.selectedDates.isEmpty) {
      return;
    }
    final sorted = s.sortedSelection;
    emit(s.copyWith(busyPrice: true));
    try {
      await _service.setSpecialPrice(
        hostId: _userId,
        propertyId: s.selectedProperty!.id,
        fromDate: sorted.first,
        toDate: sorted.last,
        price: amount,
      );
      final cur = _loaded;
      if (cur != null) {
        emit(cur.copyWith(
          busyPrice: false,
          selectedDates: <DateTime>{},
          message: 'price-updated',
          messageIsError: false,
          messageTick: ++_msgTick,
        ));
      }
      await reloadCalendar();
    } catch (_) {
      _emitActionError(busyPriceOff: true);
    }
  }

  Future<void> saveMinNights(int value) async {
    final s = _loaded;
    if (s == null || s.selectedProperty == null) return;
    final v = value.clamp(1, 30);
    emit(s.copyWith(busyMinNights: true));
    try {
      await _service.setMinimumDays(
        propertyId: s.selectedProperty!.id,
        hostId: _userId,
        minimumDaysForBooking: v,
      );
      final cur = _loaded;
      if (cur != null) {
        emit(cur.copyWith(
          busyMinNights: false,
          minNights: v,
          message: 'min-nights-updated',
          messageIsError: false,
          messageTick: ++_msgTick,
        ));
      }
    } catch (_) {
      _emitActionError(busyMinNightsOff: true);
    }
  }

  void _emitActionError({
    bool busyBlockOff = false,
    bool busyPriceOff = false,
    bool busyMinNightsOff = false,
  }) {
    final cur = _loaded;
    if (cur == null) return;
    emit(cur.copyWith(
      busyBlock: busyBlockOff ? false : null,
      busyPrice: busyPriceOff ? false : null,
      busyMinNights: busyMinNightsOff ? false : null,
      message: 'action-error',
      messageIsError: true,
      messageTick: ++_msgTick,
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _resolveMin(PropertyModel? p) => (p?.minNights ?? 1).clamp(1, 30);

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
