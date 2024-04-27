import 'dart:async';

import 'package:fyp/templates/dayBut.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
//import 'package:geolocator/geolocator.dart';
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
  int? currentMilesVal;
  TimeOfDay selectedTime = TimeOfDay.now();
  double lat = 0.0;
  double long = 0.0;

  String currentLocation = "to get";

  final TextEditingController locationController = TextEditingController();

  //"get location";

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

  Future<void> updateView(String workerId) async {
    // updates the day button with the current day + times availability
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
            TimeOfDay startTime = TimeOfDay.fromDateTime(
                DateTime.parse("2024-01-01 ${value["day_start_time"]}"));
            TimeOfDay endTime = TimeOfDay.fromDateTime(
                DateTime.parse("2024-01-01 ${value["day_end_time"]}"));
            switch (dayId) {
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
        // Handle error
        print('error');
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
            currentLocation = location;
            currentMilesVal = miles;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    updateView(widget.workerId);
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

  Future<void> adjustAvailableDb(
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
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          var existingEntryKey;
          data.forEach((key, value) {
            if (value["day_id"] == dayId) {
              existingEntryKey = key;
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
              // Remove existing entry
              await dbhandler
                  .child("Availability")
                  .child(existingEntryKey)
                  .remove();
            }
          } else {
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
          // Handle case when there are no existing entries
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
            dbhandler
                .child("Worker")
                .child(key)
                .update({"miles": miles}).then((value) {
              //Navigator.of(context).pop();
            }).catchError((error) {
              print("Error saving to Firebase: $error");
            });
          });
        }
      }
    });
  }

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
                .child(key)
                .update({"latitude": lat, "longitude": long}).then((value) {
              //Navigator.of(context).pop();
            }).catchError((error) {
              print("Error saving to Firebase: $error");
            });
          });
        }
      } else {
        // Handle error
        print('error');
      }
    });
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
              onPressed: () async {
                Navigator.of(context).pop();
                Map<String, double> coordinates =
                    await getLocationCoordinates(context);
                double? lat = coordinates['latitude'];
                double? long = coordinates['longitude'];
                _updateLocation(context, lat, long);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, double>> getLocationCoordinates(
      BuildContext context) async {
    final String location = locationController.text;
    Map<String, double> coordinates = {};

    try {
      List<Location> locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        double lat = locations[0].latitude;
        double long = locations[0].longitude;
        //currentLocation = await getPlacemarks(lat, long); //pass through placemarks
        // print(lat);
        // print(long);
        coordinates = {'latitude': lat, 'longitude': long};
      } else {
        print('No location found for: $location');
      }
    } catch (e) {
      print('Error during geocoding: $e');
    }

    return coordinates;
  }

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

  Future<void> _updateMiles(BuildContext context) async {
    int? miles = await _milesSelector(context);
    if (miles != null) {
      updateWorkerMilesDb(widget.workerId, miles, context);
      setState(() {
        currentMilesVal = miles;
      });
    }
  }

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
                            minValue: 1,
                            maxValue: 25,
                            step: 1,
                            onChanged: (value) {
                              setState(() {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                TimeOfDay startTime = TimeOfDay.fromDateTime(
                    DateTime.parse("2024-01-01 ${startTimeController.text}"));
                TimeOfDay endTime = TimeOfDay.fromDateTime(
                    DateTime.parse("2024-01-01 ${endTimeController.text}"));
                if (endTime.hour < startTime.hour ||
                    (endTime.hour == startTime.hour &&
                        endTime.minute <= startTime.minute)) {
                  Flushbar(
                    backgroundColor: Colors.black,
                    message: "End time must be after start time.",
                    duration: Duration(seconds: 4),
                  ).show(context);
                } else {
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
                  text: currentLocation, fontSize: 26, colour: Colors.black),
              const SizedBox(height: 15),
              PushButton(
                buttonSize: 60,
                text: 'Change Location', // TO DO MAKE SHOW MAIN LOCATION
                onPress: () async {
                  await locationSelector(context);
                  if (locationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid location'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 30),
              DisplayText(
                  text: "Maximum Miles : ${currentMilesVal ?? 'Not set'}",
                  fontSize: 30,
                  colour: Color(0xFF280387)),
              const SizedBox(height: 15),
              PushButton(
                  buttonSize: 60,
                  text: 'Change Miles',
                  onPress: () {
                    _updateMiles(context);
                  }),
              const SizedBox(height: 50),
              PushButton(
                buttonSize: 70,
                text: 'Submit Preferences',
                onPress: () async {
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
                    content: Text("Availability Updated!"),
                  ));
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ));
  }
}
