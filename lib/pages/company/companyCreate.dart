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
  String currentLocation = "Get Location";

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay.now();

  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();

  List<String> selectedAbilitys = [];
  static const List<String> selections = <String>[
    'First Aid',
    'Manual Handling',
    'Medication Administration',
    'Mental Health Training',
    'Elderly Care Training',
    'Child Care Training',
    'Disability Care Training',
    'Palliative Care Training',
    'Dementia Care Training',
    'Stoma Training',
    'Catheter Training',
    'PEG Feeding Training',
    'Restrained Training',
  ];

  Future<void> abilitySelector(
      BuildContext context, List<String> selections) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Required Abilities'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          final String ability = selections[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 3.0,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selectedAbilitys.contains(ability),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value != null) {
                                        if (value) {
                                          selectedAbilitys.add(ability);
                                        } else {
                                          selectedAbilitys.remove(ability);
                                        }
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  ability,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    decorationStyle: TextDecorationStyle.wavy,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        itemCount: selections.length,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                print(selectedAbilitys);
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
        //address += placemarks.reversed.last.subLocality ?? '';
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
        // address += ', ${placemarks.reversed.last.country ?? ''}';
      }

      //print("Your Address for ($lat, $long) is: $address");

      return address;
    } catch (e) {
      //print("Error getting placemarks: $e");
      return "No Address";
    }
  }

  Future<String> getLocationCoordinates(BuildContext context) async {
    final String location = locationController.text;
    String address = location;
    try {
      List<Location> locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        lat = locations[0].latitude;
        long = locations[0].longitude;
        currentLocation = await getPlacemarks(lat, long);
        setState(() {
          address = currentLocation;
        }); //pass through placemarks
        print(lat);
        print(long);
      } else {
        print('No location found for: $location');
      }
    } catch (e) {
      print('Error during geocoding: $e');
    }
    return address;
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////
  int stringTimeToMins(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

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
      backgroundColor: const Color(0xffFCFAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xffFCFAFC),
        title: const Padding(
          padding: EdgeInsets.only(top: 30), // Add padding above the title
          child: Center(
            child: DisplayText(
                text: 'Create a New Job', fontSize: 36, colour: Colors.black),
          ),
        ),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: Center(
            child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
            const DisplayText(
                text: 'Select Date of the Job',
                fontSize: 30,
                colour: Color(0xFF280387)),
            const SizedBox(height: 15),
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
            const SizedBox(height: 30),
            PushButton(
                buttonSize: 55,
                text: "Select Abilities",
                onPress: () => abilitySelector(context, selections)),
            const SizedBox(height: 30),
            const DisplayText(
                text: 'Select Time of the Job',
                fontSize: 30,
                colour: Color(0xFF280387)),
            const SizedBox(height: 15),
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
            const SizedBox(height: 30),
            const DisplayText(
                text: 'Select the Job Location',
                fontSize: 30,
                colour: Color(0xFF280387)),
            Padding(
              padding: const EdgeInsets.all(15),
              child: DateTimeText(
                text: currentLocation,
                icon: const Icon(Icons.map_outlined),
                onPress: () async {
                  await locationSelector(context);
                  String location = await getLocationCoordinates(context);
                  setState(() {
                    currentLocation = location;
                    if (currentLocation.isEmpty) {
                      currentLocation = "Get Location";
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            PushButton(
              buttonSize: 70,
              text: 'Create Job',
              onPress: () async {
                int timeDif = stringTimeToMins(endTime.format(context)) -
                    stringTimeToMins(startTime.format(context));
                if (lat == 0.0 || long == 0.0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid location'),
                    ),
                  );
                } else if (timeDif < 29) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please make sure the job ends at least 30 minutes after it starts'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Job Created Successfully'),
                    ),
                  );
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
                                  companyId: widget.companyId,
                                  jobId: jobId,
                                  abilityList: selectedAbilitys)));
                    });
                  });
                }
              },
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
}
