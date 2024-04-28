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
  List<dynamic> jobList = [];
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  // Uint8List? _riskImgBytes;
  // Uint8List? _supImgBytes;
  Uint8List? riskImgBytes;
  Uint8List? supImgBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
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

  Future<String> getPlacemarks(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      var address = '';

      if (placemarks.isNotEmpty) {
        var subLocality = placemarks.reversed.last.subLocality ?? '';
        if (subLocality.trim().isNotEmpty) {
          address += subLocality;
        }
        //address += ', ${placemarks.reversed.last.locality ?? ''}';
        // address += ', ${placemarks.reversed.last.subAdministrativeArea ?? ''}';
        //address += ', ${placemarks.reversed.last.administrativeArea ?? ''}';
        //address += ', ${placemarks.reversed.last.postalCode ?? ''}';
        var postalCode = placemarks.reversed.last.postalCode ?? '';
        if (postalCode.trim().isNotEmpty) {
          if (address.isNotEmpty) {
            address += ', ';
          }
          address += postalCode;
        }
      }

      //print("Your Address for ($lat, $long) is: $address");

      return address;
    } catch (e) {
      //print("Error getting placemarks: $e");
      return "No Address";
    }
  }

  void getJobs(String companyId, Function(List<dynamic> jobList) getJobsList) {
    dbhandler
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
            bool accepted = value['worker_accepted'];
            String jobId = value['job_id'];
            String workerId = value['worker_id'];
            bool completed = value['company_job_complete'];
            bool riskSupport = value['risk_support_plans'];

            if (!completed) {
              jobIdList.add({
                "jobId": jobId,
                "workerId": workerId,
                "accepted": accepted,
                "riskSupport": riskSupport
              });
            }
          });

          List<Map<String, dynamic>> jobDetailsList = [];

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
                    await dbhandler
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

          await getJobsList(jobDetailsList);
        } else {
          await getJobsList([]);
        }
      } else {
        //print("Data is not in the expected format");
      }
    });
  }

  Future<void> deleteJobDb(String jobId, bool notComplete) async {
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
          var assignedJobKey = data.keys.first;
          var assignedData = data[assignedJobKey];

          bool company = assignedData['company_job_complete'];
          bool worker = assignedData['company_job_complete'];

          if (company && worker || notComplete == true) {
            dbhandler
                .child("Risk Support Plans")
                .orderByChild('job_id')
                .equalTo(jobId)
                .onValue
                .take(1)
                .listen((event) async {
              if (event.snapshot.value != null) {
                Map<dynamic, dynamic>? data =
                    event.snapshot.value as Map<dynamic, dynamic>?;
                if (data != null) {
                  var riskSupportKey = data.keys.first;

                  dbhandler
                      .child('Risk Support Plans')
                      .child(riskSupportKey)
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
                  confirmJob(jobId);
                  deleteJobDb(jobId, false);
                });
                getJobs(widget.companyId, (List<dynamic> jobDetailList) {
                  setState(() {
                    jobList = jobDetailList;
                  });
                });
                Navigator.of(context).pop();
                Flushbar(
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
                  _submitPicture(context, isRisk: true);
                },
              ),
              const SizedBox(height: 5),
              PushButton(
                buttonSize: 50,
                text: "Support Plans",
                onPress: () {
                  _submitPicture(context, isRisk: false);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
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
                if (riskImgBytes != null && supImgBytes != null) {
                  Flushbar(
                    backgroundColor: Colors.black,
                    message:
                        "Risk and Support Plans Added, this may take a second!",
                    duration: Duration(seconds: 4),
                  ).show(context);
                  await addRiskSupportDb(jobId);
                  await subitRiskSupport(jobId);

                  // addRiskSupportDb(jobId);
                  // subitRiskSupport(jobId);
                } else {
                  Flushbar(
                    backgroundColor: Colors.black,
                    message:
                        "Please add both Risk and Support Plans before submitting!",
                    duration: Duration(seconds: 4),
                  ).show(context);
                }

                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, {required bool isRisk}) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (isRisk) {
        riskImgBytes = Uint8List.fromList(bytes);
      } else {
        supImgBytes = Uint8List.fromList(bytes);
      }
      Navigator.of(context).pop(); // Close the current dialog
      // Show the dialog again after selecting an image
      _submitPicture(context, isRisk: isRisk);
    }
  }

  Future<void> _submitPicture(BuildContext context,
      {required bool isRisk}) async {
    return showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog when clicking outside
      builder: (BuildContext context) {
        Uint8List? imageBytes;
        if (isRisk) {
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
                      'No image selected, please click Reselect and pick an Image.')
                  : Image.memory(imageBytes),
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

  //////////////////////////////////////////////////////////////////////////////////////////////

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

  int stringTimeToMins(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  void clicked(String jobId, bool assigned, String workerId, String dateString,
      String endTime, bool riskSupport) {
    DateTime today = DateTime.now();
    DateTime date = DateFormat('dd-MM-yyyy').parse(dateString);
    TimeOfDay currentTime = TimeOfDay.now();
    String now = currentTime.format(context);
    if (workerId == 'none') {
      // TO DO: re pick worker inform company
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
      setState(() {
        jobConfirmation(context, jobId);
      });
    } else if (riskSupport == false && assigned == true) {
      addRiskSupportPlans(context, jobId);
      // TO DO: risk support update true
    } else if ((today.isAtSameMomentAs(date) &&
            (stringTimeToMins(endTime) > ((8 * 60) + stringTimeToMins(now)))) ||
        date.isAfter(today)) {
      deleteJob(context, jobId);
    } else {
      // TO DO: error message
    }
  }

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
                await deleteJobDb(jobId, true);
                getJobs(widget.companyId, (List<dynamic> jobDetailList) {
                  setState(() {
                    jobList = jobDetailList;
                  });
                });
                Navigator.of(context).pop();
                Flushbar(
                  backgroundColor: Colors.black,
                  message: "Job Deleted!",
                  duration: Duration(seconds: 4),
                ).show(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> profileViewer(BuildContext context, String userId) async {
    dbhandler
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
                        name: name,
                        imgPath: imgPath,
                        experience: '$experience Years Experience',
                        description: description,
                        scale: 2)
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
            padding:
                EdgeInsets.symmetric(horizontal: 20), // Add horizontal padding
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
                  // height: MediaQuery.of(context).size.height * 0.5,
                  // width: MediaQuery.of(context).size.width * 0.9,
                  child: ListView.builder(
                    itemCount: jobList.length,
                    itemBuilder: (context, index) {
                      // Assuming each worker is represented as a Map
                      Map<String, dynamic> job = jobList[index];
                      return InkWell(
                        onTap: () async {
                          setState(() {
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
                          profileViewer(context, job['workerId']);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(20), // between items
                          padding:
                              const EdgeInsets.all(10), // space inside item box
                          decoration: BoxDecoration(
                            color: pickColour(job['assigned'], job['workerId'],
                                job['riskSupport']),
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: DisplayText(
                                text:
                                    "Job: ${index + 1} (Worker ${job['worker']})", //${job['workerId']})", TO DO PUT WORKER NAME
                                fontSize: 20,
                                colour: const Color(0xffffffff)),
                            subtitle: DisplayText(
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
