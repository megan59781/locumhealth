import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/pages/company/companyWorkerList.dart';
import 'package:fyp/templates/dateTimeText.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CompanyCreateJob extends StatefulWidget {
  final String companyId;

  const CompanyCreateJob({super.key, required this.companyId});

  @override
  State createState() => CompanyCreateJobState();
}

class CompanyCreateJobState extends State<CompanyCreateJob> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();

  final TextEditingController locationController = TextEditingController();
  double lat = 0.0;
  double long = 0.0;
  String currentLocation = "get location";

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay.now();

  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();

  Future<void> _dateSelector(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now().add(const Duration(days: 1)),
        lastDate: DateTime(2024, 6));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<TimeOfDay> _selectTime(TextEditingController controller) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (newTime != null) {
      setState(() {
        selectedTime = newTime;
        controller.text = selectedTime.format(context);
      });
    }
    return selectedTime;
  }

  Future<void> _timeSelector(BuildContext context, String currentTime,
      Function(TimeOfDay) updateSelected) {
    TextEditingController timeController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Please Select the Time'),
          content: SizedBox(
            height: MediaQuery.of(context).size.width * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const DisplayText(
                    text: "Selected Time", fontSize: 25, colour: Colors.black),
                const SizedBox(height: 5),
                TextFormField(
                  controller: timeController,
                  decoration: InputDecoration(
                    hintText: currentTime,
                    border: const OutlineInputBorder(),
                  ),
                  onTap: () => _selectTime(timeController),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                updateSelected(TimeOfDay.now());
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 120),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Submit'),
              onPressed: () {
                // TO DO SAVE TIMES
                TimeOfDay currentTime = TimeOfDay.fromDateTime(
                    DateTime.parse("2024-01-01 ${timeController.text}"));
                updateSelected(currentTime);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

//////////////////////////////////////////////////////////////////////////////////////////////////////
  ///
  Future<void> locationSelector(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Location'),
          content: TextField(
            controller: locationController,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                getLocationCoordinates(context);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<String> getPlacemarks(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      var address = '';

      if (placemarks.isNotEmpty) {
        address += placemarks.reversed.last.subLocality ?? '';
        //address += ', ${placemarks.reversed.last.locality ?? ''}';
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

  Future<void> getLocationCoordinates(BuildContext context) async {
    final String location = locationController.text;

    try {
      List<Location> locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        lat = locations[0].latitude;
        long = locations[0].longitude;
        currentLocation =
            await getPlacemarks(lat, long); //pass through placemarks
        print(lat);
        print(long);
      } else {
        print('No location found for: $location');
      }
    } catch (e) {
      print('Error during geocoding: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////

  Future<void> addJobDb(
      String date,
      String companyId,
      TimeOfDay startTime,
      TimeOfDay endTime,
      double lat,
      double long,
      BuildContext context,
      Function(String theJobId) getJobId) async {
    String jobId = const Uuid().v4();

    Map<String, dynamic> job = {
      "job_id": jobId,
      "company_id": companyId,
      "date": date,
      "job_start_time": startTime.format(context),
      "job_end_time": endTime.format(context),
      "latitude": lat,
      "longitude": long,
    };

    try {
      await dbhandler.child("Jobs").push().set(job);
      getJobId(jobId);
      //Navigator.of(context).pop();
    } catch (error) {
      print("Error saving to Firebase: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateString = DateFormat('dd-MM-yyyy').format(selectedDate);
    String companyId = widget.companyId;
    String jobId = "";
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 10),
            const DisplayText(
                text: 'Create a New Job', fontSize: 34, colour: Colors.black),
            const SizedBox(height: 50),
            const DisplayText(
                text: 'Select Date of the Job',
                fontSize: 30,
                colour: Colors.deepPurple),
            const SizedBox(height: 10),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const DisplayText(
                      text: 'Date: ', fontSize: 30, colour: Colors.black),
                  DateTimeText(
                    text: dateString,
                    icon: const Icon(Icons.date_range_outlined),
                    onPress: () => _dateSelector(context),
                  ),
                ]),
            const SizedBox(height: 50),
            const DisplayText(
                text: 'Select Time of the Job',
                fontSize: 30,
                colour: Colors.deepPurple),
            const SizedBox(height: 10),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const DisplayText(
                      text: 'Start:', fontSize: 30, colour: Colors.black),
                  DateTimeText(
                      text: startTime.format(context),
                      icon: const Icon(Icons.update_outlined),
                      onPress: () =>
                          _timeSelector(context, startTime.format(context),
                              (currentTime) {
                            setState(() {
                              startTime = currentTime;
                            });
                          }))
                ]),
            const SizedBox(height: 20),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const DisplayText(
                      text: ' End: ', fontSize: 30, colour: Colors.black),
                  DateTimeText(
                    text: endTime.format(context),
                    icon: const Icon(Icons.history_outlined),
                    onPress: () => _timeSelector(
                        context, endTime.format(context), (currentTime) {
                      setState(() {
                        endTime = currentTime;
                      });
                    }),
                  ),
                ]),
            const SizedBox(height: 20),
            const DisplayText(
                text: 'Select the Job Location',
                fontSize: 30,
                colour: Colors.deepPurple),
            Padding(
              padding: const EdgeInsets.all(15),
              child: DateTimeText(
                text: currentLocation,
                icon: const Icon(Icons.map_outlined),
                onPress: () {
                  locationSelector(context);
                },
              ),
            ),
            const SizedBox(height: 30),
            PushButton(
              buttonSize: 60,
              text: 'Create Job',
              onPress: () async {
                addJobDb(dateString, companyId, startTime, endTime, lat, long,
                    context, (value) {
                  setState(() {
                    jobId = value;
                    print("check here");
                    print(jobId);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CompanyWorkerList(
                                companyId: widget.companyId, jobId: jobId)));
                  });
                });
              },
            ),
          ]),
        ),
      ),
    );
  }
}
