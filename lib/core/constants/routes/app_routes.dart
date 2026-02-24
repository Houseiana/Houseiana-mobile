part of 'routes.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return _buildRoute(
          const SplashScreen(),
          settings,
        );
      case Routes.login:
        return _buildRoute(
          const LoginScreen(),
          settings,
        );
      case Routes.signUp:
        return _buildRoute(
          const SignUpScreen(),
          settings,
        );
      case Routes.bottomNav:
        return _buildRoute(
          const BottomNavScreen(),
          settings,
        );
      case Routes.propertyDetails:
        return _buildRoute(
          const PropertyDetailsScreen(),
          settings,
        );
      case Routes.searchProperties:
        return _buildRoute(
          const SearchPropertiesScreen(),
          settings,
        );
      case Routes.notifications:
        return _buildRoute(
          const NotificationsScreen(),
          settings,
        );
      default:
        return _buildRoute(
          const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
