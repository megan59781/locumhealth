import 'dart:convert';
import 'dart:typed_data';

import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/pages/company/companyWorkerList.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/helpBut.dart';
import 'package:fyp/templates/profileView.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class CompanyJob extends StatefulWidget {
  final String companyId;
  const CompanyJob({super.key, required this.companyId});

  @override
  State<CompanyJob> createState() => CompanyJobState();
}

class CompanyJobState extends State<CompanyJob> {
  List<dynamic> jobList =
      []; // empty list to be updated to store the job details
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();

  // varibales for risk and support plans
  Uint8List? riskImgBytes;
  Uint8List? supImgBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    // get the job details from the database when the page is loaded
    super.initState();
    String companyId = widget.companyId;
    setState(() {
      getJobs(companyId, (List<dynamic> jobDetailList) {
        setState(() {
          jobList = jobDetailList;
        });
      });
    });
  }

  // Function to get the address from the latitude and longitude
  Future<String> getPlacemarks(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      var address = ''; // empty string to store the address

      if (placemarks.isNotEmpty) {
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

      return address; // return subLocality and postal code
    } catch (e) {
      // Error getting placemarks: $e
      return "No Address";
    }
  }

  // Function to get the job details from the database
  // Passes the company id and a function to update the job list
  void getJobs(String companyId, Function(List<dynamic> jobList) getJobsList) {
    dbhandler // get the assigned jobs of the company from the database
        .child('Assigned Jobs')
        .orderByChild('company_id')
        .equalTo(companyId)
        .onValue
        .listen((DatabaseEvent event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          List<Map<String, dynamic>> jobIdList = [];

          data.forEach((key, value) {
            // loop through all the assigned jobs
            bool accepted = value['worker_accepted'];
            String jobId = value['job_id'];
            String workerId = value['worker_id'];
            bool completed = value['company_job_complete'];
            bool riskSupport = value['risk_support_plans'];

            if (!completed) {
              // if the job is not completed add the job details to the list
              jobIdList.add({
                "jobId": jobId,
                "workerId": workerId,
                "accepted": accepted,
                "riskSupport": riskSupport
              });
            }
          });

          List<Map<String, dynamic>> jobDetailsList = [];

          // loop through the job list to get the job details
          for (var job in jobIdList) {
            String jobId = job['jobId'];
            String workerId = job['workerId'];
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

                  // if the worker is not assigned yet add the job details to the list and keep worker as not assigned yet
                  if (workerId == "none") {
                    jobDetailsList.add({
                      'jobId': jobId,
                      'worker': "not assigned yet",
                      'date': date,
                      'startTime': jobStartTime,
                      'endTime': jobEndTime,
                      'location': location,
                      'assigned': accepted,
                      'workerId': workerId,
                      'riskSupport': riskSupport
                    });
                  } else {
                    await dbhandler // get worker details to add to the job list
                        .child('Worker')
                        .orderByChild('worker_id')
                        .equalTo(workerId)
                        .onValue
                        .first
                        .then((event) {
                      if (event.snapshot.value != null) {
                        Map<dynamic, dynamic>? data =
                            event.snapshot.value as Map<dynamic, dynamic>?;
                        if (data != null) {
                          var workerKey = data.keys.first;
                          var workerData = data[workerKey];
                          var worker = workerData['name'];

                          jobDetailsList.add({
                            'jobId': jobId,
                            'worker': worker,
                            'date': date,
                            'startTime': jobStartTime,
                            'endTime': jobEndTime,
                            'location': location,
                            'assigned': accepted,
                            'workerId': workerId,
                            'riskSupport': riskSupport
                          });
                        }
                      }
                    });
                  }
                }
              }
            });
          }

          await getJobsList(jobDetailsList); // update the job list
        } else {
          await getJobsList([]); // if empty still update
        }
      } else {
        // Data is not in the expected format
      }
    });
  }

  // Function to delete the job from the database
  Future<void> deleteJobDb(String jobId, bool notComplete) async {
    dbhandler // delete the job from the database
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
    // delete the assigned job from the database
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
          var assignedData = data[assignedJobKey];

          bool company = assignedData['company_job_complete'];
          bool worker = assignedData['company_job_complete'];

          // if the job is completed from both partys delete the assigned job
          // or if the job has been deleted before it was completed delete the assigned job
          if (company && worker || notComplete == true) {
            dbhandler // remove declined workers if any as the job is deleted by company and not assigned
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
                  dbhandler
                      .child('Declined Workers')
                      .child(declinedKey)
                      .remove();
                }
              }
            });
            dbhandler.child('Assigned Jobs').child(assignedJobKey).remove();
          }
        }
      }
    });
  }

  // if the job is completed confirm the job and update the database
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
            "company_job_complete": true,
          });
        }
      }
    });
  }

  // add risk assesment assigned to the assigned job database
  Future<void> subitRiskSupport(String jobId) async {
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
            "risk_support_plans": true,
          });
        }
      }
    });
  }

  // pop up to confirm job completion
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
                setState(() {
                  confirmJob(jobId); // confirm the job in database
                  deleteJobDb(jobId,
                      false); // delete the job from the database and other related data
                });
                getJobs(widget.companyId, (List<dynamic> jobDetailList) {
                  // update job list to remove the completed job from ui
                  setState(() {
                    jobList = jobDetailList;
                  });
                });
                Navigator.of(context).pop();
                Flushbar(
                  // show a message to confirm the job has been completed
                  backgroundColor: Colors.black,
                  message: "Job Confirmed!",
                  duration: const Duration(seconds: 4),
                ).show(context);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // add the risk and support plans to the database with link of job_id
  Future<void> addRiskSupportDb(String jobId) async {
    String riskImg = base64Encode(riskImgBytes!);
    String supportImg = base64Encode(supImgBytes!);
    Map<String, dynamic> plansList = {
      "job_id": jobId,
      "risk_plans_img": riskImg,
      "support_plans_img": supportImg,
    };
    await dbhandler.child("Risk Support Plans").push().set(plansList);
    riskImgBytes = null;
    supImgBytes = null;
  }

  // pop up to add the risk and support plans
  Future<void> addRiskSupportPlans(BuildContext context, String jobId) async {
    return showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog when clicking outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Risk & Support Plans'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DisplayText(
                text: 'Click to submit the required plans',
                fontSize: 16,
                colour: Colors.black,
              ),
              const SizedBox(height: 5),
              PushButton(
                buttonSize: 50,
                text: "Risk Assessment",
                onPress: () {
                  // submit the risk plan
                  _submitPicture(context,
                      isRisk: true); // true to submit the risk plan
                },
              ),
              const SizedBox(height: 5),
              PushButton(
                buttonSize: 50,
                text: "Support Plans",
                onPress: () {
                  // submit the support plan
                  _submitPicture(context,
                      isRisk: false); // false to submit the support plan
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // clears the byte data and closes the dialog
                setState(() {
                  riskImgBytes = null;
                  supImgBytes = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
            TextButton(
              onPressed: () async {
                // submit the risk and support plans if both are added
                if (riskImgBytes != null && supImgBytes != null) {
                  // flush bar as shows over alert dialog
                  Flushbar(
                    // show a message to confirm the plans have been added
                    backgroundColor: Colors.black,
                    message:
                        "Risk and Support Plans Added, this may take a second!",
                    duration: const Duration(seconds: 10),
                  ).show(context);
                  await addRiskSupportDb(
                      jobId); // add the risk and support plans to the database
                  await subitRiskSupport(
                      jobId); // update the assigned job to show the plans have been added
                  Navigator.of(context).pop();
                } else {
                  Flushbar(
                    // show a message to add both plans before submitting
                    backgroundColor: Colors.black,
                    message:
                        "Please add both Risk and Support Plans before submitting!",
                    duration: const Duration(seconds: 4),
                  ).show(context);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage(BuildContext context, {required bool isRisk}) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (isRisk) {
        // if the image is for the risk plan or support
        riskImgBytes = Uint8List.fromList(bytes); // convert the image to bytes
      } else {
        supImgBytes = Uint8List.fromList(bytes);
      }
      Navigator.of(context).pop(); // Close the current dialog
      _submitPicture(context,
          isRisk:
              isRisk); // Show the dialog again after selecting an image to submit
    }
  }

  // Function to submit the picture
  Future<void> _submitPicture(BuildContext context,
      {required bool isRisk}) async {
    return showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog when clicking outside the alert dialog
      builder: (BuildContext context) {
        Uint8List? imageBytes;
        if (isRisk) {
          // if the image is for the risk plan or support
          imageBytes = riskImgBytes;
        } else {
          imageBytes = supImgBytes;
        }
        return AlertDialog(
          title: const Text('Submit Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              imageBytes == null
                  ? const Text(
                      // if no image is selected show the message to select an image
                      'No image selected, please click Reselect and pick an Image.')
                  : Image.memory(imageBytes), // show the selected image
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _pickImage(context,
                          isRisk: isRisk); // Allow reselecting an image
                    },
                    child: const Text('Reselect'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to select the job view colour of the based on the status of current job
  Color pickColour(bool assigned, String workerId, bool riskSupport) {
    if (assigned && riskSupport == false) {
      return const Color(0xff005ccc);
    } else if (assigned) {
      return const Color(0xff007e32);
    } else if (workerId == "none") {
      return const Color(0xff631da3);
    } else {
      return const Color(0xffb00003);
    }
  }

  // Function to convert the time string to minutes
  int stringTimeToMins(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  // Function to handle the click on the job and link to relevant actions
  void clicked(String jobId, bool assigned, String workerId, String dateString,
      String endTime, bool riskSupport) {
    DateTime today =
        DateTime.now(); // get the current date and time for comparing
    DateTime date = DateFormat('dd-MM-yyyy')
        .parse(dateString); // format the date of the job
    TimeOfDay currentTime = TimeOfDay.now(); // get the current time
    String now = currentTime.format(context); // format the current time
    if (workerId == 'none') {
      // no worker selected click pick worker
      setState(() {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CompanyWorkerList(
                    companyId: widget.companyId,
                    jobId: jobId,
                    abilityList: const [])));
      });
    } else if ((today.isAtSameMomentAs(date) &&
            (stringTimeToMins(endTime) > stringTimeToMins(now))) ||
        today.isAfter(date)) {
      // if the job is past completion day and time click to confirm
      setState(() {
        jobConfirmation(context, jobId); // confirm the job
      });
    } else if (riskSupport == false && assigned == true) {
      // if the job is assigned and risk and support plans are not added click to add
      addRiskSupportPlans(context, jobId);
    } else if ((today.isAtSameMomentAs(date) &&
            (stringTimeToMins(endTime) > ((8 * 60) + stringTimeToMins(now)))) ||
        date.isAfter(today)) {
      // if the job is 8 hours or more than current time then can click to delete
      deleteJob(context, jobId);
    } else {
      // nothing to do
    }
  }

  // Pop-up to check if company wants to delete the job
  void deleteJob(BuildContext context, String jobId) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Job"),
          contentPadding: EdgeInsets.zero,
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 5,
              ),
              DisplayText(
                  text: "Are You Sure You Want To Delete This Job?",
                  fontSize: 20,
                  colour: Colors.black),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
            TextButton(
              onPressed: () async {
                await deleteJobDb(jobId,
                    true); // delete the job from the database, pass true as not complted
                getJobs(widget.companyId, (List<dynamic> jobDetailList) {
                  // update joblist and ui
                  setState(() {
                    jobList = jobDetailList;
                  });
                });
                Navigator.of(context).pop();
                Flushbar(
                  // show a message to confirm the job has been deleted
                  backgroundColor: Colors.black,
                  message: "Job Deleted!",
                  duration: const Duration(seconds: 4),
                ).show(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // pop up to view the worker profile
  Future<void> profileViewer(BuildContext context, String userId) async {
    dbhandler // get the worker profile details from the database with workerid passed in
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
          int experience = pData['experience'];
          String description = pData['description'];

          showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Worker's Profile"),
                contentPadding: EdgeInsets.zero,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 5,
                    ),
                    ProfileView(
                        // show the worker profile details through template
                        name: name,
                        imgPath: imgPath,
                        experience: '$experience Years Experience',
                        description: description,
                        scale:
                            2) // scale to decrease the size of the profile to fit in alert dialgoe
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
      // if no jobs are available show the message
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
        body: const SafeArea(
          child: Center(
              child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 20), // Add horizontal padding to center text
            child: Text(
              "No Current Jobs Created, Click the Create Job Tab to Create a New Job.",
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
      // if jobs are available show the job list
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
                          setState(() {
                            // handle the click on the job, pass relavent data for the function
                            clicked(
                                job['jobId'],
                                job['assigned'],
                                job['workerId'],
                                job['date'],
                                job['endTime'],
                                job['riskSupport']);
                          });
                        },
                        onDoubleTap: () async {
                          // double tap to view the worker profile
                          profileViewer(context, job['workerId']);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(
                              20), // between items for formatting
                          padding:
                              const EdgeInsets.all(10), // space inside item box
                          decoration: BoxDecoration(
                            color: pickColour(job['assigned'], job['workerId'],
                                job['riskSupport']), // colour based on job status via function
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: DisplayText(
                                text:
                                    "Job: ${index + 1} (Worker ${job['worker']})", // show the job number and worker name
                                fontSize: 20,
                                colour: const Color(0xffffffff)),
                            subtitle: DisplayText(
                                // show the job details
                                text:
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
                  // help button to show the job viewer help message
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(top: 20, right: 30),
                  child: const HelpButton(
                      message: 'Job colour meaning; \n'
                          '- Red: waiting for the woker to accept \n'
                          '- Blue: worker assigned click the job to add the risk and support plans \n'
                          '- Pink: no worker assigned, click to assign a worker to the job \n'
                          '- Green: job is active, to delete the job click, once the job is completed click to confirm \n\n'
                          'Double tap on the job to view the worker profile.',
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
