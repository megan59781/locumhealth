import 'dart:math' show cos, sqrt, asin;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/pages/company/companyNav.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CompanyWorkerList extends StatefulWidget {
  final String companyId;
  final String jobId;
  final List<String> abilityList;
  const CompanyWorkerList(
      {super.key,
      required this.companyId,
      required this.jobId,
      required this.abilityList});

  @override
  State<CompanyWorkerList> createState() => CompanyWorkerListState();
}

class CompanyWorkerListState extends State<CompanyWorkerList> {
  List<dynamic> workerList = [];
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    print("this is where job is passed");
    print(widget.jobId);
    setState(() {
      getAvailablWorkers(widget.jobId, (List<dynamic> matchedWorkerList) {
        setState(() {
          workerList = matchedWorkerList;
        });
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

  List<String> getDeclinedWorkers(String jobId) {
    List<String> declinedWorkers = [];
    dbhandler
        .child('Declined Workers')
        .orderByChild('job_id')
        .equalTo(jobId)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Assuming there is only one entry, you can access it directly
          var declinedKey = data.keys.first;
          var declinedData = data[declinedKey];
          declinedData.forEach((key, value) {
            if (key != 'job_id') {
              declinedWorkers.add(value);
            }
          });
          print("HERE Worker LIST: $declinedWorkers");
        }
      }
    });
    return declinedWorkers;
  }

  void getAvailablWorkers(
      String jobId, Function(List<String> workerList) getList) {
    print("Print this function is being passed");
    print(jobId);

    dbhandler
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
          var jobStartTime = jobData['job_start_time'];
          var jobEndTime = jobData['job_end_time'];
          // var jobId = jobData['job_id'];
          double jobLat = jobData['latitude'];
          double jobLong = jobData['longitude'];

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
          List<String> declinedWorkers = getDeclinedWorkers(jobId);
          print("HERE declined Worker LIST: $declinedWorkers");
          dbhandler
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
                List<String> availWorkerList = [];
                data.forEach((key, value) {
                  int availStartTime =
                      stringTimeToMins(value['day_start_time']);
                  int availEndTime = stringTimeToMins(value['day_end_time']);

                  if ((availStartTime <= stringTimeToMins(jobStartTime)) &&
                      (availEndTime >= stringTimeToMins(jobEndTime))) {
                    String workerId = value['worker_id'];
                    // Check if worker has declined the job
                    if (declinedWorkers.contains(workerId)) {
                      print('Worker $workerId has declined the job');
                    } else {
                      availWorkerList.add(workerId);
                    }
                  }
                });

                print('old Worker List: $availWorkerList');

                ///check declined workers if on list remove

                List<String> matchedWorkerList = [];

                for (String workerId in availWorkerList) {
                  dbhandler
                      .child('Worker')
                      .orderByChild('worker_id')
                      .equalTo(workerId)
                      .onValue
                      .listen((event) {
                    print(
                        'Snapshot: ${event.snapshot.value}'); // Print the entire snapshot
                    if (event.snapshot.value != null) {
                      // Explicitly cast to Map<dynamic, dynamic>
                      Map<dynamic, dynamic>? data =
                          event.snapshot.value as Map<dynamic, dynamic>?;
                      if (data != null) {
                        // Assuming there is only one entry, you can access it directly
                        var workerKey = data.keys.first;
                        var workerData = data[workerKey];

                        double lat = workerData['latitude'];
                        double long = workerData['longitude'];
                        int miles = workerData['miles'];

                        double actualDist =
                            calculateDistance(jobLat, jobLong, lat, long);
                        print(actualDist);

                        double actualMiles = actualDist * 0.6214;

                        if (actualMiles <= miles) {
                          matchedWorkerList.add(workerId);
                        }
                      }
                    }
                    print("megan this is a sucess");
                    print(matchedWorkerList);

                    List<String> fullyMatchedWorkerList = [];

                    for (String workerId in matchedWorkerList) {
                      dbhandler
                          .child('Ability')
                          .orderByChild('worker_id')
                          .equalTo(workerId)
                          .onValue
                          .listen((event) {
                        print(
                            'HERE ABILITIES Snapshot: ${event.snapshot.value}');
                        if (event.snapshot.value != null) {
                          Map<dynamic, dynamic>? data =
                              event.snapshot.value as Map<dynamic, dynamic>?;
                          if (data != null) {
                            List<String> workerAbilities = [];
                            // Assuming there is only one entry, you can access it directly
                            var abilityKey = data.keys.first;
                            var abilityData = data[abilityKey];
                            abilityData.forEach((key, value) {
                              if (key != 'worker_id') {
                                workerAbilities.add(key);
                              }
                            });
                            print("HERE LIST: $workerAbilities");

                            // Check if all abilities are present
                            bool allAbilitiesPresent = true;
                            for (String ability in widget.abilityList) {
                              if (!workerAbilities.contains(ability)) {
                                allAbilitiesPresent = false;
                                break;
                              }
                            }

                            if (allAbilitiesPresent) {
                              fullyMatchedWorkerList.add(workerId);
                            }
                          }
                        }
                        print("megan this is a sucess");
                        getList(fullyMatchedWorkerList);
                      });
                    }
                  });
                }
              }
            } else {
              // TO DO SHOW NO WORKERS FOUND
              print('No workers found');
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

  Future<void> addAssignJobDb(String jobId, String companyId, String workerId,
      BuildContext context) async {
    dbhandler
        .child("Assigned Jobs")
        .orderByChild("job_id")
        .equalTo(jobId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          var jobKey = data.keys.first;
          dbhandler.child("Assigned Jobs").child(jobKey).update({
            "worker_id": workerId,
          });
          print("here new worker updated");
        }
      } else {
        String assignId = const Uuid().v4();

        Map<String, dynamic> assignJob = {
          "assign_job_id": assignId,
          "job_id": jobId,
          "company_id": companyId,
          "worker_id": workerId,
          "worker_job_complete": false,
          "company_job_complete": false,
          "worker_accepted": false,
        };

        try {
          await dbhandler.child("Assigned Jobs").push().set(assignJob);
          //Navigator.of(context).pop();
        } catch (error) {
          print("Error saving to Firebase: $error");
        }
      }
    });
  }

  // Future<void> addAssignJobDb(String jobId, String companyId, String workerId,
  //     BuildContext context) async {
  //   String assignId = const Uuid().v4();

  //   Map<String, dynamic> assignJob = {
  //     "assign_job_id": assignId,
  //     "job_id": jobId,
  //     "company_id": companyId,
  //     "worker_id": workerId,
  //     "worker_job_complete": false,
  //     "company_job_complete": false,
  //     "worker_accepted": false,
  //   };

  //   try {
  //     await dbhandler.child("Assigned Jobs").push().set(assignJob);
  //     //Navigator.of(context).pop();
  //   } catch (error) {
  //     print("Error saving to Firebase: $error");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
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
                    String worker = workerList[index];

                    return InkWell(
                      onTap: () async {
                        print('Clicked on worker: $worker');
                        addAssignJobDb(
                            widget.jobId, widget.companyId, worker, context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CompanyNavigationBar(
                                    companyId: widget.companyId)));
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
                  text: "Go Back",
                  onPress: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CompanyNavigationBar(
                                companyId: widget.companyId)));
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
