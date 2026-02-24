import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/screens/login_screen.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/screen/bottom_nav.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/property_details_screen.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/screens/search_properties_screen.dart';
import 'package:houseiana_mobile_app/features/notifications/presentation/screens/notifications_screen.dart';

part 'app_routes.dart';

class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String bottomNav = '/bottom-nav';
  static const String home = '/home';
  static const String properties = '/properties';
  static const String searchProperties = '/search-properties';
  static const String propertyDetails = '/property-details';
  static const String favorites = '/favorites';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
}
