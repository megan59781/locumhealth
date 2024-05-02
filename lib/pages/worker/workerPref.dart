// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:fyp/templates/dayBut.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/helpBut.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:another_flushbar/flushbar.dart';

class WorkerPreference extends StatefulWidget {
  final String workerId;

  const WorkerPreference({super.key, required this.workerId});

  @override
  State createState() => WorkerPreferenceState();
}

class WorkerPreferenceState extends State<WorkerPreference> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  int? currentMilesVal; // miles selected value
  TimeOfDay selectedTime = TimeOfDay.now();

  // for location retrival
  double lat = 0.0;
  double long = 0.0;
  String currentLocation = "to get";
  final TextEditingController locationController = TextEditingController();

  // specific variables for day and time selection
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

  // updates the day button with the current day + times availability
  Future<void> updateView(String workerId) async {
    dbhandler
        .child('Availability')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        // Explicitly cast to Map<dynamic, dynamic>
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            int dayId = value["day_id"];
            TimeOfDay startTime =
                TimeOfDay.fromDateTime(// convert to TimeOfDay for display
                    DateTime.parse("2024-01-01 ${value["day_start_time"]}"));
            TimeOfDay endTime = TimeOfDay.fromDateTime(
                DateTime.parse("2024-01-01 ${value["day_end_time"]}"));
            switch (dayId) {
              // check each day and set dispay of times from db
              case 1:
                setState(() {
                  selMon = true;
                  monStartTime = startTime;
                  monEndTime = endTime;
                });
                break;
              case 2:
                setState(() {
                  selTue = true;
                  tueStartTime = startTime;
                  tueEndTime = endTime;
                });
                break;
              case 3:
                setState(() {
                  selWed = true;
                  wedStartTime = startTime;
                  wedEndTime = endTime;
                });
                break;
              case 4:
                setState(() {
                  selThu = true;
                  thuStartTime = startTime;
                  thuEndTime = endTime;
                });
                break;
              case 5:
                setState(() {
                  selFri = true;
                  friStartTime = startTime;
                  friEndTime = endTime;
                });
                break;
              case 6:
                setState(() {
                  selSat = true;
                  satStartTime = startTime;
                  satEndTime = endTime;
                });
                break;
              case 7:
                setState(() {
                  selSun = true;
                  sunStartTime = startTime;
                  sunEndTime = endTime;
                });
                break;
              default:
            }
          });
        }
      } else {
        // error handling
      }
    });
    // updates the location text with current location
    dbhandler
        .child('Worker')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .first
        .then((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Assuming there is only one entry, you can access it directly
          var wKey = data.keys.first;
          var wData = data[wKey];

          double lat = wData['latitude'];
          double long = wData['longitude'];
          int miles = wData['miles'];

          String location = await getPlacemarks(lat, long);

          setState(() {
            // set the state of the location and miles
            currentLocation = location;
            currentMilesVal = miles;
          });
        }
      }
    });
  }

  @override // load the state of the widget with the workerId from db
  void initState() {
    super.initState();
    updateView(widget.workerId);
  }

  // function to get the placemarks from the lat and long
  Future<String> getPlacemarks(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      var address = '';

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

      return address; // return adress to display
    } catch (e) {
      return "No Address";
    }
  }

  // function to adjust the availability database
  Future<void> adjustAvailableDb(
      // pass avaibility details
      int dayId,
      String workerId,
      TimeOfDay startTime,
      TimeOfDay endTime,
      bool selected,
      BuildContext context) async {
    dbhandler
        .child("Availability")
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .take(1)
        .listen((event) async {
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        // if already availability in db adjust
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          var existingEntryKey; // main key for the entry
          data.forEach((key, value) {
            if (value["day_id"] == dayId) {
              existingEntryKey = key; // set the key to the existing entry
            }
          });

          if (existingEntryKey != null) {
            // Update existing entry
            if (selected) {
              await dbhandler
                  .child("Availability")
                  .child(existingEntryKey)
                  .update({
                "day_start_time": startTime.format(context),
                "day_end_time": endTime.format(context)
              });
            } else {
              // Remove existing entry if not selected anymore (sel = false)
              await dbhandler
                  .child("Availability")
                  .child(existingEntryKey)
                  .remove();
            }
          } else {
            // if no existing entry add new entry
            if (selected) {
              // Add new entry
              Map<String, dynamic> available = {
                "day_id": dayId,
                "worker_id": workerId,
                "day_start_time": startTime.format(context),
                "day_end_time": endTime.format(context)
              };
              await dbhandler.child("Availability").push().set(available);
            }
          }
        }
      } else {
        if (selected) {
          // Handle case when there are no existing entries at all
          // Add new entry since there's no existing entry for the worker
          Map<String, dynamic> available = {
            "day_id": dayId,
            "worker_id": workerId,
            "day_start_time": startTime.format(context),
            "day_end_time": endTime.format(context)
          };
          await dbhandler.child("Availability").push().set(available);
        }
      }
    });
  }

  // function to update the miles in the database
  Future<void> updateWorkerMilesDb(
      String workerId, int miles, BuildContext context) async {
    dbhandler
        .child('Worker')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .take(1)
        .listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            // update the miles in the db
            dbhandler
                .child("Worker")
                .child(key)
                .update({"miles": miles})
                .then((value) {})
                .catchError((error) {
                  // Error saving to Firebase: $error"
                });
          });
        }
      }
    });
  }

  // function to update the location in the database
  Future<void> updateWorkerLocationDb(
      String workerId, double lat, double long, BuildContext context) async {
    dbhandler
        .child('Worker')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .take(1)
        .listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            dbhandler
                .child("Worker")
                .child(key) // update the location in the db
                .update({"latitude": lat, "longitude": long})
                .then((value) {})
                .catchError((error) {
                  // if this then "Error saving to Firebase: $error"
                });
          });
        }
      } else {
        // if error handle
      }
    });
  }

  // pop-up to adjust or select location
  Future<void> locationSelector(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Location'),
          content: TextField(
            controller: locationController, // controller for location
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
              onPressed: () async {
                Navigator.of(context).pop();
                Map<String, double> coordinates = await getLocationCoordinates(
                    context); // get the coordinates
                double? lat = coordinates['latitude'];
                double? long = coordinates['longitude'];
                _updateLocation(
                    context, lat, long); // update the location in db
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // function to get the coordinates from the location
  Future<Map<String, double>> getLocationCoordinates(
      BuildContext context) async {
    final String location = locationController.text;
    Map<String, double> coordinates = {};

    try {
      List<Location> locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        double lat = locations[0].latitude;
        double long = locations[0].longitude;
        coordinates = {'latitude': lat, 'longitude': long};
      } else {
        // No location found for: $location'
      }
    } catch (e) {
      // Error during geocoding: $e'
    }

    return coordinates; // return the coordinates for database update
  }

  // function to update the location for display
  Future<void> _updateLocation(
      BuildContext context, double? lat, double? long) async {
    if (lat != null && long != null) {
      // if lat and long are not null
      updateWorkerLocationDb(widget.workerId, lat, long, context);
      String location = await getPlacemarks(lat, long);
      setState(() {
        currentLocation = location;
      });
    }
  }

  // function to update the miles for display
  Future<void> _updateMiles(BuildContext context) async {
    int? miles = await _milesSelector(context);
    if (miles != null) {
      updateWorkerMilesDb(widget.workerId, miles, context);
      setState(() {
        currentMilesVal = miles;
      });
    }
  }

  // pop-up to select the miles
  Future<int?> _milesSelector(BuildContext context) async {
    int? selectedMiles = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          int miles = currentMilesVal ?? 1;
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
                            value: miles,
                            minValue: 1, // minimum miles able to travel
                            maxValue: 25, // limit of max miles able to travel
                            step: 1, // go up in 1 miles
                            onChanged: (value) {
                              setState(() {
                                // set the state of the miles
                                miles = value;
                                currentMilesVal = value;
                              });
                            })
                      ]);
                })),
            actions: [
              TextButton(
                child: const DisplayText(
                    text: "Submit", fontSize: 20, colour: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop(miles);
                },
              )
            ],
          );
        });
    return selectedMiles;
  }

  // function handles time selected and update _timeSelector widgit
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

  // pop-up to select the time for day passed in
  Future<void> _timeSelector(BuildContext context, String currentStart,
      String currentEnd, Function(bool, TimeOfDay, TimeOfDay) updateSelected) {
    TextEditingController startTimeController =
        TextEditingController(); // controller for times
    TextEditingController endTimeController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Please Select your Time Availability'),
          content: SizedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DisplayText(
                    text: "Start Time", fontSize: 25, colour: Colors.black),
                const SizedBox(height: 5),
                TextFormField(
                  controller: startTimeController,
                  decoration: InputDecoration(
                    hintText:
                        currentStart, // display the current time or most recent selected time
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
                    hintText:
                        currentEnd, // display the current time or most recent selected time
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
                // remove the time selected
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
                // submit the time selected and chnage format
                TimeOfDay startTime = TimeOfDay.fromDateTime(
                    DateTime.parse("2024-01-01 ${startTimeController.text}"));
                TimeOfDay endTime = TimeOfDay.fromDateTime(
                    DateTime.parse("2024-01-01 ${endTimeController.text}"));
                if (endTime.hour < startTime.hour ||
                    (endTime.hour ==
                            startTime
                                .hour && // check if end time is before start time
                        endTime.minute <= startTime.minute)) {
                  Flushbar(
                    // error message if end time is before start time
                    backgroundColor: Colors.black,
                    message: "End time must be after start time.",
                    duration: const Duration(seconds: 4),
                  ).show(context);
                } else {
                  // update the selected time
                  updateSelected(true, startTime, endTime);
                  Navigator.of(context).pop();
                }
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
      backgroundColor: const Color(0xffFCFAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xffFCFAFC),
        title: const Padding(
          padding: EdgeInsets.only(top: 15), // Add padding above the title
          child: Center(
            child: DisplayText(
                text: "Selected Availability",
                fontSize: 36,
                colour: Colors.black),
          ),
        ),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const DisplayText(
                  text: 'Select Days and Times',
                  fontSize: 30,
                  colour: Color(0xFF280387)),
              const SizedBox(height: 15),
              Row(
                // row of day buttons to update availability values
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
              const SizedBox(height: 30),
              const DisplayText(
                  text: 'Your Current Set Location',
                  fontSize: 30,
                  colour: Color(0xFF280387)),
              const SizedBox(height: 15),
              DisplayText(
                  // shows current set location
                  text: currentLocation,
                  fontSize: 26,
                  colour: Colors.black),
              const SizedBox(height: 15),
              PushButton(
                // button to change location
                buttonSize: 60,
                text: 'Change Location',
                onPress: () async {
                  await locationSelector(context);
                  if (locationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        // error message if location is empty
                        content: Text('Please enter a valid location'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 30),
              DisplayText(
                  // shows current set miles
                  text: "Maximum Miles : ${currentMilesVal ?? 'Not set'}",
                  fontSize: 30,
                  colour: const Color(0xFF280387)),
              const SizedBox(height: 15),
              PushButton(
                  // button to change miles
                  buttonSize: 60,
                  text: 'Change Miles',
                  onPress: () {
                    _updateMiles(context);
                  }),
              const SizedBox(height: 50),
              PushButton(
                // button to submit the preferences
                buttonSize: 70,
                text: 'Submit Preferences',
                onPress: () async {
                  // update the availability in the db
                  await adjustAvailableDb(
                      1, workerId, monStartTime, monEndTime, selMon, context);
                  await adjustAvailableDb(
                      2, workerId, tueStartTime, tueEndTime, selTue, context);

                  await adjustAvailableDb(
                      3, workerId, wedStartTime, wedEndTime, selWed, context);

                  await adjustAvailableDb(
                      4, workerId, thuStartTime, thuEndTime, selThu, context);

                  await adjustAvailableDb(
                      5, workerId, friStartTime, friEndTime, selFri, context);

                  await adjustAvailableDb(
                      6, workerId, satStartTime, satEndTime, selSat, context);

                  await adjustAvailableDb(
                      7, workerId, sunStartTime, sunEndTime, selSun, context);

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        "Availability Updated!"), // success message to user
                  ));
                },
              ),
              const SizedBox(height: 15),
              Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(top: 20, right: 30),
                child: const HelpButton(
                    // help button to show user how to use the page
                    message:
                        'Click the on the days to put the time your avaible for job requets \n\n'
                        'Using the location button to change your location \n\n'
                        'To alter the maximum miles you\'d travel, click the Miles button \n\n'
                        'Click the Submit Preferences button when you\'re done to save',
                    title: "Availability"),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
