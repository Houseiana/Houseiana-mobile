/// Digging the id a REVIEW is addressed by out of a booking row.
///
/// Reviews are keyed by the stay, never by the booking:
///   * hotel    → `POST /api/hotels/{hotelId}/reviews/create`
///   * property → `POST /api/ratings/property-by-guest` (body `propertyId`)
///
/// Both ids have to come off `GET /users/{userId}/user-trips` (or
/// `GET /booking-manager/{id}`), which is generic over stay kinds and was
/// never verified against a hotel row. A real past hotel stay came back
/// flagged as a hotel — the card renders the "Hotel" pill, the title and the
/// cover photo — while carrying neither `hotelId` nor `hotel.id`, which is
/// what dead-ended the review button on "This hotel is no longer available."
library;

/// Keys seen or plausible for the HOTEL entity id itself.
const List<String> _hotelIdKeys = <String>[
  'hotelId',
  'hotel_id',
  'hotelID',
  'hotelid',
  'hotelGuid',
  'hotelUuid',
];

/// Keys under which the hotel may arrive as a nested object.
const List<String> _hotelObjectKeys = <String>[
  'hotel',
  'hotelDetails',
  'hotelInfo',
  'hotelSummary',
];

/// A key naming the BOOKING, a ROOM, a RATE PLAN or a REVIEW is not the hotel.
/// Posting a booking id to the reviews path would 404 at best, so the pattern
/// scan below has to refuse them explicitly.
bool _namesSomethingElse(String key) {
  final k = key.toLowerCase();
  return k.contains('booking') ||
      k.contains('room') ||
      k.contains('rate') ||
      k.contains('plan') ||
      k.contains('review') ||
      k.contains('guest') ||
      k.contains('user');
}

/// Normalizes an id: ints, strings and the literal `"null"` all arrive here.
String _cleanId(dynamic value) {
  final s = value?.toString().trim() ?? '';
  if (s.isEmpty || s.toLowerCase() == 'null' || s == '0') return '';
  return s;
}

/// Best-effort HOTEL id for [json]; empty when the row carries none.
///
/// Order matters — the surest keys first, the pattern scan last — because a
/// wrong id here is a review posted against the wrong entity.
String extractHotelId(Map<String, dynamic> json) {
  for (final key in _hotelIdKeys) {
    final value = _cleanId(json[key]);
    if (value.isNotEmpty) return value;
  }

  for (final key in _hotelObjectKeys) {
    final nested = json[key];
    if (nested is Map) {
      for (final inner in const ['id', 'hotelId', '_id', 'hotelID']) {
        final value = _cleanId(nested[inner]);
        if (value.isNotEmpty) return value;
      }
    }
  }

  // Anything else shaped like a hotel id, e.g. a future `hotelEntityId`.
  for (final entry in json.entries) {
    final key = entry.key.toLowerCase();
    if (!key.contains('hotel') || !key.endsWith('id')) continue;
    if (_namesSomethingElse(entry.key)) continue;
    final value = _cleanId(entry.value);
    if (value.isNotEmpty) return value;
  }

  // Last: a nested object of any name that carries the hotel id itself
  // (e.g. `hotelBooking: { hotelId }` — the wrapper names the booking, the
  // key inside still names the hotel).
  for (final entry in json.entries) {
    final nested = entry.value;
    if (nested is! Map) continue;
    for (final key in _hotelIdKeys) {
      final value = _cleanId(nested[key]);
      if (value.isNotEmpty) return value;
    }
  }

  return '';
}
