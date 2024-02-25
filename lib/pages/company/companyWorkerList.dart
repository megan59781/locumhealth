//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:intl/intl.dart';

class CompanyWorkerList extends StatefulWidget {
  final String companyId;
  final String jobId;
  const CompanyWorkerList(
      {super.key, required this.companyId, required this.jobId});

  @override
  State<CompanyWorkerList> createState() => CompanyWorkerListState();
}

class CompanyWorkerListState extends State<CompanyWorkerList> {
  List searchResult = [];

  final workerDbHandler = FirebaseDatabase.instance.ref().child("Worker");

  // calculates minuites to compare in firebase function
  int stringTimeToInt(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  void getJobData(String jobId) {
    print('MEGAN IT runs');
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

    databaseReference
        .child('Jobs')
        .orderByChild('job_id')
        .equalTo(jobId)
        .onValue
        .listen((event) {
      print('Snapshot: ${event.snapshot.value}'); // Print the entire snapshot

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          // Assuming there's only one item in the snapshot (you are querying by jobId)
          var jobKey = data.keys.first;
          var jobData = data[jobKey];

          var dateString = jobData['date'];
          // var companyId = jobData['company_id'];
          var jobStartTime = jobData['day_start_time'];
          var jobEndTime = jobData['day_end_time'];
          // var jobId = jobData['job_id'];
          // var location = jobData['location'];

          DateTime date = DateFormat('dd-MM-yyyy').parse(dateString);
          String day = DateFormat('EEEE').format(date);
          //print('day');
          int dayId = 0;
          if (day == 'Monday') {
            dayId = 1;
          } else if (day == 'Tuesday') {
            dayId = 2;
          } else if (day == 'Wednesday') {
            dayId = 3;
          } else if (day == 'Thursday') {
            dayId = 4;
          } else if (day == 'Friday') {
            dayId = 5;
          } else if (day == 'Saturday') {
            dayId = 6;
          } else if (day == 'Sunday') {
            dayId = 7;
          } else {
            // error
            print('Invalid day');
          }

          // print("MEGAN IT WORKS");
          // print("Job ID: $jobId");
          // print(dateString);
          // print("Company ID: $companyId");
          // print("Day Start Time: $dayStartTime");
          // print("Day End Time: $dayEndTime");

          matchJobToWorker(jobId, jobStartTime, jobEndTime, dayId);
        } else {
          print("MEGAN IT fails: Data is not in the expected format");
        }
      } else {
        print("MEGAN IT fails: No data found for Job ID: $jobId");
      }
    });
  }

  void matchJobToWorker(
      String jobId, String jobStart, String jobEnd, int jobDay) {}

  @override
  Widget build(BuildContext context) {
    String jobId = widget.jobId;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase Search"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Search Here",
              ),
              onChanged: (query) {},
            ),
          ),
          PushButton(
            buttonSize: 60,
            text: "test",
            onPress: () async {
              getJobData(jobId);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResult.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(searchResult[index]['number_id']),
                  subtitle: Text(searchResult[index]['string_id']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
