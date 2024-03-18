import 'package:flutter/material.dart';
import 'package:fyp/pages/worker/workerJob.dart';
import 'package:fyp/pages/worker/workerPref.dart';
import 'package:fyp/pages/worker/workerSettings.dart';

class WorkerNavigationBar extends StatefulWidget {
  final String workerId;

  const WorkerNavigationBar({super.key, required this.workerId});

  @override
  State<WorkerNavigationBar> createState() =>
      WorkerNavigationBarState(workerId: workerId);
}

class WorkerNavigationBarState extends State<WorkerNavigationBar> {
  final String workerId;

  WorkerNavigationBarState({required this.workerId});

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  static List<Widget> _widgetOptions(String workerId) => [
        WorkerJob(workerId: workerId),
        WorkerPreference(workerId: workerId),
        WorkerSettings(workerId: workerId),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    //String workerId = widget.worker_id;
    return Scaffold(
      body: Center(
        child: _widgetOptions(workerId)[_selectedIndex],
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
