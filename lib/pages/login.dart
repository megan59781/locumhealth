//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:fyp/pages/company/companyNav.dart';
import 'package:fyp/pages/worker/workerNav.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/googleBut.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State createState() => LoginState();
}

class LoginState extends State<Login> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  DateTime selectedDate = DateTime.now().subtract(const Duration(
      days: ((18 * 365) +
          4))); // date is 18 years from current day (plus 4 = leep years)
  DateTime minAgeDate = DateTime.now().subtract(const Duration(
      days: ((18 * 365) +
          4))); // date is 18 years from current day (plus 4 = leep years)

  final TextEditingController nameController =
      TextEditingController(); // Controller for the company name

  // Retrieves the current latitude and longitude.
  Future<List<double>> getCurrentLatLong() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true,
      );
      double latitude = position.latitude;
      double longitude = position.longitude;

      return [latitude, longitude]; // Return the latitude and longitude
    } catch (e) {
      //print(e);
      return [0.0, 0.0];
    }
  }

  // Adds a worker to the database if it doesn't already exist
  Future<void> addWorkerDb(user) async {
    dbhandler
        .child('Worker')
        .orderByChild('worker_id')
        .equalTo(user.uid)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value == null) {
        DateTime? bday =
            await _dateSelector(context); // get the worker's birthday
        String name = user.displayName.toString();
        List<double> location = await getCurrentLatLong();
        Map<String, dynamic> worker = {
          "worker_id": user.uid,
          "name": name,
          "email": user.email.toString(),
          "bday": bday.toIso8601String(),
          "latitude": location[0],
          "longitude": location[1],
          "miles": 1,
        };
        dbhandler.child("Worker").push().set(worker).then((value) async {
          await addProfileDb(user.uid, name,
              "default"); // Add the worker's profile to the database
          await Future.delayed(const Duration(seconds: 5));
        }).catchError((error) {
          //print("Error saving to Firebase: $error");
        });
      }
    });
    Navigator.push(
        // Navigate to the worker navigation bar
        context,
        MaterialPageRoute(
            builder: (context) => WorkerNavigationBar(
                  workerId: user.uid,
                  setIndex: 0,
                )));
  }

  // Adds a company to the database if it doesn't already exist
  Future<void> addCompanyDb(user) async {
    dbhandler
        .child('Company')
        .orderByChild('company_id')
        .equalTo(user.uid)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value == null) {
        await nameSelector(context);
        String name = nameController.text;
        Map<String, dynamic> company = {
          "company_id": user.uid,
          "name": name,
          "email": user.email.toString(),
        };
        dbhandler.child("Company").push().set(company).then((value) async {
          await addProfileDb(user.uid, name,
              "general care"); // Add the company's profile to the database
          //Navigator.of(context).pop();
        }).catchError((error) {
          //print("Error saving to Firebase: $error");
        });
      }
    });
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                CompanyNavigationBar(companyId: user.uid, setIndex: 0)));
  }

  // Adds a profile to the database
  Future<void> addProfileDb(String userId, String name, String img) async {
    Map<String, dynamic> profile = {
      "user_id": userId,
      "img": img,
      "name": name,
      "experience": 1,
      "description": "No description",
    };
    await dbhandler.child("Profiles").push().set(profile);
  }

  // Verifies the Google account and returns the user information if valid
  // Uses the Google Sign-In package to authenticate and if the authentication is successful, the user information is returned
  Future<User?> _handleSignIn() async {
    try {
      GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!
              .authentication; // Get the authentication details

      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken:
            googleSignInAuthentication.accessToken, // Get the access token
        idToken: googleSignInAuthentication.idToken,
      );

      UserCredential authResult = await _auth.signInWithCredential(credential);
      User? user = authResult.user; // Get the user information

      return user;
    } catch (error) {
      //print(error);
      return null; // Return null if the authentication fails
    }
  }

  // Displays a date picker for the user to select their birthday
  Future<DateTime> _dateSelector(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: selectedDate.subtract(const Duration(days: (31025))),
        lastDate: minAgeDate, // set min age to 18
        helpText: 'Please Pick Your Birthday');
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
    return selectedDate;
  }

  // Displays a dialog box for the user to enter their company name
  Future<void> nameSelector(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Company Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Company Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.of(context).pop(nameController);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
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
                text: 'Login or Register', fontSize: 36, colour: Colors.black),
          ),
        ),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            DisplayText(
                text: 'Company Login', fontSize: 40, colour: Colors.pink[900]),
            const SizedBox(height: 30),
            GoogleButton(
              image: "google_icon_c.png",
              onPress: () async {
                // google company button pressed
                User? user = await _handleSignIn(); // get the user information
                if (user != null) {
                  addCompanyDb(user); // add the company to the database or login if account exists
                } else {
                  // login failed
                  Flushbar(
                    // show a message to confirm the job has been completed
                    backgroundColor: Colors.black,
                    message: "Error logging in, please check your details.",
                    duration: const Duration(seconds: 4),
                  ).show(context);
                }
              },
            ),
            const SizedBox(height: 60),
            DisplayText(
                text: 'Worker Login', fontSize: 40, colour: Colors.teal[900]),
            const SizedBox(height: 30),
            GoogleButton(
              image: "google_icon_w.png",
              onPress: () async {
                User? user = await _handleSignIn(); // get the user information
                if (user != null) { // add the worker to the database or login if account exists
                  addWorkerDb(user);
                } else {
                  Flushbar(
                    // login failed
                    backgroundColor: Colors.black,
                    message: "Error logging in, please check your details.",
                    duration: const Duration(seconds: 4),
                  ).show(context);
                }
              },
            ),
            const SizedBox(height: 50),
          ]),
        ),
      ),
    );
  }
}
