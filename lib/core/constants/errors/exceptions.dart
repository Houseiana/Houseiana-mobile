import 'package:houseiana_mobile_app/core/constants/errors/exception_model.dart';

class ServerException implements Exception {
  final ExceptionModel exceptionModel;

  const ServerException({required this.exceptionModel});

  factory ServerException.msg(String msg) => ServerException(
        exceptionModel: ExceptionModel(statusCode: 0, message: msg),
      );

  String get message => exceptionModel.message;
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});
}
