import 'dart:math' show cos, sqrt, asin; // for harvesian formula
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/pages/company/companyNav.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

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
    // get the list of available workers when the page is loaded
    super.initState();
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

  // list of declined workers for passed job
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
          var declinedKey = data.keys.first;
          var declinedData = data[declinedKey];
          declinedData.forEach((key, value) {
            if (key != 'job_id') {
              // get all worker ids that declined the job
              declinedWorkers.add(value);
            }
          });
        }
      }
    });
    return declinedWorkers; // return to getAvailablWorkers function
  }

  // worker matching algorithmn for all workers that match the job
  // pass job id and function to get list of workers
  void getAvailablWorkers(
      String jobId, Function(List<String> workerList) getList) {
    dbhandler // get job details
        .child('Jobs')
        .orderByChild('job_id')
        .equalTo(jobId)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Assuming there's only one item in the snapshot (you are querying by jobId)
          var jobKey = data.keys.first;
          var jobData = data[jobKey];

          var dateString = jobData['date'];
          var jobStartTime = jobData['job_start_time'];
          var jobEndTime = jobData['job_end_time'];
          double jobLat = jobData['latitude'];
          double jobLong = jobData['longitude'];

          // formate the date to get the day
          DateTime date = DateFormat('dd-MM-yyyy').parse(dateString);
          String day = DateFormat('EEEE').format(date); // get day of the week
          // get day the date is on to compare with worker availability
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
            // error invalid date
          }

          // get list of declined workers for the job
          List<String> declinedWorkers = getDeclinedWorkers(jobId);
          // filter all workers that are available on the day
          dbhandler
              .child('Availability')
              .orderByChild('day_id')
              .equalTo(dayId)
              .onValue
              .listen((DatabaseEvent event) {
            if (event.snapshot.value != null) {
              Map<dynamic, dynamic>? data =
                  event.snapshot.value as Map<dynamic, dynamic>?;

              if (data != null) {
                List<String> availWorkerList =
                    []; // empty list to add available workers

                data.forEach((key, value) {
                  // loop through all workers availble on the day
                  int availStartTime = stringTimeToMins(
                      value['day_start_time']); // get worker start time
                  int availEndTime = stringTimeToMins(
                      value['day_end_time']); // get worker end time

                  if ((availStartTime <= stringTimeToMins(jobStartTime)) &&
                      (availEndTime >= stringTimeToMins(jobEndTime))) {
                    // check if worker start on or before job and if end on or after job
                    String workerId = value['worker_id'];
                    // Check if worker has declined the job
                    if (declinedWorkers.contains(workerId)) {
                      // Worker has declined the job
                    } else {
                      availWorkerList
                          .add(workerId); // add worker to available list
                    }
                  }
                });

                List<String> matchedWorkerList = [];

                for (String workerId in availWorkerList) {
                  // loop through all available workers to get location details
                  dbhandler
                      .child('Worker')
                      .orderByChild('worker_id')
                      .equalTo(workerId)
                      .onValue
                      .listen((event) async {
                    if (event.snapshot.value != null) {
                      // Explicitly cast to Map<dynamic, dynamic>
                      Map<dynamic, dynamic>? data =
                          event.snapshot.value as Map<dynamic, dynamic>?;
                      if (data != null) {
                        var workerKey = data.keys.first;
                        var workerData = data[workerKey];

                        double lat = workerData['latitude'];
                        double long = workerData['longitude'];
                        int miles = workerData['miles'];

                        double
                            actualDist = // calculate distance between job and worker
                            calculateDistance(jobLat, jobLong, lat, long);

                        // convert km to miles
                        double actualMiles = actualDist * 0.6214;

                        if (actualMiles <= miles) {
                          // check if worker is within the job miles
                          matchedWorkerList.add(
                              workerId); // add worker to matched list if miles are within range of job location
                        }
                      }
                    }

                    List<Tuple2<String, int>> fullyMatchedWorkerList = [];

                    for (String workerId in matchedWorkerList) {
                      // loop through all matched workers
                      if (widget.abilityList.isEmpty) {
                        // if no abilities are required
                        int jobCount = await workerJobCount(
                            workerId); // get the number of jobs the worker has
                        fullyMatchedWorkerList.add(Tuple2(workerId,
                            jobCount)); // tuple to link worker_id and job count
                      } else {
                        dbhandler
                            .child('Ability')
                            .orderByChild('worker_id')
                            .equalTo(workerId)
                            .onValue
                            .listen((event) async {
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
                                  workerAbilities.add(
                                      key); // get all abilities worker can do
                                }
                              });
                              // Check if all abilities are present
                              bool allAbilitiesPresent = true;
                              for (String ability in widget.abilityList) {
                                if (!workerAbilities.contains(ability)) {
                                  allAbilitiesPresent = false;
                                  break;
                                }
                              }

                              if (allAbilitiesPresent) {
                                // if all abilities are present add worker to fully matched list
                                int jobCount = await workerJobCount(workerId);
                                fullyMatchedWorkerList
                                    .add(Tuple2(workerId, jobCount));
                              }
                            }
                          }
                        });
                      }
                      // sort the list by job count
                      fullyMatchedWorkerList
                          .sort((a, b) => a.item2.compareTo(b.item2));
                      // extract the worker id from the tuple
                      List<String> orderedWorkers = fullyMatchedWorkerList
                          .map((tuple) => tuple.item1)
                          .toList();
                       await getList(orderedWorkers); // return the list of workers
                    }
                  });
                }
              }
            } else {
              // no workers found
              getList([]);
            }
          });
        } else {
          // Data is not in the expected format
        }
      } else {
        // No data found for Job ID: $jobId
      }
    });
  }

  // get the number of jobs a worker has
  Future<int> workerJobCount(String workerId) async {
    int count = 0;
    dbhandler
        .child('Assigned Jobs')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .listen((DatabaseEvent event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            if (value['worker_job_complete'] == false) {
              count++; // count the number of jobs the worker has
            }
          });
        }
      }
    });
    return count;
  }

  // delete job from database
  Future<void> deleteJobDb(String jobId) async {
    dbhandler
        .child('Jobs')
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
          var jobKey = data.keys.first;
          dbhandler.child('Jobs').child(jobKey).remove();
        }
      }
    });
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
          var jobKey = data.keys.first;
          dbhandler.child('Assigned Jobs').child(jobKey).remove();
        }
      }
    });
  }

  // add job to assigned jobs database with chosen workerid
  Future<void> addAssignJobDb(String jobId, String companyId, String workerId,
      BuildContext context) async {
    // pass jobid, companyid and workerid
    dbhandler // check if job is already assigned was created and update worker_id
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
        }
      } else {
        // if job has not been assigned create new job
        Map<String, dynamic> assignJob = {
          "job_id": jobId,
          "company_id": companyId,
          "worker_id": workerId,
          "worker_job_complete": false,
          "company_job_complete": false,
          "worker_accepted": false,
          "risk_support_plans": false,
        };

        try {
          await dbhandler.child("Assigned Jobs").push().set(assignJob);
        } catch (error) {
          // Handle issue adding to db
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (workerList.isEmpty) {
      // if no workers are available
      return Scaffold(
        backgroundColor: const Color(0xffFCFAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xffFCFAFC),
          title: const Padding(
            padding: EdgeInsets.only(top: 20), // Add padding above the title
            child: Center(
              child: DisplayText(
                  // display no workers available
                  text: "No Workers Available",
                  fontSize: 36,
                  colour: Colors.black),
            ),
          ),
          automaticallyImplyLeading: false, // Remove the back button
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PushButton(
                    buttonSize: 60,
                    text: "Keep Job",
                    onPress: () async {
                      addAssignJobDb(
                          // add job to assigned jobs with no worker
                          widget.jobId,
                          widget.companyId,
                          'none',
                          context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              // go back to company job page
                              builder: (context) => CompanyNavigationBar(
                                  companyId: widget.companyId, setIndex: 0)));
                    }),
                const SizedBox(height: 60),
                PushButton(
                    buttonSize: 60,
                    text: "Delete Job",
                    onPress: () async {
                      await deleteJobDb(
                          widget.jobId); // delete job from database
                      Navigator.push(
                          // go back to company job page
                          context,
                          MaterialPageRoute(
                              builder: (context) => CompanyNavigationBar(
                                  companyId: widget.companyId, setIndex: 0)));
                    }),
              ],
            ),
          ),
        ),
      );
    } else {
      // one or more workers are available
      return Scaffold(
        backgroundColor: const Color(0xffFCFAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xffFCFAFC),
          title: const Padding(
            padding: EdgeInsets.only(top: 20), // Add padding above the title
            child: Center(
              child: DisplayText(
                  text: "List of Available Workers",
                  fontSize: 36,
                  colour: Colors.black),
            ),
          ),
          automaticallyImplyLeading: false, // Remove the back button
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: ListView.builder(
                    itemCount: workerList.length,
                    itemBuilder: (context, index) {
                      String worker = workerList[
                          index]; // worker anymous so no personal data just worker 1,2,3...
                      return InkWell(
                        onTap: () async {
                          // choose worker add job to assigned jobs with chosen worker
                          addAssignJobDb(
                              widget.jobId, widget.companyId, worker, context);
                          Navigator.push(
                              // go back to company job page
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CompanyNavigationBar(
                                      companyId: widget.companyId,
                                      setIndex: 0)));
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
                            // display worker number
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
                    // delete job from database
                    buttonSize: 60,
                    text: "Delete Job",
                    onPress: () async {
                      await deleteJobDb(widget.jobId);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CompanyNavigationBar(
                                  companyId: widget.companyId, setIndex: 0)));
                    }),
              ],
            ),
          ),
        ),
      );
    }
  }
}
