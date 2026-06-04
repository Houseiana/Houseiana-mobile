import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/features/host/data/models/block_reason_model.dart';
import 'package:houseiana_mobile_app/features/host/data/models/calendar_day_model.dart';

/// Aggregated, parsed result of the `/api/property-calendar` endpoint.
class HostCalendarData {
  /// Keyed by `yyyy-MM-dd` (see [dayKey]).
  final Map<String, CalendarDay> dailyRates;

  /// Normalized blocked days.
  final Set<DateTime> blockedDates;

  /// Consecutive occupied days grouped into reservations.
  final List<CalendarBooking> bookings;

  final String currency;

  const HostCalendarData({
    required this.dailyRates,
    required this.blockedDates,
    required this.bookings,
    required this.currency,
  });
}

/// Talks to the host-calendar management endpoints. Mirrors the web
/// `host-dashboard/calendar` data flow but adapted to the app's [ApiConsumer].
///
/// Date formats (centralized here so they're trivial to adjust):
/// - `GET property-calendar` `date` param → `dd-MM-yyyy`.
/// - POST body `fromDate`/`toDate` → ISO-8601 (UTC), date-stable.
class HostCalendarManagementService {
  final ApiConsumer _api;

  HostCalendarManagementService(this._api);

  // ── Date helpers ──────────────────────────────────────────────────────────

  /// `date` query param for property-calendar → `yyyy-MM-dd` (first of month).
  /// The backend parses this as yyyy-MM-dd; sending `dd-MM-yyyy` makes it read
  /// the year as `0001`, returning data that never matches the visible month.
  static String calendarDateParam(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-${_p2(month.month)}-01';

  /// `fromDate`/`toDate` for POST bodies → `yyyy-MM-dd`. The backend rejects
  /// ISO-8601 here ("Use YYYY-MM-DD format"). Built from numeric parts so the
  /// day stays stable regardless of device timezone.
  static String postDate(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${_p2(day.month)}-${_p2(day.day)}';

  static String _p2(int n) => n.toString().padLeft(2, '0');

  // ── Endpoints ─────────────────────────────────────────────────────────────

  /// GET /api/properties/by-host?hostId=&limit=500
  Future<List<PropertyModel>> getPropertiesByHost(String hostId) async {
    try {
      final res = await _api.get(
        EndPoints.propertiesByHost,
        queryParameters: {'hostId': hostId, 'limit': 500},
      );
      return _extractList(res).map(PropertyModel.fromJson).toList();
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// GET /api/property-calendar?propertyId=&userId=&page=1&date=dd-MM-yyyy
  Future<HostCalendarData> getPropertyCalendar({
    required String propertyId,
    required String userId,
    required DateTime month,
  }) async {
    try {
      final res = await _api.get(
        EndPoints.propertyCalendar,
        queryParameters: {
          'propertyId': propertyId,
          'userId': userId,
          'page': 1,
          'date': calendarDateParam(month),
        },
      );
      return _parseCalendar(res);
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// POST /api/properties/special-price (host-scoped, matches the web).
  /// The admin-dashboard endpoint rejects host ids ("Invalid admin ID").
  Future<void> setSpecialPrice({
    required String hostId,
    required String propertyId,
    required DateTime fromDate,
    required DateTime toDate,
    required double price,
  }) async {
    try {
      await _api.post(
        EndPoints.specialPrice,
        body: {
          'hostId': hostId,
          'propertyId': propertyId,
          'fromDate': postDate(fromDate),
          'toDate': postDate(toDate),
          'price': price,
        },
      );
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// POST /api/properties/calendar/update-status
  /// `reasonId == null` unblocks; a non-null id blocks.
  Future<void> updateStatus({
    required String propertyId,
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
    int? reasonId,
    String? reasonText,
  }) async {
    try {
      await _api.post(
        EndPoints.calendarUpdateStatus,
        body: {
          'propertyId': propertyId,
          'userId': userId,
          'fromDate': postDate(fromDate),
          'toDate': postDate(toDate),
          'reasonId': reasonId,
          'reasonText': reasonText ?? '',
        },
      );
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// POST /booking-manager/minimum-days
  Future<void> setMinimumDays({
    required String propertyId,
    required String hostId,
    required int minimumDaysForBooking,
  }) async {
    try {
      await _api.post(
        EndPoints.minimumDays,
        body: {
          'propertyId': propertyId,
          'hostId': hostId,
          'minimumDaysForBooking': minimumDaysForBooking,
        },
      );
    } catch (e) {
      throw ServerException.msg(e.toString());
    }
  }

  /// GET /api/Lookups/ReasonBlockProperty — falls back to a static list.
  Future<List<BlockReason>> getBlockReasons() async {
    try {
      final res = await _api.get(EndPoints.reasonBlockPropertyLookup);
      final reasons = _extractList(res)
          .map(BlockReason.fromJson)
          .where((r) => r.name.isNotEmpty)
          .toList();
      return reasons.isEmpty ? BlockReason.fallback : reasons;
    } catch (_) {
      return BlockReason.fallback;
    }
  }

  // ── Parsing ─────────────────────────────────────────────────────────────

  HostCalendarData _parseCalendar(dynamic res) {
    String currency = '';
    if (res is Map) {
      if (res['currency'] != null) {
        currency = res['currency'].toString();
      } else if (res['data'] is Map && res['data']['currency'] != null) {
        currency = res['data']['currency'].toString();
      }
    }

    final days = _extractList(res).map(CalendarDay.fromJson).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final dailyRates = <String, CalendarDay>{};
    final blocked = <DateTime>{};
    for (final d in days) {
      dailyRates[d.key] = d;
      if (d.isBlocked) blocked.add(d.date);
      if (currency.isEmpty && (d.currency?.isNotEmpty ?? false)) {
        currency = d.currency!;
      }
    }

    return HostCalendarData(
      dailyRates: dailyRates,
      blockedDates: blocked,
      bookings: _groupBookings(days),
      currency: currency.isEmpty ? 'EGP' : currency,
    );
  }

  /// Groups consecutive occupied days (same guest + status) into reservations.
  List<CalendarBooking> _groupBookings(List<CalendarDay> sortedDays) {
    final bookings = <CalendarBooking>[];
    CalendarDay? runStart;
    CalendarDay? runEnd;

    void close() {
      if (runStart != null && runEnd != null) {
        bookings.add(CalendarBooking(
          start: runStart!.date,
          end: runEnd!.date,
          status: runStart!.status,
          guestName: runStart!.bookedByName,
        ));
      }
      runStart = null;
      runEnd = null;
    }

    for (final d in sortedDays) {
      if (!d.isBookedLike) {
        close();
        continue;
      }
      if (runStart == null) {
        runStart = d;
        runEnd = d;
      } else {
        final consecutive = d.date.difference(runEnd!.date).inDays == 1;
        final sameGuest = (runEnd!.bookedByName ?? '') == (d.bookedByName ?? '');
        final sameStatus = runEnd!.status == d.status;
        if (consecutive && sameGuest && sameStatus) {
          runEnd = d;
        } else {
          close();
          runStart = d;
          runEnd = d;
        }
      }
    }
    close();
    return bookings;
  }

  /// Flattens the various response envelopes (`List`, `{data:[...]}`,
  /// `{data:{data:[...]}}`, `{items:[...]}`) into a list of maps.
  List<Map<String, dynamic>> _extractList(dynamic res) {
    if (res == null) return [];
    if (res is List) return res.whereType<Map<String, dynamic>>().toList();
    if (res is Map) {
      final data = res['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) {
        final inner = data['data'] ?? data['items'];
        if (inner is List) {
          return inner.whereType<Map<String, dynamic>>().toList();
        }
      }
      final items = res['items'];
      if (items is List) return items.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
