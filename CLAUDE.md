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

Features: `auth`, `booking`, `bottom_nav`, `chat`, `country`, `dashboard`, `demo`, `discover`, `favorites`, `home`, `host`, `legal`, `messages`, `notifications`, `profile`, `properties`, `property_details`, `recommendations`, `search`, `splash`, `support`, `trips`

### Core Infrastructure (`lib/core/`)

- **DI**: `GetIt` service locator; global instance is `sl` from `lib/core/injection/injection_container.dart`. Each feature registers its dependencies in a dedicated `*_injection.dart` file (all under `lib/core/injection/`) called from `injection_container.dart#init()`.
- **Networking**: `DioConsumer` wraps Dio and implements `ApiConsumer`. All backend calls go through `EndPoints` which delegates the base URL to `AppConfig.backendApiUrl`. Two request interceptors run on every call: `AuthInterceptor` (Bearer token + 401 refresh, below) and `LangInterceptor` (adds a `lang: ar|en` header on all requests so the backend returns localized data — mirrors the web client).
- **Auth**: `ClerkService` directly calls Clerk's Frontend API (`https://clerk.houseiana.com/v1`) using form-urlencoded requests and manual cookie management (persisted `__client` cookie) for multi-step flows. The production backend **requires a valid Clerk session JWT** as `Authorization: Bearer <token>`; many endpoints also take the Clerk user ID as path/query params. `AuthInterceptor` (`lib/core/network/api/auth_interceptor.dart`) attaches the token from `UserSession.authToken`, and on a `401` mints a fresh session JWT via `ClerkService.getSessionToken(sessionId)` (deduped across concurrent 401s), retries the request on a bare Dio, and only forces logout (`pushNamedAndRemoveUntil(Routes.login)` via the global `navigatorKey`) if the session is genuinely dead.
- **Session**: `UserSession` persists `clerk_user_id`, `clerk_session_id`, `authToken`, and basic profile fields in `SharedPreferences`. Use `sl<UserSession>()` to read the current user. `isLoggedIn` is the auth gate.
- **Theme**: `AppColors` for colors (primary = `#FCC519` yellow). `light_theme`/`dark_theme` build the two `ThemeData` objects; `ThemeCubit` (`lib/core/theme/theme_cubit.dart`) drives `MaterialApp.themeMode` and persists the choice. `AppSpacing`, `AppRadius`, `AppShadows` for design tokens.
- **Dark mode**: surface/text/neutral tokens on `AppColors` are brightness-aware getters backed by `AppColorsLight`/`AppColorsDark`; a static flag is set from `MaterialApp.builder`. Brand/status colors (`primaryColor`, `brandCharcoal`, `success`, `error`, …) stay `const` and never flip. Never reference `AppColors.<getter>` inside a `const` expression, and never use `const` when instantiating an app widget (it would skip the rebuild on theme switch).

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

### Localization (i18n)

Custom JSON-based i18n in `lib/i18n/` (not ARB/gen-l10n). Supported locales: `en`, `ar`. Translations live in `lib/i18n/translations/{en,ar}.json`; `AppLocalizations` loads them and exposes `tr(key, {args})`. Read strings via the `BuildContext` extension: `context.tr('auth.signIn')`. Missing keys pass through unchanged, so cubits/services can store a **translation key** as their message and the UI wraps it in `context.tr` at render time. `LocaleCubit` holds the active `AppLocale` (persisted under the `app_locale` SharedPreferences key), and `HouseianaApp` applies `TextDirection.rtl` for Arabic. When adding user-facing text, add the key to **both** JSON files.

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