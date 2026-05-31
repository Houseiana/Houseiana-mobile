# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Houseiana is a Flutter mobile app for holiday home rentals (Airbnb-style). It targets Android and iOS. The web companion lives in the sibling directory `../Houseiana-Holidays-Homes-main_web/`.

## Common Commands

```bash
# Run on a connected device or emulator
flutter run

# Run with environment variables (required for payment/auth integrations)
flutter run \
  --dart-define=CLERK_PUBLISHABLE_KEY=pk_xxx \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_xxx \
  --dart-define=PAYPAL_CLIENT_ID=xxx \
  --dart-define=GOOGLE_CLIENT_ID=xxx \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx

# Static analysis
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Build release APK
flutter build apk --release

# Build release iOS
flutter build ios --release
```

## Architecture

### Layer Structure

Each feature under `lib/features/<feature>/` follows this pattern:
- `presentation/screens/` — Flutter UI widgets
- `presentation/cubit/` — BLoC/Cubit state classes (`*_cubit.dart`, `*_state.dart`)
- `data/model/` — Data models (where present)

Features: `auth`, `booking`, `bottom_nav`, `chat`, `country`, `dashboard`, `favorites`, `home`, `host`, `legal`, `notifications`, `profile`, `properties`, `property_details`, `recommendations`, `search`, `splash`, `support`, `trips`

### Core Infrastructure (`lib/core/`)

- **DI**: `GetIt` service locator; global instance is `sl` from `injection_container.dart`. Each feature registers its dependencies in a dedicated `*_injection.dart` file called from `injection_container.dart#init()`.
- **Networking**: `DioConsumer` wraps Dio and implements `ApiConsumer`. All backend calls go through `EndPoints` which delegates the base URL to `AppConfig.backendApiUrl`.
- **Auth**: `ClerkService` directly calls Clerk's Frontend API (`https://clerk.houseiana.com/v1`) using form-urlencoded requests and manual cookie management for multi-step flows. The backend API requires the Clerk user ID as path/query params — it does **not** use JWT bearer tokens from this app.
- **Session**: `UserSession` persists `clerk_user_id`, `clerk_session_id`, and basic profile fields in `SharedPreferences`. Use `sl<UserSession>()` to read the current user. `isLoggedIn` is the auth gate.
- **Theme**: `AppColors` for colors (primary = `#FCC519` yellow). `AppTheme`/`light_theme`/`dark_theme` for themes. `AppSpacing`, `AppRadius`, `AppShadows` for design tokens.

### Environment Configuration

`AppConfig` in `lib/core/config/app_config.dart` controls environment:
- `development` → `http://10.0.2.2:3000/api` (Android emulator localhost)
- `staging` → Azure Container Apps staging URL
- `production` → Azure Container Apps production URL

Change `AppConfig.environment` to switch. All API keys are injected at build time via `--dart-define`.

### Routing

Named routes only. All route names are constants in `lib/core/constants/routes/routes.dart`. Route-to-screen mapping is in `AppRoutes.onGenerateRoute` (`lib/core/constants/routes/app_routes.dart`). Arguments are passed as `Map<String, dynamic>` via `settings.arguments`.

### State Management

BLoC/Cubit pattern throughout. The global `AuthCubit` is provided at the root in `app.dart`. Feature-specific cubits are provided locally by each screen or the bottom nav shell. `AppBlocObserver` logs all transitions in debug mode.

### Bottom Navigation

Five tabs (index 0–4): Home, Search/Properties, Country, Trips, Profile. Managed by `BottomNavCubit`. The Profile tab (index 4) requires authentication — accessing it unauthenticated shows a sign-in prompt instead of navigating.

### Chat & Real-time

Chat uses both Socket.IO (`socket_service.dart`) and Firebase Firestore (`cloud_firestore`). Firebase must be initialized at startup; the app gracefully continues if Firebase is not configured (no `google-services.json`).

### Payments

- **Stripe**: `StripePaymentService` — initialized with `stripePublishableKey` from `AppConfig`.
- **PayPal**: `PaypalPaymentService` — uses `paypalClientId` from `AppConfig`.
- Both keys come from `--dart-define` at build time.

### Shared Widgets (`lib/shared/widgets/`)

Reusable components outside any specific feature:
- `cards/property_card_v2.dart` — standard property listing card
- `skeletons/` — `PropertySkeletonLoader`, `ListSkeletonLoader` for loading states
- `empty_state/empty_state_widget.dart` — empty list states
- `animations/` — shared animation helpers
# Project Rules

## Objective
Align the Flutter mobile app with the web project as closely as possible in features, UX, UI spirit, flows, and API behavior.

## Hard Constraints
- Never modify the web project.
- Never suggest edits to the web project.
- All implementation must happen inside the Flutter project only.
- The web project is the product source of truth.
- Reuse the same APIs already consumed by the web project whenever possible.
- Do not start coding before producing a detailed implementation plan when asked for planning.
- Prefer maintainable architecture over hacks.
- When unsure, inspect the codebase first and state uncertainty explicitly.

## Planning Style
- Break work into phases by product section.
- Break phases into atomic tasks.
- Each task must include dependencies, files impacted, implementation steps, edge cases, and definition of done.
- Output in Arabic unless asked otherwise.

## Coding Style
- Keep changes scoped and minimal.
- Avoid unrelated refactors.
- Preserve existing API contracts.
- Reuse existing Flutter architecture where sensible, but improve weak areas if necessary.