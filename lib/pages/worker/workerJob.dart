import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class WorkerJob extends StatefulWidget {
  final String workerId;
  const WorkerJob({super.key, required this.workerId});

  @override
  State<WorkerJob> createState() => WorkerJobState();
}

class WorkerJobState extends State<WorkerJob> {
  List<dynamic> jobList = [];
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    String workerId = widget.workerId;
    getJobs(workerId, (List<dynamic> jobDetailList) {
      setState(() {
        jobList = jobDetailList;
      });
    });
  }

  Future<String> getPlacemarks(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      var address = '';

      if (placemarks.isNotEmpty) {
        address += placemarks.reversed.last.subLocality ?? '';
        address += ', ${placemarks.reversed.last.locality ?? ''}';
        // address += ', ${placemarks.reversed.last.subAdministrativeArea ?? ''}';
        //address += ', ${placemarks.reversed.last.administrativeArea ?? ''}';
        address += ', ${placemarks.reversed.last.postalCode ?? ''}';
        // address += ', ${placemarks.reversed.last.country ?? ''}';
      }

      //print("Your Address for ($lat, $long) is: $address");

      return address;
    } catch (e) {
      //print("Error getting placemarks: $e");
      return "No Address";
    }
  }

  void getJobs(String workerId, Function(List<dynamic> jobList) getJobsList) {
    dbhandler
        .child('Assigned Jobs')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          // Convert the Map<dynamic, dynamic> to a List
          List<Map<String, dynamic>> jobIdList = [];
          data.forEach((key, value) {
            //Deal with jobs in the list
            String jobId = value['job_id'];
            String companyId = value['company_id'];
            bool accepted = value['worker_accepted'];
            bool completed = value['worker_job_complete'];

            if (!completed) {
              jobIdList.add({
                "jobId": jobId,
                "companyId": companyId,
                "accepted": accepted
              });
            }
          });

          List<Map<String, dynamic>> jobDetailsList = [];
          print("HERE jobIdList: $jobIdList");

          for (var job in jobIdList) {
            String jobId = job['jobId'];
            String companyId = job['companyId'];
            bool accepted = job['accepted'];
            print("$jobId            w:$companyId");
            dbhandler
                .child('Jobs')
                .orderByChild('job_id')
                .equalTo(jobId)
                .onValue
                .listen((event) async {
              print('Job Query output: ${event.snapshot.value}');
              if (event.snapshot.value != null) {
                Map<dynamic, dynamic>? data =
                    event.snapshot.value as Map<dynamic, dynamic>?;
                if (data != null) {
                  // Assuming there is only one entry, you can access it directly
                  var jobKey = data.keys.first;
                  var jobData = data[jobKey];

                  var date = jobData['date'];
                  var jobStartTime = jobData['job_start_time'];
                  var jobEndTime = jobData['job_end_time'];

                  double lat = jobData['latitude'];
                  double long = jobData['longitude'];

                  String location = await getPlacemarks(lat, long);
                  print(location);

                  dbhandler
                      .child('Company')
                      .orderByChild('company_id')
                      .equalTo(companyId)
                      .onValue
                      .listen((event) async {
                    print('Company Query output: ${event.snapshot.value}');
                    if (event.snapshot.value != null) {
                      Map<dynamic, dynamic>? data =
                          event.snapshot.value as Map<dynamic, dynamic>?;
                      if (data != null) {
                        // Assuming there is only one entry, you can access it directly
                        for (var companyKey in data.keys) {
                          var companyData = data[companyKey];
                          String companyName = companyData['name'];

                          jobDetailsList.add({
                            'jobId': jobId,
                            'company': companyName,
                            'date': date,
                            'startTime': jobStartTime,
                            'endTime': jobEndTime,
                            'location': location,
                            "assigned": accepted,
                          });
                        }
                      }
                    }
                  });
                }
              }
            });
          }

          // HERE TO RETURN JOBS
          print('jobs deatails list');
          print(jobDetailsList);
          getJobsList(jobDetailsList);
        } else {
          // Handle the case when there are no jobs assigned
          getJobsList([]);
        }
      } else {
        print("MEGAN IT fails: Data is not in the expected format");
      }
    });
  }

  Color pickColour(bool assigned) {
    if (assigned) {
      return Colors.lightGreen[400]!;
    } else {
      return Colors.deepOrange[400]!;
    }
  }

  Future<void> acceptJob(String jobId) async {
    dbhandler
        .child('Assigned Jobs')
        .orderByChild('job_id')
        .equalTo(jobId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          // Assuming there is only one entry, you can access it directly
          var assignedJobKey = data.keys.first;
          dbhandler.child('Assigned Jobs').child(assignedJobKey).update({
            'worker_accepted': true,
          });
        }
      }
    });
  }

  Future<void> confirmJob(String jobId) async {
    dbhandler
        .child('Assigned Jobs')
        .orderByChild('job_id')
        .equalTo(jobId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          // Assuming there is only one entry, you can access it directly
          var assignedJobKey = data.keys.first;
          dbhandler.child('Assigned Jobs').child(assignedJobKey).update({
            "worker_job_complete": true,
          });
        }
      }
    });
  }

  Future<void> addDeclinedDb(String jobId, String workerId) async {
    print("here function working worker removed");
    dbhandler
        .child("Declined Workers")
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
          var jobData = data[jobKey];
          int count = (jobData.length) - 1;
          String newKey = "worker_id_$count";
          dbhandler.child("Declined Workers").child(jobKey).update({
            newKey: workerId,
          });
          print("here data exists");
        }
      } else {
        Map<String, dynamic> workers = {
          "job_id": jobId,
          "worker_id_0": workerId,
        };
        await dbhandler.child("Declined Workers").push().set(workers);
        print("added HERE");
      }
    });
  }

  Future<void> declineJob(String jobId) async {
    print('jobid declined is $jobId');
    dbhandler
        .child('Assigned Jobs')
        .orderByChild('job_id')
        .equalTo(jobId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          // Assuming there is only one entry, you can access it directly
          var assignedJobKey = data.keys.first;
          dbhandler.child('Assigned Jobs').child(assignedJobKey).update({
            'worker_id': "none",
          });
        }
      }
    });
  }

  Future<void> jobSelector(BuildContext context, String jobId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Do you want to accept this job?'),
          content: const DisplayText(
              text: 'Please select Yes to accept the job or No to decline.',
              fontSize: 20,
              colour: Colors.black),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                declineJob(jobId);
                addDeclinedDb(jobId, widget.workerId);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                acceptJob(jobId);
                Navigator.of(context).pop();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> jobConfirmation(BuildContext context, String jobId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Has the job been completed?'),
          content: const DisplayText(
              text:
                  'Please select Yes to confirm the job complettion or No if it has not.',
              fontSize: 20,
              colour: Colors.black),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                confirmJob(jobId);
                Navigator.of(context).pop();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  int stringTimeToMins(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  void clicked(String jobId, bool assigned, String dateString, String endTime) {
    DateTime today = DateTime.now();
    DateTime date = DateFormat('dd-MM-yyyy').parse(dateString);
    TimeOfDay currentTime = TimeOfDay.now();
    String now = currentTime.format(context);
    if (assigned == false) {
      jobSelector(context, jobId);
    } else if ((today.isAtSameMomentAs(date) &&
            (stringTimeToMins(endTime) > stringTimeToMins(now))) ||
        today.isAfter(date)) {
      print("job over");
      jobConfirmation(context, jobId);
    }
    else {
      //jobConfirmation(context, jobId);
      // TO DO: error message nothing to do
    }
  }

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
                  text: "List of Current Jobs",
                  fontSize: 30,
                  colour: Colors.black),
              const SizedBox(height: 10),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.9,
                child: ListView.builder(
                  itemCount: jobList.length,
                  itemBuilder: (context, index) {
                    // Assuming each worker is represented as a Map
                    Map<String, dynamic> job = jobList[index];
                    return InkWell(
                      onTap: () async {
                        clicked(job['jobId'], job['assigned'], job['date'],
                            job['endTime']);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5), // between items
                        padding:
                            const EdgeInsets.all(10), // space inside item box
                        decoration: BoxDecoration(
                          color: pickColour(job['assigned']),
                          border: Border.all(color: Colors.deepPurple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: DisplayText(
                              text:
                                  "Job: ${index + 1} (Company ${job['company']})", //${job['workerId']})", TO DO PUT WORKER NAME
                              fontSize: 20,
                              colour: Colors.black),
                          subtitle: DisplayText(
                              text:
                                  "Date: ${job['date']} \nTime: ${job['startTime']} to ${job['endTime']} \nLocation: ${job['location']}",
                              fontSize: 18,
                              colour: Colors.deepPurple),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
