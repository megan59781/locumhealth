import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

//Firebase.auth.signOut()

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

      print("Signed in: ${user!.displayName}");

      // Fetch additional user details
      String? userEmail = user.email;
      String? userName = user.displayName;

      //Image userImg = user.photoURL! as Image;

      print("Email: $userEmail");
      print("First Name: $userName");

      return user;
    } catch (error) {
      print(error);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Sign-In with Firebase"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            DateTime bday = DateTime(2000, 1, 1);
            User? user = await _handleSignIn();
            if (user != null) {
              print('correct');
              Map<String, dynamic> worker = {
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
            } else {
              print('failed');
              // Map<String, dynamic> worker = {
              //   "name": user?.displayName.toString(),
              //   "email": user?.email.toString(),
              //   "bday": bday.toIso8601String(),
              //   "location": "Portsmouth".toString(),
              // };

              // dbhandler.child("Worker").push().set(worker).then((value) {
              //   Navigator.of(context).pop();
              // }).catchError((error) {
              //   print("Error saving to Firebase: $error");
              // });
            }
          },
          child: const Text("Sign in with Google"),
        ),
      ),
    );
  }
}
