class EndPoints {
  EndPoints._();

  // Base URL - Update with your actual API URL
  static const String baseUrl = 'https://api.houseiana.com/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';

  // Properties
  static const String properties = '/properties';
  static const String featuredProperties = '/properties/featured';
  static const String searchProperties = '/properties/search';
  static String propertyDetails(String id) => '/properties/$id';

  // Favorites
  static const String favorites = '/favorites';
  static String toggleFavorite(String id) => '/favorites/$id';

  // Chat
  static const String chats = '/chats';
  static String chatMessages(String chatId) => '/chats/$chatId/messages';

  // Profile
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';

  // Notifications
  static const String notifications = '/notifications';
}
