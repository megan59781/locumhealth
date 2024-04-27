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
  final int setIndex;

  CompanyNavigationBarState({required this.companyId, required this.setIndex}) {
    _selectedIndex = setIndex;
  }

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  static List<Widget> _widgetOptions(String companyId) => [
        CompanyJob(companyId: companyId),
        CompanyCreateJob(companyId: companyId),
        CompanyProfile(companyId: companyId),
        CompanySettings(companyId: companyId),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    //String CompanyId = widget.Company_id;
    return Scaffold(
      body: Center(
        child: _widgetOptions(companyId)[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_business_outlined),
            label: 'Create Job',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
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
