import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:geocoding/geocoding.dart';

class CompanyJob extends StatefulWidget {
  final String companyId;
  const CompanyJob({super.key, required this.companyId});

  @override
  State<CompanyJob> createState() => CompanyJobState();
}

class CompanyJobState extends State<CompanyJob> {
  List<dynamic> jobList = [];
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    String companyId = widget.companyId;
    getJobs(companyId, (List<dynamic> jobDetailList) {
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
        address += ', ${placemarks.reversed.last.subAdministrativeArea ?? ''}';
        //address += ', ${placemarks.reversed.last.administrativeArea ?? ''}';
        address += ', ${placemarks.reversed.last.postalCode ?? ''}';
        address += ', ${placemarks.reversed.last.country ?? ''}';
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
            String workerId = value['worker_id'];
            jobIdList.add({"jobId": jobId, "workerId": workerId});
          });

          List<Map<String, dynamic>> jobDetailsList = [];
          print("jobIdList: $jobIdList");

          for (var job in jobIdList) {
            String jobId = job['jobId'];
            String workerId = job['workerId'];
            print("$jobId            w:$workerId");
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
                  var jobStartTime = jobData['day_start_time'];
                  var jobEndTime = jobData['day_end_time'];

                  // TO DO CACLULATE AND DISPLAY LOCTAION WITH JOB
                  double lat = jobData['latitude'];
                  double long = jobData['longitude'];

                  String location = await getPlacemarks(lat, long);
                  print(location);

                  jobDetailsList.add({
                    'jobId': jobId,
                    'workerId': workerId,
                    'date': date,
                    'startTime': jobStartTime,
                    'endTime': jobEndTime,
                    'location': location,
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
                        print('Clicked on worker: ${job['workerId']} location of job: ${job['location']} ');
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
                              text: "job: $index",
                              fontSize: 24,
                              colour: Colors.black),
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
