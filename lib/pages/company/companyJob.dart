import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/pages/company/companyWorkerList.dart';
import 'package:fyp/templates/displayText.dart';
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
                });
                Navigator.of(context).pop();
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
                  await addRiskSupportDb(jobId);
                  await subitRiskSupport(jobId);
                  // addRiskSupportDb(jobId);
                  // subitRiskSupport(jobId);
                } else {
                  // TO DO: error message
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
      return Colors.yellow[400]!;
    } else if (assigned) {
      return Colors.lightGreen[400]!;
    } else if (workerId == "none") {
      return Colors.pink[300]!;
    } else {
      return Colors.deepOrange[600]!;
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
    } else {
      // TO DO: error message say waiting for worker to accept
    }
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
                    const SizedBox(height: 5,),
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
                        profileViewer(context,
                            "AIhwMbH3ExbIWVzAITBTBk1GX813"); //job['workerId']);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5), // between items
                        padding:
                            const EdgeInsets.all(10), // space inside item box
                        decoration: BoxDecoration(
                          color: pickColour(job['assigned'], job['workerId'],
                              job['riskSupport']),
                          border: Border.all(color: Colors.deepPurple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: DisplayText(
                              text:
                                  "Job: ${index + 1} (Worker ${job['worker']})", //${job['workerId']})", TO DO PUT WORKER NAME
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
