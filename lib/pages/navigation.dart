import 'package:flutter/material.dart';
import 'package:fyp/pages/workerJob.dart';
import 'package:fyp/pages/workerPref.dart';
import 'package:fyp/pages/workerSettings.dart';

class AppNavigationBar extends StatefulWidget {
  final String worker_id;

  //const AppNavigationBar({super.key, required this.worker_id});
  const AppNavigationBar({Key? key, required this.worker_id}) : super(key: key);

  @override
  State<AppNavigationBar> createState() => AppNavigationBarState(workerId: worker_id);
}

class AppNavigationBarState extends State<AppNavigationBar> {
  final String workerId;

  AppNavigationBarState({required this.workerId});

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  static List<Widget> _widgetOptions(String workerId) => [
        WorkerJob(worker_id: workerId),
        WorkerPreference(worker_id: workerId),
        WorkerSettings(worker_id: workerId),
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
