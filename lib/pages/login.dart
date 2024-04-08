//import 'package:cloud_firestore/cloud_firestore.dart';
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

/// The state class for the Login widget.
class LoginState extends State<Login> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  /// Retrieves the current latitude and longitude.
  ///
  /// Returns a Future that completes with a List containing the latitude and longitude.
  /// If an error occurs, a default location [0.0, 0.0] is returned.
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
      // You might want to handle the error accordingly, for example, returning a default location.
      return [0.0, 0.0];
    }
  }

  /// Adds a worker to the database if it doesn't already exist.
  ///
  /// Retrieves the current location and creates a worker object with the user's information.
  /// The worker object is then pushed to the Firebase database under the "Worker" node.
  Future<void> addWorkerDb(user) async {
    dbhandler
        .child('Worker')
        .orderByChild('worker_id')
        .equalTo(user.uid)
        .onValue
        .listen((event) async {
      print('Snapshot: ${event.snapshot.value}'); // Print the entire snapshot
      if (event.snapshot.value == null) {
        List<double> location = await getCurrentLatLong();

        DateTime bday = DateTime(2000, 1, 1);
        Map<String, dynamic> worker = {
          "worker_id": user.uid,
          "name": user.displayName.toString(),
          "email": user.email.toString(),
          "bday": bday.toIso8601String(),
          "latitude": location[0],
          "longitude": location[1],
          "miles": 0,
        };
        dbhandler.child("Worker").push().set(worker).then((value) {
          //Navigator.of(context).pop();
        }).catchError((error) {
          print("Error saving to Firebase: $error");
        });
      }
    });
  }

  /// Adds a company to the database if it doesn't already exist.
  ///
  /// Creates a company object with the user's information and pushes it to the Firebase database
  /// under the "Company" node.
  Future<void> addCompanyDb(user) async {
    dbhandler
        .child('Company')
        .orderByChild('company_id')
        .equalTo(user.uid)
        .onValue
        .listen((event) {
      print('Snapshot: ${event.snapshot.value}'); // Print the entire snapshot
      if (event.snapshot.value == null) {
        Map<String, dynamic> company = {
          "company_id": user.uid,
          "name": user.displayName.toString(), //TO DO ASK NAME??
          "email": user.email.toString(),
        };
        dbhandler.child("Company").push().set(company).then((value) {
          print("works company");
          //Navigator.of(context).pop();
        }).catchError((error) {
          print("Error saving to Firebase: $error");
        });
      }
    });
  }

  /// Verifies the Google account and returns the user information if valid.
  ///
  /// Uses the Google Sign-In package to authenticate the user with Google.
  /// If the authentication is successful, the user information is returned.
  /// If an error occurs, null is returned.
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
      print(error);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 100),
            DisplayText(
                text: 'Company Login', fontSize: 40, colour: Colors.pink[900]),
            const SizedBox(height: 50),
            GoogleButton(
              image: "google_icon_c.png",
              onPress: () async {
                User? user = await _handleSignIn();
                if (user != null) {
                  print('correct');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CompanyNavigationBar(companyId: user.uid)));
                } else {
                  print('failed');
                  // TO DO SORT FAILED GOOGLE
                }
              },
            ),
            const SizedBox(height: 100),
            DisplayText(
                text: 'Worker Login', fontSize: 40, colour: Colors.teal[900]),
            const SizedBox(height: 50),
            GoogleButton(
              image: "google_icon_w.png",
              onPress: () async {
                User? user = await _handleSignIn();
                if (user != null) {
                  print('correct');
                  addWorkerDb(user);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              WorkerNavigationBar(workerId: user.uid)));
                } else {
                  print('failed');
                  // TO DO SORT FAILED GOOGLE
                }
              },
            ),
            const SizedBox(height: 100),
          ]),
        ),
      ),
    );
  }
}

