import 'package:flutter/material.dart';
import 'package:fyp/pages/worker/workerAbility.dart';
import 'package:fyp/pages/worker/workerJob.dart';
import 'package:fyp/pages/worker/workerPref.dart';
import 'package:fyp/pages/worker/workerProfile.dart';
import 'package:fyp/pages/worker/workerSettings.dart';

// Define WorkerNavigationBar widget
class WorkerNavigationBar extends StatefulWidget {
  final String workerId;
  final int setIndex;

  const WorkerNavigationBar(
      {super.key, required this.workerId, required this.setIndex});

  @override
  State<WorkerNavigationBar> createState() =>
      WorkerNavigationBarState(workerId: workerId, setIndex: setIndex);
}

class WorkerNavigationBarState extends State<WorkerNavigationBar> {
  final String workerId;
  final int setIndex;

  // Constructor
  WorkerNavigationBarState({required this.workerId, required this.setIndex}) {
    _selectedIndex = setIndex;
  }

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  // Page widget options
  static List<Widget> _widgetOptions(String workerId) => [
        WorkerJob(workerId: workerId),
        WorkerPreference(workerId: workerId),
        WorkerAbility(workerId: workerId),
        WorkerProfile(workerId: workerId),
        WorkerSettings(workerId: workerId),
      ];

  // It updates the selected index and triggers a rebuild of the widget.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build the Scaffold widget
    return Scaffold(
      body: Center(
        child: _widgetOptions(workerId)[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs', //WorkerJob
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Availability', //WorkerPreference
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_outlined),
            label: 'Abilities', //WorkerAbility
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile', //WorkerProfile
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings', //WorkerSettings
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
