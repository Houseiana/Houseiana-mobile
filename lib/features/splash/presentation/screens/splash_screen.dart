import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:houseiana_mobile_app/core/constants/app_assets.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:houseiana_mobile_app/features/splash/presentation/cubit/splash_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SplashCubit>()..checkAppVersion(),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _dotsFade;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));
    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeIn),
      ),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _contentController.forward();
  }

  void _onGetStarted() {
    Navigator.of(context).pushReplacementNamed(Routes.bottomNav);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        if (state is SplashForceUpdate) {
          Navigator.of(context).pushReplacementNamed(
            Routes.forceUpdate,
            arguments: {'updateUrl': state.updateUrl},
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.charcoal,
        body: Stack(
          children: [
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 150,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3140),
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),

            Center(
              child: BlocBuilder<SplashCubit, SplashState>(
                builder: (context, state) {
                  return _ContentView(
                    logoFade: _logoFade,
                    logoScale: _logoScale,
                    titleSlide: _titleSlide,
                    titleFade: _titleFade,
                    dotsFade: _dotsFade,
                    buttonSlide: _buttonSlide,
                    buttonFade: _buttonFade,
                    onGetStarted: _onGetStarted,
                    showGetStarted: state is SplashReady,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentView extends StatelessWidget {
  final Animation<double> logoFade;
  final Animation<double> logoScale;
  final Animation<Offset> titleSlide;
  final Animation<double> titleFade;
  final Animation<double> dotsFade;
  final Animation<Offset> buttonSlide;
  final Animation<double> buttonFade;
  final VoidCallback onGetStarted;
  final bool showGetStarted;

  const _ContentView({
    required this.logoFade,
    required this.logoScale,
    required this.titleSlide,
    required this.titleFade,
    required this.dotsFade,
    required this.buttonSlide,
    required this.buttonFade,
    required this.onGetStarted,
    required this.showGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: logoFade,
          child: ScaleTransition(
            scale: logoScale,
            child: Image.asset(
              AppAssets.logoIcon,
              width: 80,
              height: 112,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SlideTransition(
          position: titleSlide,
          child: FadeTransition(
            opacity: titleFade,
            child: Column(
              children: [
                Text(
                  context.tr('splash.appName'),
                  style: GoogleFonts.readexPro(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('splash.tagline'),
                  style: GoogleFonts.readexPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.neutral400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 60),
        FadeTransition(
          opacity: dotsFade,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(active: true),
              const SizedBox(width: 8),
              _dot(),
              const SizedBox(width: 8),
              _dot(),
              const SizedBox(width: 8),
              _dot(),
            ],
          ),
        ),
        const SizedBox(height: 40),
        if (showGetStarted)
          SlideTransition(
            position: buttonSlide,
            child: FadeTransition(
              opacity: buttonFade,
              child: GestureDetector(
                onTap: onGetStarted,
                child: Container(
                  width: 260,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.bioYellow,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.tr('splash.getStarted'),
                    style: GoogleFonts.readexPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const SizedBox(
            width: 260,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.bioYellow),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dot({bool active = false}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.bioYellow : AppColors.neutral600,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

