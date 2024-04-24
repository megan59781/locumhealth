import 'package:flutter/material.dart';
import 'package:fyp/pages/worker/workerAbility.dart';
import 'package:fyp/pages/worker/workerJob.dart';
import 'package:fyp/pages/worker/workerPref.dart';
import 'package:fyp/pages/worker/workerProfile.dart';
import 'package:fyp/pages/worker/workerSettings.dart';

// Define WorkerNavigationBar widget
class WorkerNavigationBar extends StatefulWidget {
  final String workerId;

  const WorkerNavigationBar({super.key, required this.workerId});

  @override
  State<WorkerNavigationBar> createState() =>
      WorkerNavigationBarState(workerId: workerId);
}

// Define WorkerNavigationBarState widget
/// The state class for the WorkerNavigationBar widget.
/// It manages the state of the bottom navigation bar and the corresponding content.
class WorkerNavigationBarState extends State<WorkerNavigationBar> {
  final String workerId;

  /// Constructs a new instance of WorkerNavigationBarState.
  /// The [workerId] parameter is required and represents the ID of the worker.
  WorkerNavigationBarState({required this.workerId});

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  /// A list of widget options to be displayed in the bottom navigation bar.
  /// Each option corresponds to a different page in the app.
  static List<Widget> _widgetOptions(String workerId) => [
        WorkerJob(workerId: workerId),
        WorkerPreference(workerId: workerId),
        WorkerAbility(workerId: workerId),
        WorkerProfile(workerId: workerId),
        WorkerSettings(workerId: workerId),
      ];

  /// Callback function that is called when a bottom navigation bar item is tapped.
  /// It updates the selected index and triggers a rebuild of the widget.
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
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            label: 'Preferences',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_outlined),
            label: 'Abilities',
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
