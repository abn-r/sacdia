import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/home/presentation/screens/home_screen.dart';
import 'package:sacdia/features/activities/presentation/screens/activities_screen.dart';
import 'package:sacdia/features/profile/presentation/screens/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  late MotionTabBarController _tabBarController;
  int _selectedIndex = 1; // Inicio por defecto

  @override
  void initState() {
    super.initState();
    _tabBarController = MotionTabBarController(
      initialIndex: _selectedIndex,
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabBarController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const ActivitiesScreen(),
          const HomeScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: MotionTabBar(
        controller: _tabBarController,
        initialSelectedTab: "Inicio",
        labels: const ["Actividades", "Inicio", "Perfil"],
        icons: const [
          Icons.calendar_today,
          Icons.home,
          Icons.person,
        ],
        tabSize: 50,
        tabBarHeight: 54,
        textStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabIconColor: Colors.black54,
        tabIconSize: 25,
        tabIconSelectedSize: 25,
        tabSelectedColor: sacRed,
        tabIconSelectedColor: Colors.white,
        tabBarColor: Colors.white,
        onTabItemSelected: (int value) {
          setState(() {
            _selectedIndex = value;
            _tabBarController.index = value;
          });
        },
      ),
    );
  }
}
