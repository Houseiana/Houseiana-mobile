import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

enum ToastEnum {
  success(AppColors.success, Icons.check_circle),
  error(AppColors.error, Icons.error),
  warning(AppColors.warning, Icons.warning),
  info(AppColors.info, Icons.info);

  final Color color;
  final IconData icon;

  const ToastEnum(this.color, this.icon);
}
