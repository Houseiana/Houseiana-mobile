import 'package:houseiana_mobile_app/core/constants/errors/exception_model.dart';

class ServerException implements Exception {
  final ExceptionModel exceptionModel;

  const ServerException({required this.exceptionModel});

  factory ServerException.msg(String msg) => ServerException(
        exceptionModel: ExceptionModel(statusCode: 0, message: msg),
      );

  String get message => exceptionModel.message;
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

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});
}
