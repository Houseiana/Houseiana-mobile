import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/public_profile_model.dart';

abstract class OwnerProfileState extends Equatable {
  const OwnerProfileState();

  @override
  List<Object?> get props => [];
}

class OwnerProfileInitial extends OwnerProfileState {}

class OwnerProfileLoading extends OwnerProfileState {}

class OwnerProfileLoaded extends OwnerProfileState {
  final PublicProfileModel profile;

  const OwnerProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class OwnerProfileError extends OwnerProfileState {
  /// i18n key (e.g. 'ownerProfile.profileNotFound').
  final String messageKey;

  const OwnerProfileError(this.messageKey);

  @override
  List<Object?> get props => [messageKey];
}
