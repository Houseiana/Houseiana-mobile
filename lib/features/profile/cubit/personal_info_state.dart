import 'package:equatable/equatable.dart';
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

  const PersonalInfoLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class PersonalInfoSaving extends PersonalInfoState {}

class PersonalInfoSaved extends PersonalInfoState {
  final UserModel user;

  const PersonalInfoSaved(this.user);

  @override
  List<Object?> get props => [user];
}

class PersonalInfoError extends PersonalInfoState {
  final String message;

  const PersonalInfoError(this.message);

  @override
  List<Object?> get props => [message];
}
