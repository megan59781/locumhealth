import 'package:flutter/material.dart';

class WorkerJob extends StatelessWidget {
  final String worker_id;

  const WorkerJob({super.key, required this.worker_id});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Your school page content goes here
      child: const Text('Worker Jobs Appear Here'),
    );
  }
}