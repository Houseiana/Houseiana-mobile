import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// App icon data class for consistent icon usage.
///
/// Backed by the `iconsax_plus` package — Linear variants are used for the
/// default (outlined) icons and Bold variants for the filled/active state.
/// A small number of icons fall back to Material when no close `iconsax_plus`
/// equivalent exists.
class AppIcons {
  AppIcons._();

  // Icon sizes
  static const double sizeXs = 12.0;
  static const double sizeSm = 16.0;
  static const double sizeMd = 20.0;
  static const double sizeLg = 24.0;
  static const double sizeXl = 28.0;
  static const double sizeXxl = 32.0;

  // Navigation icons
  static const IconData home = IconsaxPlusLinear.home_2;
  static const IconData homeFilled = IconsaxPlusBold.home_2;
  static const IconData search = IconsaxPlusLinear.search_normal;
  static const IconData searchOutlined = IconsaxPlusLinear.search_normal;
  static const IconData favorites = IconsaxPlusLinear.heart;
  static const IconData favoritesFilled = IconsaxPlusBold.heart;
  static const IconData trips = IconsaxPlusLinear.bag_2;
  static const IconData tripsFilled = IconsaxPlusBold.bag_2;
  static const IconData messages = IconsaxPlusLinear.message;
  static const IconData messagesFilled = IconsaxPlusBold.message;
  static const IconData profile = IconsaxPlusLinear.user;
  static const IconData profileFilled = IconsaxPlusBold.user;

  // Action icons
  static const IconData favorite = IconsaxPlusBold.heart;
  static const IconData favoriteOutline = IconsaxPlusLinear.heart;
  static const IconData share = IconsaxPlusLinear.share;
  static const IconData shareFilled = IconsaxPlusBold.share;
  static const IconData filter = IconsaxPlusLinear.filter;
  static const IconData filterOutlined = IconsaxPlusLinear.filter;
  static const IconData sort = IconsaxPlusLinear.sort;
  static const IconData sortOutlined = IconsaxPlusLinear.sort;
  static const IconData map = IconsaxPlusLinear.map;
  static const IconData mapFilled = IconsaxPlusBold.map;
  static const IconData list = IconsaxPlusLinear.menu_board;
  static const IconData grid = IconsaxPlusLinear.element_3;

  // Property icons
  static const IconData location = IconsaxPlusLinear.location;
  static const IconData locationFilled = IconsaxPlusBold.location;
  static const IconData bed = Icons.king_bed_outlined;
  static const IconData bedFilled = Icons.king_bed;
  static const IconData bathroom = Icons.bathtub_outlined;
  static const IconData bathroomFilled = Icons.bathtub;
  static const IconData guests = IconsaxPlusLinear.profile_2user;
  static const IconData guestsFilled = IconsaxPlusBold.profile_2user;
  static const IconData area = Icons.square_foot;
  static const IconData amenities = IconsaxPlusLinear.menu_board;
  static const IconData amenity = IconsaxPlusLinear.tick_circle;

  // Calendar icons
  static const IconData calendar = IconsaxPlusLinear.calendar;
  static const IconData calendarFilled = IconsaxPlusBold.calendar;
  static const IconData clock = IconsaxPlusLinear.clock;
  static const IconData clockOutlined = IconsaxPlusLinear.clock;

  // User icons
  static const IconData star = IconsaxPlusBold.star;
  static const IconData starOutline = IconsaxPlusLinear.star;
  static const IconData starHalf = Icons.star_half;
  static const IconData verified = IconsaxPlusBold.verify;
  static const IconData verifiedOutline = IconsaxPlusLinear.verify;
  static const IconData superhost = IconsaxPlusBold.crown_1;
  static const IconData superhostOutline = IconsaxPlusLinear.crown_1;

  // Security icons
  static const IconData security = IconsaxPlusLinear.security_safe;
  static const IconData lock = IconsaxPlusLinear.lock_1;
  static const IconData lockFilled = IconsaxPlusBold.lock_1;
  static const IconData shield = IconsaxPlusLinear.shield_tick;
  static const IconData shieldCheck = IconsaxPlusLinear.shield_tick;

  // Communication icons
  static const IconData phone = IconsaxPlusLinear.call;
  static const IconData phoneFilled = IconsaxPlusBold.call;
  static const IconData email = IconsaxPlusLinear.sms;
  static const IconData emailFilled = IconsaxPlusBold.sms;
  static const IconData send = IconsaxPlusBold.send_2;
  static const IconData sendOutlined = IconsaxPlusLinear.send_2;
  static const IconData chat = IconsaxPlusLinear.message_2;
  static const IconData chatFilled = IconsaxPlusBold.message_2;

  // Navigation arrows
  static const IconData back = IconsaxPlusLinear.arrow_left_2;
  static const IconData backFilled = IconsaxPlusLinear.arrow_left;
  static const IconData forward = IconsaxPlusLinear.arrow_right_3;
  static const IconData forwardFilled = IconsaxPlusLinear.arrow_right;
  static const IconData chevronRight = IconsaxPlusLinear.arrow_right_3;
  static const IconData chevronLeft = IconsaxPlusLinear.arrow_left_2;
  static const IconData chevronDown = IconsaxPlusLinear.arrow_down_1;
  static const IconData chevronUp = IconsaxPlusLinear.arrow_up_2;
  static const IconData close = IconsaxPlusLinear.close_square;
  static const IconData closeOutlined = IconsaxPlusLinear.close_square;
  static const IconData menu = IconsaxPlusLinear.menu_1;
  static const IconData moreVertical = IconsaxPlusLinear.more;
  static const IconData moreHorizontal = IconsaxPlusLinear.more_circle;

  // Status icons
  static const IconData success = IconsaxPlusBold.tick_circle;
  static const IconData successOutline = IconsaxPlusLinear.tick_circle;
  static const IconData error = IconsaxPlusBold.close_circle;
  static const IconData errorOutline = IconsaxPlusLinear.close_circle;
  static const IconData warning = IconsaxPlusBold.warning_2;
  static const IconData warningOutline = IconsaxPlusLinear.warning_2;
  static const IconData info = IconsaxPlusBold.info_circle;
  static const IconData infoOutline = IconsaxPlusLinear.info_circle;
  static const IconData help = IconsaxPlusLinear.message_question;
  static const IconData helpFilled = IconsaxPlusBold.message_question;

  // Media icons
  static const IconData camera = IconsaxPlusLinear.camera;
  static const IconData cameraFilled = IconsaxPlusBold.camera;
  static const IconData gallery = IconsaxPlusLinear.gallery;
  static const IconData galleryFilled = IconsaxPlusBold.gallery;
  static const IconData play = IconsaxPlusBold.play;
  static const IconData pause = IconsaxPlusBold.pause;
  static const IconData image = IconsaxPlusLinear.image;
  static const IconData imageFilled = IconsaxPlusBold.image;
  static const IconData imageNotSupported = Icons.image_not_supported_outlined;

  // Payment icons
  static const IconData payment = IconsaxPlusLinear.card;
  static const IconData paymentFilled = IconsaxPlusBold.card;
  static const IconData wallet = IconsaxPlusLinear.wallet;
  static const IconData walletFilled = IconsaxPlusBold.wallet;

  // Settings icons
  static const IconData settings = IconsaxPlusLinear.setting_2;
  static const IconData settingsFilled = IconsaxPlusBold.setting_2;
  static const IconData notifications = IconsaxPlusLinear.notification;
  static const IconData notificationsFilled = IconsaxPlusBold.notification;
  static const IconData notificationsOff = Icons.notifications_off_outlined;
  static const IconData language = IconsaxPlusLinear.language_circle;
  static const IconData globe = IconsaxPlusLinear.global;
  static const IconData brightness = Icons.brightness_6;

  // Social icons
  static const IconData logout = IconsaxPlusLinear.logout_1;
  static const IconData login = IconsaxPlusLinear.login_1;
  static const IconData addUser = IconsaxPlusLinear.user_add;
  static const IconData group = IconsaxPlusLinear.profile_2user;

  // Misc icons
  static const IconData refresh = IconsaxPlusLinear.refresh;
  static const IconData refreshOutlined = IconsaxPlusLinear.refresh;
  static const IconData copy = IconsaxPlusLinear.copy;
  static const IconData copyOutlined = IconsaxPlusLinear.copy;
  static const IconData download = IconsaxPlusLinear.import_1;
  static const IconData downloadOutlined = IconsaxPlusLinear.import_1;
  static const IconData upload = IconsaxPlusLinear.export_1;
  static const IconData uploadOutlined = IconsaxPlusLinear.export_1;
  static const IconData wifi = IconsaxPlusLinear.wifi;
  static const IconData wifiOff = Icons.wifi_off;
  static const IconData airplane = IconsaxPlusBold.airplane;
  static const IconData airplaneOutlined = IconsaxPlusLinear.airplane;

  // Cleaning & Safety icons
  static const IconData cleaning = IconsaxPlusBold.broom;
  static const IconData cleaningOutlined = IconsaxPlusLinear.broom;
  static const IconData sanitizer = IconsaxPlusLinear.shield_tick;
  static const IconData checkin = IconsaxPlusLinear.login_1;
  static const IconData checkout = IconsaxPlusLinear.logout_1;
  static const IconData warningAmber = IconsaxPlusBold.warning_2;
  static const IconData firstAid = Icons.medical_services;
}

/// Icon style configuration
class AppIconStyle {
  AppIconStyle._();

  static IconThemeData get defaultStyle => const IconThemeData(
        color: AppColors.charcoal,
        size: AppIcons.sizeLg,
      );

  static IconThemeData get navigationStyle => const IconThemeData(
        color: AppColors.charcoal,
        size: AppIcons.sizeMd,
      );

  static IconThemeData get actionStyle => const IconThemeData(
        color: AppColors.charcoal,
        size: AppIcons.sizeLg,
      );

  static IconThemeData get badgeStyle => const IconThemeData(
        color: AppColors.textLight,
        size: AppIcons.sizeXs,
      );

  static IconThemeData get ratingStyle => const IconThemeData(
        color: AppColors.bioYellow,
        size: AppIcons.sizeSm,
      );

  static IconThemeData get propertyCardStyle => const IconThemeData(
        color: AppColors.neutral600,
        size: AppIcons.sizeSm,
      );

  static IconThemeData get bottomNavStyle => const IconThemeData(
        color: AppColors.neutral400,
        size: AppIcons.sizeMd,
      );

  static IconThemeData get bottomNavSelectedStyle => const IconThemeData(
        color: AppColors.charcoal,
        size: AppIcons.sizeMd,
      );
}
