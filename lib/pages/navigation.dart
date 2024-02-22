import 'package:flutter/material.dart';
import 'package:fyp/pages/workerJob.dart';
import 'package:fyp/pages/workerPref.dart';
import 'package:fyp/pages/workerSettings.dart';

class AppNavigationBar extends StatefulWidget {
  const AppNavigationBar({super.key});

  @override
  State<AppNavigationBar> createState() => AppNavigationBarState();
}

class AppNavigationBarState extends State<AppNavigationBar> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    WorkerJob(),
    WorkerPreference(),
    WorkerSettings(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            label: 'Preferences',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
