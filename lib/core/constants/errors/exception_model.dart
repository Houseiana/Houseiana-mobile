import 'package:equatable/equatable.dart';

class ExceptionModel extends Equatable {
  final int statusCode;
  final String message;

  const ExceptionModel({
    required this.statusCode,
    required this.message,
  });

  factory ExceptionModel.fromJson(Map<String, dynamic> json) {
    return ExceptionModel(
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String? ?? 'Unknown error',
    );
  }

  @override
  List<Object?> get props => [statusCode, message];
}
