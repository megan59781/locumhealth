import 'package:flutter/material.dart';
import 'package:fyp/pages/Company/CompanyJob.dart';
import 'package:fyp/pages/Company/CompanySettings.dart';
import 'package:fyp/pages/company/companyCreate.dart';
import 'package:fyp/pages/company/companyProfile.dart';

class CompanyNavigationBar extends StatefulWidget {
  final String companyId;
  final int setIndex;

  const CompanyNavigationBar(
      {super.key, required this.companyId, required this.setIndex});

  @override
  State<CompanyNavigationBar> createState() =>
      CompanyNavigationBarState(companyId: companyId, setIndex: setIndex);
}

class CompanyNavigationBarState extends State<CompanyNavigationBar> {
  final String companyId;
  final int setIndex; // index of the page to be displayed when passed through

  CompanyNavigationBarState({required this.companyId, required this.setIndex}) {
    _selectedIndex = setIndex;
  }

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  // List of widgets to be displayed in the bottom navigation bar
  static List<Widget> _widgetOptions(String companyId) => [
        CompanyJob(companyId: companyId),
        CompanyCreateJob(companyId: companyId),
        CompanyProfile(companyId: companyId),
        CompanySettings(companyId: companyId),
      ];

  // Function to change the index of the page to be displayed
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions(companyId)[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs', // CompanyJob
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_business_outlined),
            label: 'Create Job', // CompanyCreateJob
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile', // CompanyProfile
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings', // CompanySettings
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple, // purple when selected
        onTap: _onItemTapped, // function to change the index
      ),
    );
  }
}
