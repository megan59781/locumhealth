//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/pages/company/companyNav.dart';
import 'package:fyp/pages/worker/workerNav.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/googleBut.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

//FirebaseAuth.instance.signOut()

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State createState() => LoginState();
}

class LoginState extends State<Login> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  late String works;

  // Future<bool> workerExists(user) async {
  //   return await FirebaseFirestore.instance
  //       .collection("Worker")
  //       .where("worker_id", isEqualTo: user.uid)
  //       .get()
  //       .then((value) => value.size > 0 ? true : false);
  // }

  Future<void> addWorkerDb(user) async {
    // bool workerRes = await workerExists(user);
    // if (workerRes == false){
    DateTime bday = DateTime(2000, 1, 1);
    Map<String, dynamic> worker = {
      "worker_id": user.uid,
      "name": user.displayName.toString(),
      "email": user.email.toString(),
      "bday": bday.toIso8601String(),
      "location": "Portsmouth".toString(),
    };
    dbhandler.child("Worker").push().set(worker).then((value) {
      //Navigator.of(context).pop();
    }).catchError((error) {
      print("Error saving to Firebase: $error");
    });
  }

  Future<void> addCompanyDb(user) async {
    // bool workerRes = await workerExists(user);
    // if (workerRes == false){
    Map<String, dynamic> company = {
      "company_id": user.uid,
      "name": user.displayName.toString(),
      "email": user.email.toString(),
    };
    dbhandler.child("Company").push().set(company).then((value) {
      //Navigator.of(context).pop();
    }).catchError((error) {
      print("Error saving to Firebase: $error");
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      body: SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 100),
            DisplayText(
                text: 'Company Login', fontSize: 40, colour: Colors.pink[900]),
            const SizedBox(height: 50),
            GoogleButton(
              buttonSize: 125,
              onPress: () async {
                User? user = await _handleSignIn();
                if (user != null) {
                  print('correct');
                  //addWorkerDb(user);
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
              buttonSize: 125,
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
