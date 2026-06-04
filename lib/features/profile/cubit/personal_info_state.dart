import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/gender_option.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';

abstract class PersonalInfoState extends Equatable {
  const PersonalInfoState();

  @override
  List<Object?> get props => [];
}

class PersonalInfoInitial extends PersonalInfoState {}

class PersonalInfoLoading extends PersonalInfoState {}

class PersonalInfoLoaded extends PersonalInfoState {
  final UserModel user;
  final List<GenderOption> genderOptions;

  const PersonalInfoLoaded(this.user, this.genderOptions);

  @override
  List<Object?> get props => [user, genderOptions];
}

class PersonalInfoSaving extends PersonalInfoState {}

class PersonalInfoSaved extends PersonalInfoState {
  final UserModel user;
  final List<GenderOption> genderOptions;

  const PersonalInfoSaved(this.user, this.genderOptions);

  @override
  List<Object?> get props => [user, genderOptions];
}

class PersonalInfoError extends PersonalInfoState {
  final String message;

  const PersonalInfoError(this.message);

  @override
  List<Object?> get props => [message];
}
