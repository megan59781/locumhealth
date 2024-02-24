import 'package:flutter/material.dart';

class CompanyJob extends StatelessWidget {
  final String companyId;

  const CompanyJob({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Your school page content goes here
      child: const Text('Company Jobs Appear Here'),
    );
  }
}