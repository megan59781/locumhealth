import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/pages/login.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/helpBut.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:google_sign_in/google_sign_in.dart';

class WorkerSettings extends StatefulWidget {
  final String workerId;

  const WorkerSettings({super.key, required this.workerId});

  @override
  State createState() => WorkerSettingsState();
}

class WorkerSettingsState extends State<WorkerSettings> {
  // Firebase Authentication and Google Sign In to sign out
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();

  // Default values if the profile is empty
  String name = " First Last Name ";
  String imgPath = "default";
  int experience = 0;
  String description = "No Description";
  final TextEditingController textController =
      TextEditingController(); // Text controller for the text field

  @override
  void initState() {
    super.initState();
    setState(() {
      // get profile details
      getProfile(widget.workerId);
    });
  }

  // Sign out function
  Future<void> signOut() async {
    await _auth.signOut().then((_) {
      _googleSignIn.signOut();

      Navigator.push(
          // Navigate to the login page
          context,
          MaterialPageRoute(builder: (context) => const Login()));
    });
  }

  // Get the profile of the worker from db
  Future<void> getProfile(String userId) async {
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
          setState(() {
            name = pData['name'];
            imgPath = pData['img'];
            experience = pData['experience'];
            description = pData['description'];
          });
        }
      }
    });
  }

  // Update the profile of the worker with specific item and value
  // item is db key to update and value is dynamic
  Future<void> updateProfile(String item, dynamic value) async {
    dbhandler
        .child('Profiles')
        .orderByChild('user_id')
        .equalTo(widget.workerId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          var profileKey = data.keys.first; // update profile
          await dbhandler.child('Profiles').child(profileKey).update({
            item: value,
          });
          // profile works here
        }
      } else {
        // No Profile Found
      }
    });
  }

  // pop-up to update the image of gennder
  Future<void> genderChanger(BuildContext context, String value) async {
    String dropdownValue = value;

    // Dropdown items
    List<String> dropdownItems = [
      'default',
      'male',
      'female',
      'non-binary',
    ];

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Change Selected Gender"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: dropdownValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!; // set the new value
                      });
                    },
                    items: dropdownItems // map the items to the dropdown
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
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
                    await updateProfile(
                        "img", dropdownValue); // update the profile db

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Gender Updated!"), // show message
                    ));
                  },
                  child: const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // pop-up to update the profile with the item and value ALL BUT IMAGE
  Future<void> profileChanger(
      BuildContext context, String title, String item, dynamic value) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Change $title"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(labelText: value),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  value = textController.text;
                });
                if (item == "experience") {
                  value = int.parse(value);
                }
                await updateProfile(item, value); // update the profile db
                textController.clear();
                Navigator.of(context).pop(value);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("$item Updated!"), // show message
                ));
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  // Delete the worker from the database
  Future<void> deleteWorker(String workerId) async {
    dbhandler
        .child('Worker') // delete worker
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          var workerKey = data.keys.first;
          dbhandler.child('Worker').child(workerKey).remove();
        }
      }
    });
    dbhandler // delete all worker availabilitys
        .child('Availability')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .listen((DatabaseEvent event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            var availabilityKey = key;
            dbhandler.child('Availability').child(availabilityKey).remove();
          });
        }
      }
    });
    dbhandler // delete all worker ability
        .child('Ability')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Assuming there is only one entry, you can access it directly
          var workerKey = data.keys.first;
          dbhandler.child('Ability').child(workerKey).remove();
        }
      }
    });
    dbhandler // delete all worker profile
        .child('Profiles')
        .orderByChild('user_id')
        .equalTo(workerId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Assuming there is only one entry, you can access it directly
          var workerKey = data.keys.first;
          dbhandler.child('Profile').child(workerKey).remove();
        }
      }
    });
  }

  // Unassign all jobs from the worker
  Future<void> unassignJobs(String workerId) async {
    List<String> jobIdList = [];

    await dbhandler
        .child('Assigned Jobs')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .once()
        .then((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            String jobId = value['job_id'];
            jobIdList.add(jobId);
          });
        }
      }
    });

    for (String jobId in jobIdList) {
      await dbhandler
          .child('Assigned Jobs')
          .orderByChild('job_id')
          .equalTo(jobId)
          .once()
          .then((event) async {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic>? data =
              event.snapshot.value as Map<dynamic, dynamic>?;

          if (data != null) {
            data.forEach((key, value) async {
              var assignedJobKey = key;
              await dbhandler
                  .child('Assigned Jobs')
                  .child(assignedJobKey)
                  .update({
                'worker_id': "none",
                'worker_accepted': false,
              });
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xffFCFAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xffFCFAFC),
          title: const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: DisplayText(
                  text: "Settings", fontSize: 36, colour: Colors.black),
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
              const SizedBox(height: 55),
              PushButton(
                  // Change Name button
                  buttonSize: 70,
                  text: "Change Name",
                  onPress: () =>
                      profileChanger(context, "Profile Name", "name", name)),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70,
                  text: "Change Gender", // change genderimage button
                  onPress: () => genderChanger(context, imgPath)),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70,
                  text: "Change Experience", // change experience button
                  onPress: () => profileChanger(context, "Years of Experience",
                      "experience", experience.toString())),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70, // change description button
                  text: "Change Description",
                  onPress: () => profileChanger(context, "About you summary",
                      "description", description)),
              const SizedBox(height: 25),
              PushButton(
                // delete account button
                buttonSize: 70,
                text: "Delete Account",
                onPress: () async => {
                  setState(() async {
                    // delete account and assigned data
                    await unassignJobs(widget.workerId);
                    await deleteWorker(widget.workerId);
                  }),
                  // await _auth.signOut().then((_) { // sign out
                  //   _googleSignIn.signOut();
                  // }),
                  Navigator.push(context, // navigate to login
                      MaterialPageRoute(builder: (context) => const Login())),
                },
              ),
              const SizedBox(height: 25),
              PushButton( // sign out button
                  buttonSize: 70, text: "Sign Out", onPress: () => signOut()),
              const SizedBox(height: 25),
              Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(top: 20, right: 30),
                child: const HelpButton( // help button for settings
                    message: 'Select a button to change your profile\n\n'
                        'To remove your account click Delete Account \n\n'
                        'Click the Sign Out button to log out of your account',
                    title: "Settings"),
              ),
            ]))));
  }
}
