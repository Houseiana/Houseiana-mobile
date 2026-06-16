import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/theme/app_icons.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/cubit.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/states.dart';
import 'package:houseiana_mobile_app/features/home/presentation/screens/home_screen.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/screens/properties_screen.dart';
import 'package:houseiana_mobile_app/features/country/presentation/screens/country_screen.dart';
import 'package:houseiana_mobile_app/features/trips/presentation/screens/trips_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  final _session = sl<UserSession>();

  static const List<Widget> _screens = [
    HomeScreen(),
    PropertiesScreen(),
    CountryScreen(),
    TripsScreen(),
    ProfileScreen(),
  ];

  List<Widget> get _allScreens =>
      _session.isHost ? [..._screens, const SizedBox.shrink()] : _screens;

  void _onTabTap(BuildContext ctx, int index) {
    final screenCount = _session.isHost ? 6 : 5;
    if (index == 5 && _session.isHost) {
      Navigator.pushNamed(ctx, Routes.hostDashboard);
      return;
    }
    if (index >= screenCount) return;
    // The Profile tab is reachable by guests too — it renders a sign-in CTA
    // and only the no-auth items (language, legal, support) when logged out.
    ctx.read<BottomNavCubit>().changeIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BottomNavCubit(),
      child: BlocBuilder<BottomNavCubit, BottomNavState>(
        builder: (ctx, state) {
          return Scaffold(
            body: _allScreens[state.index.clamp(0, _allScreens.length - 1)],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              // SafeArea ensures system nav buttons never overlap the bar
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 68,
                  child: BottomNavigationBar(
                    currentIndex: state.index,
                    onTap: (index) => _onTabTap(ctx, index),
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.white,
                    selectedItemColor: AppColors.primaryColor,
                    unselectedItemColor: const Color(0xFF9CA3AF),
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    elevation: 0,
                    iconSize: 28,
                    items: _buildNavItems(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    final items = <BottomNavigationBarItem>[
      _navItem(AppIcons.home, AppIcons.homeFilled, context.tr('bottomNav.home')),
      _navItem(AppIcons.search, AppIcons.search, context.tr('bottomNav.search')),
      _navItem(AppIcons.globe, AppIcons.globe, context.tr('bottomNav.country')),
      _navItem(AppIcons.trips, AppIcons.tripsFilled, context.tr('bottomNav.trips')),
      _navItem(AppIcons.profile, AppIcons.profileFilled, context.tr('bottomNav.profile')),
    ];
    if (_session.isHost) {
      items.add(_navItem(
          AppIcons.superhostOutline, AppIcons.superhost, context.tr('bottomNav.host')));
    }
    return items;
  }

  BottomNavigationBarItem _navItem(
      IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(icon, size: 28),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(activeIcon, size: 28),
      ),
      label: label,
    );
  }
}
