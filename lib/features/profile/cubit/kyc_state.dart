import 'package:equatable/equatable.dart';

abstract class KycState extends Equatable {
  const KycState();

  @override
  List<Object?> get props => [];
}

class KycInitial extends KycState {}

class KycInProgress extends KycState {
  final int currentStep;
  final String documentType;
  final String idNumber;
  final String? frontImagePath;
  final String? backImagePath;
  final String? selfiePath;

  const KycInProgress({
    this.currentStep = 0,
    this.documentType = 'ID Card',
    this.idNumber = '',
    this.frontImagePath,
    this.backImagePath,
    this.selfiePath,
  });

  KycInProgress copyWith({
    int? currentStep,
    String? documentType,
    String? idNumber,
    String? frontImagePath,
    String? backImagePath,
    String? selfiePath,
  }) {
    return KycInProgress(
      currentStep: currentStep ?? this.currentStep,
      documentType: documentType ?? this.documentType,
      idNumber: idNumber ?? this.idNumber,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      selfiePath: selfiePath ?? this.selfiePath,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        documentType,
        idNumber,
        frontImagePath,
        backImagePath,
        selfiePath,
      ];
}

class KycSubmitting extends KycState {}

class KycSuccess extends KycState {}

class KycError extends KycState {
  final String message;
  const KycError(this.message);

  @override
  List<Object?> get props => [message];
}
