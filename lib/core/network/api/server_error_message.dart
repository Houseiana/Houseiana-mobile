/// Derives a human-readable message from an HTTP error response body, or
/// null when the body carries no usable text.
///
/// Shared by [DioConsumer] and the services that run their own raw Dio
/// (e.g. HostService), so every layer surfaces the same backend reason.
/// Handles the shapes the backend actually produces:
/// - `{message: ...}` / `{error: ...}` — plain API errors
/// - ASP.NET ValidationProblemDetails — the per-field `errors` map carries
///   the real reason (e.g. "Beds must not exceed MaxGuests"), while `title`
///   is just "One or more validation errors occurred." — prefer the specific
///   text, then `detail`, and `title` only as a last resort
/// - a bare string body
String? serverErrorMessageFromBody(dynamic data) {
  if (data is Map) {
    final msg = data['message'] ?? data['error'];
    if (msg != null && msg.toString().trim().isNotEmpty) {
      return msg.toString();
    }
    final fieldErrors = _flattenFieldErrors(data['errors']);
    if (fieldErrors != null) return fieldErrors;
    final fallback = data['detail'] ?? data['title'];
    if (fallback != null && fallback.toString().trim().isNotEmpty) {
      return fallback.toString();
    }
  } else if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  return null;
}

/// Joins a ValidationProblemDetails `errors` map — `{field: [msg, ...]}` —
/// into a single readable line, or returns null when absent/empty.
String? _flattenFieldErrors(dynamic errors) {
  if (errors is! Map) return null;
  final messages = <String>[];
  for (final value in errors.values) {
    if (value is List) {
      messages.addAll(
          value.map((m) => m.toString().trim()).where((m) => m.isNotEmpty));
    } else if (value != null && value.toString().trim().isNotEmpty) {
      messages.add(value.toString().trim());
    }
  }
  if (messages.isEmpty) return null;
  return messages.join('\n');
}
