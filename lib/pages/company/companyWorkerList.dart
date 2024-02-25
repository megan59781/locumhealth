import 'dart:math' show cos, sqrt, asin;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';
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
  List<dynamic> workerList = [];
  DatabaseReference dbHandler = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    String jobId = widget.jobId;
    getAvailablWorkers(jobId, (List<dynamic> availWorkerList) {
      setState(() {
        workerList = availWorkerList;
      });
    });
  }

  // calculates minuites to compare in firebase function
  int stringTimeToMins(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  // Haversine formula to calculate distnace bewteen 2 points
  double calculateDistance(lat1, lon1, lat2, lon2) {
    double haversine(lat1, lon1, lat2, lon2) {
      var p = 0.017453292519943295;
      var c = cos;
      var a = 0.5 -
          c((lat2 - lat1) * p) / 2 +
          c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
      return 12742 * asin(sqrt(a));
    }

    return haversine(lat1, lon1, lat2, lon2);
  }

  void getAvailablWorkers(
      String jobId, Function(List<dynamic> workerList) getList) {
    print("Megan this is lat long calc");
    print(calculateDistance(50.78770, 1.084350, 50.798870, 0.988060));

    dbHandler
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
          dbHandler
              .child('Availability')
              .orderByChild('day_id')
              .equalTo(dayId)
              .onValue
              .listen((DatabaseEvent event) {
            if (event.snapshot.value != null) {
              // Explicitly cast to Map<dynamic, dynamic>
              Map<dynamic, dynamic>? data =
                  event.snapshot.value as Map<dynamic, dynamic>?;

              if (data != null) {
                // Convert the Map<dynamic, dynamic> to a List
                List<dynamic> availWorkerList = [];
                data.forEach((key, value) {
                  int availStartTime =
                      stringTimeToMins(value['day_start_time']);
                  int availEndTime = stringTimeToMins(value['day_end_time']);

                  if ((availStartTime <= stringTimeToMins(jobStartTime)) &&
                      (availEndTime >= stringTimeToMins(jobEndTime))) {
                    String workerId = value['worker_id'];
                    int miles = value['miles'];
                    availWorkerList.add([workerId, miles]);
                  }
                });

                // Now you have a list of jobs
                print('Worker List: $availWorkerList');

                for (List<dynamic> worker in availWorkerList) {
                  String workerId = worker[0];
                  dbHandler
                      .child('Worker')
                      .orderByChild('worker_id')
                      .equalTo(workerId)
                      .onValue
                      .listen((event) {
                    print(
                        'Snapshot: ${event.snapshot.value}'); // Print the entire snapshot

                    if (event.snapshot.value != null) {
                      Map<dynamic, dynamic>? data =
                          event.snapshot.value as Map<dynamic, dynamic>?;
                      if (data != null) {
                        var jobKey = data.keys.first;
                        var jobData = data[jobKey]; //WORKING HERE TO FINNISH LOCATION

                        var dateString = jobData['date'];
                        // var companyId = jobData['company_id'];
                        var jobStartTime = jobData['day_start_time'];
                        var jobEndTime = jobData['day_end_time'];
                        // var jobId = jobData['job_id'];
                        // var location = jobData['location'];

                        DateTime date =
                            DateFormat('dd-MM-yyyy').parse(dateString);
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
                      } else {
                        print(
                            "MEGAN IT fails: Data is not in the expected format");
                      }
                    } else {
                      print("MEGAN IT fails: No data found for Job ID: $jobId");
                    }
                  });
                }

                getList(availWorkerList); // TO DO RETURN MAIN LIST
              }
            } else {
              // Handle the case when there are no jobs with day_id equal to 1
              print('No jobs found with day_id equal to 1');
              getList([]);
            }
          });
        } else {
          print("MEGAN IT fails: Data is not in the expected format");
        }
      } else {
        print("MEGAN IT fails: No data found for Job ID: $jobId");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String jobId = widget.jobId;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DisplayText(
                  text: "List of Availiable Workers",
                  fontSize: 30,
                  colour: Colors.black),
              const SizedBox(height: 10),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.9,
                child: ListView.builder(
                  itemCount: workerList.length,
                  itemBuilder: (context, index) {
                    // Assuming each worker is represented as a Map
                    List<Object> worker = workerList[index];

                    return InkWell(
                      onTap: () {
                        // Handle the click on the list item
                        print('Clicked on worker: ${worker[0]}');
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5), // between items
                        padding:
                            const EdgeInsets.all(10), // space inside item box
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.deepPurple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: DisplayText(
                              text: "worker: $index",
                              fontSize: 24,
                              colour: Colors.black),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 100),
              PushButton(
                  buttonSize: 60,
                  text: "test",
                  onPress: () => getAvailablWorkers(jobId, (availWorkerList) {
                        setState(() {
                          workerList = availWorkerList;
                        });
                      })),
            ],
          ),
        ),
      ),
    );
  }
}
