import 'package:fyp/templates/dayBut.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:numberpicker/numberpicker.dart';

class WorkerPreference extends StatefulWidget {
  final String workerId;

  const WorkerPreference({super.key, required this.workerId});

  @override
  State createState() => WorkerPreferenceState();
}

class WorkerPreferenceState extends State<WorkerPreference> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  int currentMilesVal = 1;
  TimeOfDay selectedTime = TimeOfDay.now();

  bool selMon = false;
  TimeOfDay monStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay monEndTime = const TimeOfDay(hour: 0, minute: 0);
  bool selTue = false;
  TimeOfDay tueStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay tueEndTime = const TimeOfDay(hour: 0, minute: 0);
  bool selWed = false;
  TimeOfDay wedStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay wedEndTime = const TimeOfDay(hour: 0, minute: 0);
  bool selThu = false;
  TimeOfDay thuStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay thuEndTime = const TimeOfDay(hour: 0, minute: 0);
  bool selFri = false;
  TimeOfDay friStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay friEndTime = const TimeOfDay(hour: 0, minute: 0);
  bool selSat = false;
  TimeOfDay satStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay satEndTime = const TimeOfDay(hour: 0, minute: 0);
  bool selSun = false;
  TimeOfDay sunStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay sunEndTime = const TimeOfDay(hour: 0, minute: 0);

  Future<List<double>> getCurrentLatLong() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true,
      );

      double latitude = position.latitude;
      double longitude = position.longitude;

      return [latitude, longitude];
    } catch (e) {
      //print(e);
      // You might want to handle the error accordingly, for example, returning a default location.
      return [0.0, 0.0];
    }
  }

  // Future<Map<String, String>> getCurrentSLocation() async {
  //   try {
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.best,
  //       forceAndroidLocationManager: true,
  //     );

  //     String latitude = position.latitude.toString();
  //     String longitude = position.longitude.toString();

  //     return {'latitude': latitude, 'longitude': longitude};
  //   } catch (e) {
  //     print(e);
  //     // You might want to handle the error accordingly, for example, returning default strings.
  //     return {'latitude': '0.0', 'longitude': '0.0'};
  //   }
  // }

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

  Future<void> addAvailableDb(int dayId, String workerId, TimeOfDay startTime,
      TimeOfDay endTime, BuildContext context) async {
    Map<String, dynamic> available = {
      "day_id": dayId,
      "worker_id": workerId,
      "day_start_time": startTime.format(context),
      "day_end_time": endTime.format(context),
      "miles": currentMilesVal,
    };

    try {
      await dbhandler.child("Availability").push().set(available);
      //Navigator.of(context).pop();
    } catch (error) {
      print("Error saving to Firebase: $error");
    }
  }

  Future<int?> _milesSelector(BuildContext context) async {
    return showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const DisplayText(
                text: "Select the maxium miles",
                fontSize: 20,
                colour: Colors.black),
            content: SizedBox(
                height: MediaQuery.of(context).size.width * 0.6,
                child: StatefulBuilder(builder: (context, setState) {
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        NumberPicker(
                          selectedTextStyle: const TextStyle(
                              color: Colors.deepPurple, fontSize: 20),
                          value: currentMilesVal,
                          minValue: 1,
                          maxValue: 25,
                          step: 1,
                          onChanged: (value) =>
                              setState(() => currentMilesVal = value),
                        )
                      ]);
                })),
            actions: [
              TextButton(
                child: const DisplayText(
                    text: "Submit", fontSize: 20, colour: Colors.black),
                onPressed: () {
                  // TO DO SAVE
                  Navigator.of(context).pop(currentMilesVal);
                },
              )
            ],
          );
        });
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

  Future<void> _timeSelector(BuildContext context, String currentStart,
      String currentEnd, Function(bool, TimeOfDay, TimeOfDay) updateSelected) {
    TextEditingController startTimeController = TextEditingController();
    TextEditingController endTimeController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Please Select your Time Availability'),
          content: SizedBox(
            height: MediaQuery.of(context).size.width * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const DisplayText(
                    text: "Start Time", fontSize: 25, colour: Colors.black),
                const SizedBox(height: 5),
                TextFormField(
                  controller: startTimeController,
                  decoration: InputDecoration(
                    hintText: currentStart,
                    border: const OutlineInputBorder(),
                  ),
                  onTap: () => _selectTime(startTimeController),
                ),
                const SizedBox(height: 20),
                const DisplayText(
                    text: "End Time", fontSize: 25, colour: Colors.black),
                const SizedBox(height: 5),
                TextFormField(
                  controller: endTimeController,
                  decoration: InputDecoration(
                    hintText: currentEnd,
                    border: const OutlineInputBorder(),
                  ),
                  onTap: () => _selectTime(endTimeController),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Remove'),
              onPressed: () {
                TimeOfDay emptyTime = const TimeOfDay(hour: 0, minute: 0);
                updateSelected(false, emptyTime, emptyTime);
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
                TimeOfDay startTime = TimeOfDay.fromDateTime(
                    DateTime.parse("2024-01-01 ${startTimeController.text}"));
                TimeOfDay endTime = TimeOfDay.fromDateTime(
                    DateTime.parse("2024-01-01 ${endTimeController.text}"));
                updateSelected(true, startTime, endTime);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String workerId = widget.workerId;
    return MaterialApp(
        home: Scaffold(
      backgroundColor: Colors.brown[100],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const DisplayText(
                  text: "Select Your Work Availability",
                  fontSize: 28,
                  colour: Colors.black),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 7),
                  Expanded(
                      child: DayButton(
                          text: "Mon",
                          selected: selMon,
                          onPress: () => _timeSelector(
                                  context,
                                  monStartTime.format(context),
                                  monEndTime.format(context),
                                  (value, startTime, endTime) {
                                setState(() {
                                  selMon = value;
                                  monStartTime = startTime;
                                  monEndTime = endTime;
                                });
                              }))),
                  Expanded(
                      child: DayButton(
                          text: "Tue",
                          selected: selTue,
                          onPress: () => _timeSelector(
                                  context,
                                  tueStartTime.format(context),
                                  tueEndTime.format(context),
                                  (value, startTime, endTime) {
                                setState(() {
                                  selTue = value;
                                  tueStartTime = startTime;
                                  tueEndTime = endTime;
                                });
                              }))),
                  Expanded(
                    child: DayButton(
                        text: "Wed",
                        selected: selWed,
                        onPress: () => _timeSelector(
                                context,
                                wedStartTime.format(context),
                                wedEndTime.format(context),
                                (value, startTime, endTime) {
                              setState(() {
                                selWed = value;
                                wedStartTime = startTime;
                                wedEndTime = endTime;
                              });
                            })),
                  ),
                  Expanded(
                    child: DayButton(
                        text: "Thu",
                        selected: selThu,
                        onPress: () => _timeSelector(
                                context,
                                thuStartTime.format(context),
                                thuEndTime.format(context),
                                (value, startTime, endTime) {
                              setState(() {
                                selThu = value;
                                thuStartTime = startTime;
                                thuEndTime = endTime;
                              });
                            })),
                  ),
                  Expanded(
                    child: DayButton(
                        text: "Fri",
                        selected: selFri,
                        onPress: () => _timeSelector(
                                context,
                                friStartTime.format(context),
                                friEndTime.format(context),
                                (value, startTime, endTime) {
                              setState(() {
                                selFri = value;
                                friStartTime = startTime;
                                friEndTime = endTime;
                              });
                            })),
                  ),
                  Expanded(
                    child: DayButton(
                        text: "Sat",
                        selected: selSat,
                        onPress: () => _timeSelector(
                                context,
                                satStartTime.format(context),
                                satEndTime.format(context),
                                (value, startTime, endTime) {
                              setState(() {
                                selSat = value;
                                satStartTime = startTime;
                                satEndTime = endTime;
                              });
                            })),
                  ),
                  Expanded(
                    child: DayButton(
                        text: "Sun",
                        selected: selSun,
                        onPress: () => _timeSelector(
                                context,
                                sunStartTime.format(context),
                                sunEndTime.format(context),
                                (value, startTime, endTime) {
                              setState(() {
                                selSun = value;
                                sunStartTime = startTime;
                                sunEndTime = endTime;
                              });
                            })),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              const DisplayText(
                text: 'This is your set Location',
                fontSize: 20,
                colour: Colors.black,
              ),
              FutureBuilder<List<double>>(
                future: getCurrentLatLong(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError || snapshot.data == null) {
                    return const DisplayText(
                      text: 'Error getting location',
                      fontSize: 20,
                      colour: Colors.deepPurple,
                    );
                  } else {
                    double lat = snapshot.data![0];
                    double long = snapshot.data![1];
                    return FutureBuilder<String>(
                      future: getPlacemarks(lat, long),
                      builder: (context, locateSnapshot) {
                        if (locateSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (locateSnapshot.hasError) {
                          return Text('Error: ${locateSnapshot.error}');
                        } else {
                          // Data has been fetched successfully, use locateSnapshot.data as a String
                          return DisplayText(
                            text: locateSnapshot.data!,
                            fontSize: 20,
                            colour: Colors.deepPurple,
                          );
                        }
                      },
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              PushButton(
                  buttonSize: 60,
                  text: 'My location is wrong',
                  onPress: () => null),
              const SizedBox(height: 50),
              DisplayText(
                  text: "Maxium Miles Traveled: $currentMilesVal",
                  fontSize: 20,
                  colour: Colors.black),
              const SizedBox(height: 20),
              PushButton(
                  buttonSize: 60,
                  text: 'Change Miles',
                  onPress: () {
                    _milesSelector(context);
                    setState(() {
                      currentMilesVal;
                    });
                  }),
              const SizedBox(height: 50),
              PushButton(
                buttonSize: 70,
                text: 'Submit Preferences',
                onPress: () async {
                  if (selMon) {
                    addAvailableDb(1, workerId, monStartTime, monEndTime, context);
                  }
                  if (selTue) {
                    addAvailableDb(2, workerId, tueStartTime, tueEndTime, context);
                  }
                  if (selWed) {
                    addAvailableDb(3, workerId, wedStartTime, wedEndTime, context);
                  }
                  if (selThu) {
                    addAvailableDb(4, workerId, thuStartTime, thuEndTime, context);
                  }
                  if (selFri) {
                    addAvailableDb(5, workerId, friStartTime, friEndTime, context);
                  }
                  if (selSat) {
                    addAvailableDb(6, workerId, satStartTime, satEndTime, context);
                  }
                  if (selSun) {
                    addAvailableDb(7, workerId, sunStartTime, sunEndTime, context);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ));
  }
}
