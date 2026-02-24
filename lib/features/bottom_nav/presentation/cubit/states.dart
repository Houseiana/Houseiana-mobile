import 'package:equatable/equatable.dart';

class BottomNavState extends Equatable {
  final int index;

  const BottomNavState({required this.index});

  @override
  List<Object?> get props => [index];
}
