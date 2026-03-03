class ClerkConfig {
  ClerkConfig._();

  // Clerk API Keys
  // NOTE: secretKey must NEVER be committed — keep it server-side only.
  static const String publishableKey = 'pk_live_Y2xlcmsuaG91c2VpYW5hLmNvbSQ';
  static const String secretKey = '';

  // Clerk Frontend API Base URL (decoded from publishable key: clerk.houseiana.com$)
  static const String frontendApiUrl = 'https://clerk.houseiana.com';

  // Clerk Backend API Base URL (for server-side operations only)
  static const String backendApiUrl = 'https://api.clerk.com/v1';
}
