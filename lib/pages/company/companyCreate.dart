import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/pages/company/companyWorkerList.dart';
import 'package:fyp/templates/dateTimeText.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/helpBut.dart';
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

  // Variables for location retrival
  final TextEditingController locationController = TextEditingController();
  double lat = 0.0;
  double long = 0.0;
  String currentLocation = "Get Location";

  // Variables for date and time selection
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();

  // List for Ability selection - same as workers
  List<String> selectedAbilitys = [];
  static const List<String> selections = <String>[ // IF UPDATED HERE ALSO UPDATE IN WORKERABILITY
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

  // Pop-up that allows the user to select the abilities required for the job
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
                                    setState(() { // Update the state of the checkbox to update the list
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
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Date Selector pop-up that allows the user to select the date of the job
  Future<void> _dateSelector(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now().add(const Duration(days: 1)),
        lastDate: DateTime(2024, 6));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked; // Update the selected date variable
      });
    }
  }
  
  // Time Selector controller that allows the user to select the start and end time of the job
  // Called within timeSelector 
  Future<TimeOfDay> _selectTime(TextEditingController controller) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (newTime != null) {
      setState(() {
        selectedTime = newTime; // Update the selected time variable and the text field
        controller.text = selectedTime.format(context);
      });
    }
    return selectedTime;
  }

  // Time Selector pop-up that allows the user to select the start and end time of the job
  // Passes current time which is start or end time and function to update the selected time
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
                    hintText: currentTime, // Display the currently selected time or last selected
                    border: const OutlineInputBorder(),
                  ),
                  onTap: () => _selectTime(timeController), // Call the time selector to update the text field
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
                TimeOfDay currentTime = TimeOfDay.fromDateTime( // converts to date text to save format to db
                    DateTime.parse("2024-01-01 ${timeController.text}"));
                updateSelected(currentTime); // updates the current time in widget build
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Location Selector pop-up that allows the user to enter the location of the job and returns the coordinates
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
                getLocationCoordinates(context); // Get the coordinates of the location entered
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Get the placemarks of the location entered
  Future<String> getPlacemarks(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long); // gets placemark from coordinates

      var address = ''; // Get the address from the placemark

      if (placemarks.isNotEmpty) { // only keep the address if it is not empty
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
      return address; // address bult up of sublocality and postal code
    } catch (e) {
      // Error getting placemarks: $e
      return "No Address";
    }
  }

  // Get the coordinates of the location entered
  Future<String> getLocationCoordinates(BuildContext context) async {
    final String location = locationController.text; // Get the location from the text in location pop-up text field
    String address = location;
    try {
      List<Location> locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        lat = locations[0].latitude;
        long = locations[0].longitude;
        currentLocation = await getPlacemarks(lat, long);
        setState(() {
          address = currentLocation; // Update the current location in the widget build
        }); 
      } else {
        // No location found
      }
    } catch (e) {
      // Error with geocoding
    }
    return address;
  }

  // Convert time string to minutes for comparing time
  int stringTimeToMins(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes; // returns total minuites of time
  }

  // Add the job to the database with details entered
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
    } catch (error) {}
  }

  @override
  Widget build(BuildContext context) {
    String dateString = DateFormat('dd-MM-yyyy').format(selectedDate); // Format the date to display
    String companyId = widget.companyId; // simplifys calling
    String jobId = ""; // initialise job id which updates once added to db
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
        automaticallyImplyLeading: false, // Remove the back button of title
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 25),
                const DisplayText(
                    text: 'Select Date of the Job',
                    fontSize: 30,
                    colour: Color(0xFF280387)),
                const SizedBox(height: 10),
                Row( // Display the date and calendar icon for selecting the date
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
                const SizedBox(height: 25),
                PushButton( // Button to select the abilities required for the job
                    buttonSize: 60,
                    text: "Select Abilities",
                    onPress: () => abilitySelector(context, selections)),
                const SizedBox(height: 25),
                const DisplayText(
                    text: 'Select Time of the Job',
                    fontSize: 30,
                    colour: Color(0xFF280387)),
                const SizedBox(height: 10),
                Row( // Display the start time and clock icons for selecting the time
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
                Row( // Display the end time and clock icons for selecting the time
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
                    colour: Color(0xFF280387)),
                SizedBox( // Display the location and location icon for selecting the location
                  width: 350,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
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
                ),
                const SizedBox(height: 30),
                PushButton( // Button to create the job with the details entered and add to db
                  buttonSize: 70,
                  text: 'Create Job',
                  onPress: () async {
                    int timeDif = stringTimeToMins(endTime.format(context)) -
                        stringTimeToMins(startTime.format(context));
                    if (lat == 0.0 || long == 0.0) { // Check if location is entered if not error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid location'),
                        ),
                      );
                    } else if (timeDif < 29) { // Check if the job is at least 30 minutes long if not error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please make sure the job ends at least 30 minutes after it starts'),
                        ),
                      );
                    } else { // If all details are entered correctly add the job to the db
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job Created Successfully'),
                        ),
                      );
                      addJobDb(dateString, companyId, startTime, endTime, lat,
                          long, context, (value) {
                        setState(() {
                          jobId = value;
                          Navigator.push(
                              context,
                              MaterialPageRoute( // Navigate to the worker list page to assign workers to the job
                                  builder: (context) => CompanyWorkerList(
                                      companyId: widget.companyId,
                                      jobId: jobId,
                                      abilityList: selectedAbilitys)));
                        });
                      });
                    }
                  },
                ),
                const SizedBox(height: 5),
                Container( // Help button to explain to user how to create a job
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(top: 20, right: 30),
                  child: const HelpButton(
                      message:
                          'Choose the job date by clicking the calendar icon\n\n'
                          'Using the ability button select the required abilities \n\n'
                          'Select the job start and end time by clicking the clock icons.\n\n'
                          'Select the location by clicking the location button and searching for where the job is.\n\n'
                          'Click the Create Job button when you\'re done.',
                      title: "Job Creation"),
                ),
                const SizedBox(height: 25),
              ]),
        ),
      ),
    );
  }
}
