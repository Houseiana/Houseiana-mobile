import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashLoading extends SplashState {
  const SplashLoading();
}

class SplashReady extends SplashState {
  const SplashReady();
}

class SplashForceUpdate extends SplashState {
  final String updateUrl;

  const SplashForceUpdate(this.updateUrl);

  @override
  List<Object?> get props => [updateUrl];
}
