import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/app_strings.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart'
    as di;
import 'package:houseiana_mobile_app/core/network/api/auth_interceptor.dart';
import 'package:houseiana_mobile_app/core/theme/light_theme.dart';
import 'package:houseiana_mobile_app/core/theme/dark_theme.dart';
import 'package:houseiana_mobile_app/core/theme/theme_cubit.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_cubit.dart';

class HouseianaApp extends StatelessWidget {
  HouseianaApp({super.key});

  // Built once per process — ThemeData construction is not free and the root
  // rebuilds on every locale change.
  static final ThemeData _lightTheme = lightTheme();
  static final ThemeData _darkTheme = darkTheme();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthCubit>()),
        BlocProvider(create: (_) => di.sl<LocaleCubit>()),
        BlocProvider(create: (_) => di.sl<ThemeCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, AppLocale>(
        builder: (context, locale) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                title: AppStrings.appName,
                debugShowCheckedModeBanner: false,
                theme: _lightTheme,
                darkTheme: _darkTheme,
                themeMode: themeMode,
                // No cross-fade between themes. The default 200ms lerp would let
                // screens rebuild while the resolved brightness is still the old
                // one, so the AppColors getters below would hand out stale
                // colors with no later rebuild to correct them.
                themeAnimationDuration: Duration.zero,
                locale: Locale(locale.code),
                supportedLocales: const [
                  Locale('en'),
                  Locale('ar'),
                ],
                localizationsDelegates: const [
                  AppLocalizationsDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) {
                  // This builder sits below MaterialApp's own Theme, so
                  // `Theme.of` here is the RESOLVED theme — which is what makes
                  // ThemeMode.system work without any extra plumbing.
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;

                  // Point the palette at the matching set of tokens before any
                  // route below builds (parent-first build order).
                  AppColors.setDark(isDark);

                  // Global bottom SafeArea so the Android system navigation
                  // bar (3-button / gesture pill) never covers content on any
                  // screen, dialog, or bottom sheet. The ColoredBox provides a
                  // solid background behind the (transparent) system nav bar
                  // area so it doesn't render as a transparent gap.
                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    // The bars stay transparent in edge-to-edge mode, so only
                    // the icon brightness has to follow the theme.
                    value: (isDark
                            ? SystemUiOverlayStyle.light
                            : SystemUiOverlayStyle.dark)
                        .copyWith(
                      statusBarColor: Colors.transparent,
                      systemNavigationBarColor: Colors.transparent,
                      systemNavigationBarDividerColor: Colors.transparent,
                    ),
                    child: Directionality(
                      textDirection: locale == AppLocale.ar
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: ColoredBox(
                        color: theme.scaffoldBackgroundColor,
                        child: SafeArea(
                          top: false,
                          bottom: true,
                          maintainBottomViewPadding: true,
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  );
                },
                initialRoute: Routes.splash,
                onGenerateRoute: AppRoutes.onGenerateRoute,
              );
            },
          );
        },
      ),
    );
  }
}
