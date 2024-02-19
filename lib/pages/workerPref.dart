import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/templates/dayBut.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class WorkerPreference extends StatefulWidget {
  const WorkerPreference({super.key});

  @override
  State createState() => WorkerPreferenceState();
}

class WorkerPreferenceState extends State<WorkerPreference> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  late String works;

  TimeOfDay selectedTime = TimeOfDay.now();

  Future<bool> workerExists(user) async {
    return await FirebaseFirestore.instance
        .collection("Worker")
        .where("worker_id", isEqualTo: user.uid)
        .get()
        .then((value) => value.size > 0 ? true : false);
  }

  Future<void> addWorkerDb(user) async {
    bool workerRes = await workerExists(user);
    if (workerRes == true) {
      print("worker already in database");
    } else {
      DateTime bday = DateTime(2000, 1, 1);
      Map<String, dynamic> worker = {
        "worker_id": user.uid,
        "name": user.displayName.toString(),
        "email": user.email.toString(),
        "bday": bday.toIso8601String(),
        "location": "Portsmouth".toString(),
      };
      dbhandler.child("Worker").push().set(worker).then((value) {
        Navigator.of(context).pop();
      }).catchError((error) {
        print("Error saving to Firebase: $error");
      });
    }
  }

  Future<User?> _handleSignIn() async {
    try {
      GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      UserCredential authResult = await _auth.signInWithCredential(credential);
      User? user = authResult.user;

      return user;
    } catch (error) {
      //print(error);
      return null;
    }
  }

  void _selectTime(TextEditingController controller) async {
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
  }

  Future<void> _timeselector(BuildContext context) {
    TextEditingController startTimeController = TextEditingController();
    TextEditingController endTimeController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Please Select your Time Availability'),
          content: SizedBox(
            height: MediaQuery.of(context).size.width *
                0.6, // Adjust the width as needed
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const DisplayText(
                    text: "Start Time", fontSize: 25, colour: Colors.black),
                const SizedBox(height: 5),
                TextFormField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                    hintText: 'Select Start Time',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => _selectTime(startTimeController),
                ),
                const SizedBox(height: 20),
                const DisplayText(
                    text: "End Time", fontSize: 25, colour: Colors.black),
                const SizedBox(height: 5),
                TextFormField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                    hintText: 'Select End Time',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => _selectTime(
                    endTimeController,
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Submit'),
              onPressed: () {
                // TO DO SAVE TIMES
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
    return Scaffold(
      backgroundColor: Colors.brown[100],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 200),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 7),
                  Expanded(
                      child: DayButton(
                          text: "Mon", onPress: () => _timeselector(context))),
                  Expanded(
                    child: DayButton(
                        text: "Tue", onPress: () => _timeselector(context)),
                  ),
                  Expanded(
                    child: DayButton(
                        text: "Wed", onPress: () => _timeselector(context)),
                  ),
                  Expanded(
                    child: DayButton(
                        text: "Thu", onPress: () => _timeselector(context)),
                  ),
                  Expanded(
                    child: DayButton(
                        text: "Fri", onPress: () => _timeselector(context)),
                  ),
                  Expanded(
                    child: DayButton(
                        text: "Sat", onPress: () => _timeselector(context)),
                  ),
                  Expanded(
                    child: DayButton(
                        text: "Sun", onPress: () => _timeselector(context)),
                  ),
                ],
              ),
              const SizedBox(height: 200),
            ],
          ),
        ),
      ),
    );
  }
}
