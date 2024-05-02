import 'dart:convert';
import 'dart:typed_data';

import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/helpBut.dart';
import 'package:fyp/templates/profileView.dart';
import 'package:fyp/templates/pushBut.dart';
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
    super.initState(); // update jobs on load
    String workerId = widget.workerId;
    setState(() {
      getJobs(workerId, (List<dynamic> jobDetailList) {
        setState(() {
          jobList = jobDetailList;
        });
      });
    });
  }

  // Get the placemarks for the given latitude and longitude
  Future<String> getPlacemarks(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      var address = '';

      if (placemarks.isNotEmpty) {
        // Check if placemarks is not empty
        var subLocality = placemarks.reversed.last.subLocality ?? '';
        if (subLocality.trim().isNotEmpty) {
          address += subLocality;
        }

        var postalCode = placemarks.reversed.last.postalCode ?? '';
        if (postalCode.trim().isNotEmpty) {
          if (address.isNotEmpty) {
            address += ', ';
          }
          address += postalCode;
        }
      }

      return address; // Return the address as postal code and sublocality
    } catch (e) {
      // Error getting placemarks: $e
      return "No Address";
    }
  }

  // Get the jobs for the given workerId
  void getJobs(String workerId, Function(List<dynamic> jobList) getJobsList) {
    dbhandler // get list of jobs assigned to the worker
        .child('Assigned Jobs')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .listen((DatabaseEvent event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          List<Map<String, dynamic>> jobIdList = [];

          data.forEach((key, value) {
            // for each job assigned get the job details
            String jobId = value['job_id'];
            String companyId = value['company_id'];
            bool accepted = value['worker_accepted'];
            bool completed = value['worker_job_complete'];
            bool riskSupport = value['risk_support_plans'];

            if (!completed) {
              jobIdList.add({
                "jobId": jobId,
                "companyId": companyId,
                "accepted": accepted,
                "riskSupport": riskSupport,
              });
            }
          });

          List<Map<String, dynamic>> jobDetailsList = [];

          for (var job in jobIdList) {
            // for each job get specific job details
            String jobId = job['jobId'];
            String companyId = job['companyId'];
            bool accepted = job['accepted'];
            bool riskSupport = job['riskSupport'];

            await dbhandler
                .child('Jobs')
                .orderByChild('job_id')
                .equalTo(jobId)
                .onValue
                .first
                .then((event) async {
              if (event.snapshot.value != null) {
                Map<dynamic, dynamic>? data =
                    event.snapshot.value as Map<dynamic, dynamic>?;
                if (data != null) {
                  var jobKey = data.keys.first;
                  var jobData = data[jobKey];

                  var date = jobData['date'];
                  var jobStartTime = jobData['job_start_time'];
                  var jobEndTime = jobData['job_end_time'];
                  double lat = jobData['latitude'];
                  double long = jobData['longitude'];
                  String location = await getPlacemarks(lat, long);

                  await dbhandler // get the company name for the job
                      .child('Company')
                      .orderByChild('company_id')
                      .equalTo(companyId)
                      .onValue
                      .first
                      .then((event) {
                    if (event.snapshot.value != null) {
                      Map<dynamic, dynamic>? data =
                          event.snapshot.value as Map<dynamic, dynamic>?;
                      if (data != null) {
                        for (var companyKey in data.keys) {
                          var companyData = data[companyKey];
                          String companyName = companyData['name'];

                          // Add the job details to the list for display
                          jobDetailsList.add({
                            'jobId': jobId,
                            'company': companyName,
                            'companyId': companyId,
                            'date': date,
                            'startTime': jobStartTime,
                            'endTime': jobEndTime,
                            'location': location,
                            "assigned": accepted,
                            "riskSupport": riskSupport,
                          });
                        }
                      }
                    }
                  });
                }
              }
            });
          }

          await getJobsList(jobDetailsList); // return the list of job details
        } else {
          await getJobsList([]); // return empty list if no jobs
        }
      } else {
        // Data is not in the expected format
      }
    });
  }

  // Pick the colour for the job based on the assigned and riskSupport status
  Color pickColour(bool assigned, bool riskSupport) {
    if (assigned && riskSupport == false) {
      return const Color(0xff005ccc);
    } else if (assigned) {
      return const Color(0xff007e32);
    } else {
      return const Color(0xffb00003);
    }
  }

  // Accept the job with the given jobId to update assigned jobs
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
          var assignedJobKey = data.keys.first;
          dbhandler.child('Assigned Jobs').child(assignedJobKey).update({
            'worker_accepted': true, // set worker accepted to true
          });
        }
      }
    });
    dbhandler // remove declined workers if any
        .child('Declined Workers')
        .orderByChild('job_id')
        .equalTo(jobId)
        .onValue
        .first
        .then((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          var declinedKey = data.keys.first;
          dbhandler.child('Declined Workers').child(declinedKey).remove();
        }
      }
    });
  }

  // Confirm the job with the given jobId to update assigned jobs
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
          var assignedJobKey = data.keys.first;
          dbhandler.child('Assigned Jobs').child(assignedJobKey).update({
            "worker_job_complete": true, // set worker job complete to true
          });
        }
      }
    });
  }

  // Delete the job with the given jobId
  Future<void> deleteJobDb(String jobId) async {
    dbhandler // delete the job from the assigned jobs if both company and worker have completed
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
          var assignedJobKey = data.keys.first;
          var assignedData = data[assignedJobKey];

          bool company = assignedData['company_job_complete'];
          bool worker = assignedData['company_job_complete'];

          if (company && worker) {
            dbhandler.child('Assigned Jobs').child(assignedJobKey).remove();
          }
        }
      }
    });
  }

  // Add the declined worker to the database if the worker declines the job
  Future<void> addDeclinedDb(String jobId, String workerId) async {
    dbhandler
        .child("Declined Workers")
        .orderByChild("job_id")
        .equalTo(jobId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        // if there are already declined workers add the worker to the list
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
        }
      } else {
        // if no declined workers add new declined worker
        Map<String, dynamic> workers = {
          "job_id": jobId,
          "worker_id_0": workerId,
        };
        await dbhandler.child("Declined Workers").push().set(workers);
      }
    });
  }

  // Decline the job with the given jobId
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
            'worker_id': "none", // set worker id to none
          });
        }
      }
    });
  }

  // pop-up to accpet job or decline job
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
                declineJob(jobId); // decline the job in database
                addDeclinedDb(jobId, widget.workerId);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                acceptJob(jobId); // accept the job in database
                Navigator.of(context).pop();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // pop-up to confirm job completion
  Future<void> jobConfirmation(BuildContext context, String jobId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Has the job been completed?'),
          content: const DisplayText(
              text:
                  'Please select Yes to confirm the job completion or No if it has not.',
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
              onPressed: () async {
                await confirmJob(jobId); // confirm the job in database
                await deleteRiskSupport(
                    jobId); // delete the risk and support plans
                getJobs(widget.workerId, (List<dynamic> jobDetailList) {
                  // update the job list to remove the completed job
                  setState(() {
                    jobList = jobDetailList;
                  });
                });
                Navigator.of(context).pop();
                Flushbar(
                  // show confirmation message of job completion
                  backgroundColor: Colors.black,
                  message: "Job Confirmed!",
                  duration: Duration(seconds: 4),
                ).show(context);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // Convert the time string to minutes
  int stringTimeToMins(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  // Show the risk and support plans for the job
  Future<void> showRiskSupportPlans(BuildContext context, String jobId) async {
    List<Uint8List?> imgBytes = await getRiskSupport(
        jobId); // get the risk and support plans images from job id
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select the plan you want to view'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imgBytes[0] != null)
                PushButton(
                  buttonSize: 50,
                  text: "Risk Assessment",
                  onPress: () {
                    imageViewer(context,
                        imgBytes[0]); // pop-up to view the risk assessment plan
                  },
                ),
              const SizedBox(height: 5),
              if (imgBytes[1] != null)
                PushButton(
                  buttonSize: 50,
                  text: "Support Plans",
                  onPress: () {
                    imageViewer(context,
                        imgBytes[1]); // pop-up to view the support plans
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }

  // Delete the risk and support plans for the job
  Future<void> deleteRiskSupport(String jobId) async {
    await dbhandler
        .child('Risk Support Plans')
        .orderByChild('job_id')
        .equalTo(jobId)
        .once()
        .then((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          var rSKey = data.keys.first;
          dbhandler.child('Risk Support Plans').child(rSKey).remove();
        }
      }
    });
  }

  // Get the risk and support plans images for the job
  Future<List<Uint8List?>> getRiskSupport(String jobId) async {
    List<Uint8List?> result = [];

    await dbhandler // get the risk and support plans images for the job
        .child('Risk Support Plans')
        .orderByChild('job_id')
        .equalTo(jobId)
        .onValue
        .first
        .then((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          var rSKey = data.keys.first;
          var rSData = data[rSKey];
          // decode the base64 string to bytes
          Uint8List? riskImgBytes = base64Decode(rSData["risk_plans_img"]);
          Uint8List? supImgBytes = base64Decode(rSData["support_plans_img"]);

          result = [riskImgBytes, supImgBytes]; // return as a list to index
        }
      }
    });
    return result;
  }

  // Pop-up to view the image
  Future<void> imageViewer(BuildContext context, Uint8List? byteImg) async {
    // view the image in a pop-up
    if (byteImg == null) return; // if no image return nothing
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selected Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Image.memory(byteImg)], // display the image
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }

  // Handle the click on the job based on the status
  void clicked(String jobId, bool assigned, String dateString, String endTime,
      bool riskSupport) {
    DateTime today = DateTime.now(); // get the current date
    DateTime date =
        DateFormat('dd-MM-yyyy').parse(dateString); // format date of job
    TimeOfDay currentTime = TimeOfDay.now();
    String now = currentTime.format(context); // fomat current time
    if (assigned == false) {
      jobSelector(context, jobId); // pop-up to accept or decline job
    } else if ((today.isAtSameMomentAs(date) &&
            (stringTimeToMins(endTime) > stringTimeToMins(now))) ||
        today.isAfter(date)) {
      // check if the job is past completion date and time to confirm
      jobConfirmation(context, jobId);
    } else if (riskSupport) {
      // check if the risk and support plans are available
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: // show loading message
            Text("Risk and Support Plans Loading, this may take a second!"),
      ));
      showRiskSupportPlans(context, jobId);
    } else {
      // nothing to do
    }
  }

  // View the company profile
  Future<void> profileViewer(BuildContext context, String userId) async {
    dbhandler // search company id from job
        .child('Profiles')
        .orderByChild('user_id')
        .equalTo(userId)
        .onValue
        .first
        .then((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          var pKey = data.keys.first;
          var pData = data[pKey];
          String name = pData['name'];
          String imgPath = pData['img'];
          String description = pData['description'];

          showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Company Profile"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileView(
                        // display the company profile
                        name: name,
                        imgPath: imgPath,
                        experience: "",
                        description: description,
                        scale: 2) // display half scale to fit the pop-up
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Back'),
                  ),
                ],
              );
            },
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (jobList.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xffFCFAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xffFCFAFC),
          title: const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Center(
              child: DisplayText(
                  text: 'List of Current Jobs',
                  fontSize: 36,
                  colour: Colors.black),
            ),
          ),
          automaticallyImplyLeading: false, // Remove the back button
        ),
        body: const SafeArea(
          child: Center(
              child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 20), // Add horizontal padding
            child: Text(
              "You currently have no active jobs, please wait for a job request",
              style: TextStyle(
                fontSize: 26,
                color: Color(0xFF280387),
              ),
              textAlign: TextAlign.center,
            ),
          )),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: const Color(0xffFCFAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xffFCFAFC),
          title: const Padding(
            padding: EdgeInsets.only(top: 30), // Add padding above the title
            child: Center(
              child: DisplayText(
                  text: 'List of Current Jobs',
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: jobList.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> job = jobList[index];
                      return InkWell(
                        onTap: () async {
                          // handle the click on the job
                          clicked(job['jobId'], job['assigned'], job['date'],
                              job['endTime'], job['riskSupport']);
                        },
                        onDoubleTap: () async {
                          // double tap to view company profile
                          profileViewer(context, job['companyId']);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(20), // between items
                          padding:
                              const EdgeInsets.all(10), // space inside item box
                          decoration: BoxDecoration(
                            color: // set the colour based on the job status
                                pickColour(job['assigned'], job['riskSupport']),
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: DisplayText(
                                text: // display company name
                                    "Job: ${index + 1} (Company ${job['company']})",
                                fontSize: 20,
                                colour: const Color(0xffffffff)),
                            subtitle: DisplayText(
                                text: // display job details
                                    "Date: ${job['date']} \nTime: ${job['startTime']} to ${job['endTime']} \nLocation: ${job['location']}",
                                fontSize: 16,
                                colour: const Color(0xfffcfcfc)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(top: 20, right: 30),
                  child: const HelpButton(
                      // help button for user how to use page
                      message: 'Job colour meaning; \n'
                          '- Red: new job request, click to accept \n'
                          '- Blue: waiting for the company to add risk and support plans \n'
                          '- Green: click to view risk and support plans, once the job is completed click to confirm \n\n'
                          'Double tap on the job to view the company profile.',
                      title: "Job Viewer"),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      );
    }
  }
}
