import 'package:flutter/material.dart';

extension MediaQueryExtension on BuildContext {
  double get topPadding => MediaQuery.of(this).padding.top;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  double get viewInsetsBottom => MediaQuery.of(this).viewInsets.bottom;
  Orientation get orientation => MediaQuery.of(this).orientation;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;
}
