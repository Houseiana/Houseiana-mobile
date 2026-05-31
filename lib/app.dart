import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:houseiana_mobile_app/core/constants/app_strings.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart'
    as di;
import 'package:houseiana_mobile_app/core/network/api/auth_interceptor.dart';
import 'package:houseiana_mobile_app/core/theme/light_theme.dart';
import 'package:houseiana_mobile_app/core/theme/dark_theme.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_cubit.dart';

class HouseianaApp extends StatelessWidget {
  const HouseianaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthCubit>()),
        BlocProvider(create: (_) => di.sl<LocaleCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, AppLocale>(
        builder: (context, locale) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: lightTheme(),
            darkTheme: darkTheme(),
            themeMode: ThemeMode.light,
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
              // Global bottom SafeArea so the Android system navigation
              // bar (3-button / gesture pill) never covers content on any
              // screen, dialog, or bottom sheet. The ColoredBox provides a
              // solid background behind the (transparent) system nav bar
              // area so it doesn't render as a transparent gap.
              return Directionality(
                textDirection:
                    locale == AppLocale.ar ? TextDirection.rtl : TextDirection.ltr,
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: SafeArea(
                    top: false,
                    bottom: true,
                    maintainBottomViewPadding: true,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
            initialRoute: Routes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
