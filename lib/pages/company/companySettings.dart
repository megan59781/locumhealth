import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/pages/login.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/helpBut.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CompanySettings extends StatefulWidget {
  final String companyId;

  const CompanySettings({super.key, required this.companyId});

  @override
  State createState() => CompanySettingsState();
}

class CompanySettingsState extends State<CompanySettings> {
  // Firebase authentication and google sign in for sign out
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();

  // set for default company profile
  String name = " First Last Name ";
  String imgPath = "default";
  int experience = 0;
  String description = "No Description";
  final TextEditingController textController =
      TextEditingController(); // for changing profile

  @override
  void initState() {
    super.initState();
    setState(() {
      // Set the state of the variables from database
      getProfile(widget.companyId);
    });
  }

  // Function to sign out of the account
  Future<void> signOut() async {
    await _auth.signOut().then((_) {
      _googleSignIn.signOut();

      Navigator.push(
          // Navigate to the login page
          context,
          MaterialPageRoute(builder: (context) => const Login()));
    });
  }

  // Function to get the company profile from the database
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

  // Function to update the company profile in the database
  Future<void> updateProfile(String item, dynamic value) async {
    dbhandler
        .child('Profiles')
        .orderByChild('user_id')
        .equalTo(widget.companyId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          var profileKey = data.keys.first;
          await dbhandler.child('Profiles').child(profileKey).update({
            item: value,
          });
        }
      } else {
        // no profile found
      }
    });
  }

  // Function to change the image of the company profile
  Future<void> imageChanger(BuildContext context, String value) async {
    String dropdownValue = value;

    // Dropdown items link to picture names
    List<String> dropdownItems = [
      'childcare',
      'physical disabilities',
      'elderly',
      'learning disabilities',
      'general care',
    ];

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Set the Main Care Type"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: dropdownValue, // set to selected value
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                    items: dropdownItems // inital value is the current value
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value), // text of image
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
                    await updateProfile("img",
                        dropdownValue); // update image in profile database
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      // message to show image updated
                      content: Text("Image Updated!"),
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

  // Function to change the profile details (NOT IMAGE THO)
  Future<void> profileChanger(
      // title is database value and value is what stored
      BuildContext context,
      String title,
      String item,
      dynamic value) async {
    showDialog<void>(
      // pass title of what changing
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Change $title"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller:
                  textController, // text controller to get the new value
              decoration:
                  InputDecoration(labelText: value), // shows current value
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
                  // if experience is being changed, parse to int
                  value = int.parse(value);
                }
                await updateProfile(
                    item, value); // update the profile in the database
                textController.clear();
                Navigator.of(context).pop(value);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  // message to show item updated
                  content: Text("$item Updated!"),
                ));
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete all jobs associated with the company if company is deleted
  Future<void> deleteJobs(String companyId) async {
    List<String> jobIdList = [];
    await dbhandler // get all jobs associated with the company
        .child('Assigned Jobs')
        .orderByChild('company_id')
        .equalTo(companyId)
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
    // delete all jobs associated with the company
    for (String jobId in jobIdList) {
      dbhandler // remove the job from the jobs
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
            var jobKey = data.keys.first;
            dbhandler.child('Jobs').child(jobKey).remove();
          }
        }
      });
      dbhandler // remove the job from the assigned jobs
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
            var jobKey = data.keys.first;
            dbhandler.child('Assigned Jobs').child(jobKey).remove();
          }
        }
      });
    }
  }

  // Function to delete the company profile and company
  Future<void> deleteCompany(String companyId) async {
    dbhandler // remove the company from the profiles
        .child('Profiles')
        .orderByChild('user_id')
        .equalTo(companyId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          var profileKey = data.keys.first;
          dbhandler.child('Profiles').child(profileKey).remove();
        }
      }
    });
    dbhandler
        .child('Company')
        .orderByChild('company_id')
        .equalTo(companyId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          var companyKey = data.keys.first;
          dbhandler.child('Company').child(companyKey).remove();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xffFCFAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xffFCFAFC),
          title: const Padding(
            padding: EdgeInsets.only(top: 15),
            child: Center(
              child: DisplayText(
                  text: 'Settings', fontSize: 36, colour: Colors.black),
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
              const SizedBox(height: 90),
              PushButton(
                  buttonSize: 70,
                  text: "Change Name",
                  onPress: () => // change the name of the company
                      profileChanger(context, "Company Name", "name", name)),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70,
                  text: "Change Care Type", // change the image of the company
                  onPress: () => imageChanger(context, imgPath)),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70,
                  text:
                      "Change Description", // change the description of the company
                  onPress: () => profileChanger(context, "Your Company Summary",
                      "description", description)),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70,
                  text: "Delete Account",
                  onPress: () => {
                        // delete the account and all associated jobs and data
                        deleteJobs(widget.companyId),
                        deleteCompany(widget.companyId),
                      }),
              const SizedBox(height: 25),
              PushButton( // sign out of the account
                  buttonSize: 70, text: "Sign Out", onPress: () => signOut()),
              const SizedBox(height: 75),
              Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(top: 20, right: 30),
                child: const HelpButton( // help button for user how to use page
                    message: 'Select a button to change your profile\n\n'
                        'To remove your account click Delete Account \n\n'
                        'Click the Sign Out button to log out of your account',
                    title: "Settings"),
              ),
            ]))));
  }
}
