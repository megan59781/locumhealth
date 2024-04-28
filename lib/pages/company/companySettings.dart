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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  String name = " First Last Name ";
  String imgPath = "default";
  int experience = 0;
  String description = "No Description";
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {
      getProfile(widget.companyId);
    });
  }

  Future<void> signOut() async {
    await _auth.signOut().then((_) {
      //try the following
      _googleSignIn.signOut();
      //try the following

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
    });
  }

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
        print("profile works here");
        if (data != null) {
          var profileKey = data.keys.first;
          await dbhandler.child('Profiles').child(profileKey).update({
            item: value,
          });
          print("profile works here");
        }
      } else {
        print("No Profile Found");
      }
    });
  }

  Future<void> imageChanger(BuildContext context, String value) async {
    String dropdownValue = value;

    // Dropdown items
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
                    value: dropdownValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                    items: dropdownItems
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
                    // Call updateProfile function with the selected value
                    await updateProfile("img", dropdownValue);

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
                await updateProfile(item, value);
                textController.clear();
                Navigator.of(context).pop(value);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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

  Future<void> deleteJobs(String companyId) async {
    List<String> jobIdList = [];
    await dbhandler
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

    for (String jobId in jobIdList) {
      dbhandler
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
            // Assuming there is only one entry, you can access it directly
            var jobKey = data.keys.first;
            dbhandler.child('Jobs').child(jobKey).remove();
          }
        }
      });
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
            var jobKey = data.keys.first;
            dbhandler.child('Assigned Jobs').child(jobKey).remove();
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
            padding: EdgeInsets.only(top: 15), // Add padding above the title
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
                  onPress: () =>
                      profileChanger(context, "Company Name", "name", name)),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70,
                  text: "Change Care Type",
                  onPress: () => imageChanger(context, imgPath)),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70,
                  text: "Change Description",
                  onPress: () => profileChanger(context, "Your Company Summary",
                      "description", description)),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70,
                  text: "Delete Account",
                  onPress: () => {
                        deleteJobs(widget.companyId),
                        //TO DO: Delete the company profile
                      }),
              const SizedBox(height: 25),
              PushButton(
                  buttonSize: 70, text: "Sign Out", onPress: () => signOut()),
              const SizedBox(height: 75),
              Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(top: 20, right: 30),
                child: const HelpButton(
                    message:
                        'Select a button to change your profile\n\n'
                        'To remove your account click Delete Account \n\n'
                        'Click the Sign Out button to log out of your account',
                    title: "Settings"),
              ),
            ]))));
  }
}
