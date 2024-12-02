import 'package:carrier/Screens/home/HomePageState.dart';
import 'package:carrier/Screens/identity/LoginPageState.dart';
import 'package:carrier/Screens/lib/custom_bottom_navigation_bar.dart';
import 'package:carrier/Screens/page/proposal_details.dart';
import 'package:carrier/Screens/page/search_page.dart';
import 'package:carrier/Screens/page/waiting_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          final prefs = snapshot.data;
          final token = prefs?.getString('token');
          if (token != null) {
            return SearchPage();
          } else {
            return LoginPage();
          }
        }
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    SearchPage(),
    WaitingPage(),
    ProposalPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}