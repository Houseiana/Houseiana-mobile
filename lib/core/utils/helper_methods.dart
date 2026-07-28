import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/enums/toast_enum.dart';

class HelperMethods {
  HelperMethods._();

  static void showToast(
    BuildContext context, {
    required String message,
    ToastEnum type = ToastEnum.info,
  }) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: type.color,
      icon: Icon(
        type.icon,
        color: AppColors.textLight,
      ),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  // `formatPrice` used to live here with a hardcoded `$` sign and no callers.
  // Money lives in `core/utils/money.dart` now — use `Money.format`.

  static String formatArea(double area) {
    return '${area.toStringAsFixed(0)} sq ft';
  }
}
