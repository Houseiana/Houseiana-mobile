import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/cubit.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/states.dart';
import 'package:houseiana_mobile_app/features/home/presentation/screens/home_screen.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/screens/properties_screen.dart';
import 'package:houseiana_mobile_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/screens/profile_screen.dart';

class BottomNavScreen extends StatelessWidget {
  const BottomNavScreen({super.key});

  static final List<Widget> _screens = [
    const HomeScreen(),
    const PropertiesScreen(),
    const FavoritesScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BottomNavCubit(),
      child: BlocBuilder<BottomNavCubit, BottomNavState>(
        builder: (context, state) {
          return Scaffold(
            body: _screens[state.index],
            bottomNavigationBar: CurvedNavigationBar(
              index: state.index,
              height: 60,
              color: AppColors.primaryColor,
              buttonBackgroundColor: AppColors.primaryColor,
              backgroundColor: AppColors.transparent,
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 300),
              onTap: (index) {
                context.read<BottomNavCubit>().changeIndex(index);
              },
              items: const [
                Icon(Icons.home_outlined, size: 26, color: AppColors.textLight),
                Icon(Icons.search, size: 26, color: AppColors.textLight),
                Icon(Icons.favorite_outline, size: 26, color: AppColors.textLight),
                Icon(Icons.chat_bubble_outline, size: 26, color: AppColors.textLight),
                Icon(Icons.person_outline, size: 26, color: AppColors.textLight),
              ],
            ),
          );
        },
      ),
    );
  }
}
