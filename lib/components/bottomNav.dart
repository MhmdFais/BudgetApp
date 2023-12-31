import 'package:budgettrack/pages/expenceAndIncome.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../pages/Profile.dart';
import '../pages/goals.dart';
import '../pages/homePage.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int currentIndex = 0;

  List<Widget> pages = [
    const HomePage(),
    Expence(
      //notificationList: [],
      nume: 0,
      //onDeleteNotification: (index) => {},
    ),
    const Goals(),
    Check(),
  ];

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: 8,
                activeColor: Color.fromARGB(255, 25, 86, 143),
                iconSize: 24,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                duration: Duration(milliseconds: 400),
                tabBackgroundColor: Colors.grey[300]!,
                color: Colors.blueGrey,
                tabs: const [
                  GButton(
                    icon: Icons.home,
                    text: 'Home',
                  ),
                  GButton(
                    icon: Icons.track_changes_rounded,
                    text: 'Goals',
                  ),
                  GButton(
                    icon: Icons.document_scanner_outlined,
                    text: 'Scan',
                  ),
                ],
                selectedIndex: currentIndex,
                onTabChange: onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
