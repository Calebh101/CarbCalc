import 'package:flutter/material.dart';

import 'package:carbcalc/pages/homescreen.dart';
import 'package:carbcalc/pages/settingscreen.dart';
import 'package:flutter/rendering.dart';
import 'package:quick_navbar/quick_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localpkg/theme.dart';

late Future<Map<String, dynamic>> cache;

void main() {
  debugPaintSizeEnabled = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> saveData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  Future<String?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (await testData(key)) {
      return prefs.getString(key);
    } else {
      return null;
    }
  }

  Future<bool> testData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CarbCalc',
      theme: customTheme(darkMode: false, seedColor: Colors.orange),
      darkTheme: customTheme(darkMode: false, seedColor: Colors.orange),
      themeMode: ThemeMode.system,
      home: QuickNavBar(items: [
        {
          "label": "Home",
          "icon": Icons.home,
          "widget": HomeScreen(),
        },
        {
          "label": "Settings",
          "icon": Icons.settings,
          "widget": SettingsScreen(),
        },
      ], selectedColor: Colors.orange, sidebarBeta: true),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    HomeScreen(),
    //FoodsScreen(),
    SettingsScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          /*BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            activeIcon: Icon(Icons.restaurant),
            label: 'Foods',
          ),*/
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],

        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange[800],
        onTap: _onItemTapped,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}