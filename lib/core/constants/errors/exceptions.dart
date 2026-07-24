import 'package:houseiana_mobile_app/core/constants/errors/exception_model.dart';
import 'package:houseiana_mobile_app/core/network/api/status_code.dart';

class ServerException implements Exception {
  final ExceptionModel exceptionModel;

  const ServerException({required this.exceptionModel});

  factory ServerException.msg(String msg) => ServerException(
        exceptionModel: ExceptionModel(statusCode: 0, message: msg),
      );

  String get message => exceptionModel.message;

  // Many call sites interpolate the caught error straight into a user-facing
  // string ('Failed …: $e'); without this the user sees
  // "Instance of 'ServerException'" instead of the backend's actual reason.
  @override
  String toString() => exceptionModel.message;
}

/// Thrown when a request was aborted via a `CancelToken` (screen disposed or
/// a newer query superseded it). Subclasses [ServerException] so untouched
/// call sites keep working; opt-in callers catch this type and return
/// silently instead of surfacing an error state to the user.
class RequestCancelledException extends ServerException {
  const RequestCancelledException()
      : super(
          exceptionModel: const ExceptionModel(
            statusCode: 0,
            message: 'Request cancelled',
          ),
        );
}

/// Translation key explaining why a load failed, for retry/error states.
///
/// A timeout gets its own copy: the backend cold-starts (see `backend_dio.dart`),
/// so it is a *slow* failure rather than a broken one and "try again" genuinely
/// works — telling the user the server is being slow beats a generic error.
/// Callers render it with `context.tr(...)`.
String loadErrorKeyFor(Object error) {
  if (error is ServerException &&
      error.exceptionModel.statusCode == StatusCode.requestTimeout) {
    return 'common.slowServer';
  }
  return 'common.loadFailed';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});

  @override
  String toString() => message;
}
