import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/pages/login.dart';
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

  Future<void> signOut() async {
    await _auth.signOut().then((_) {
      //try the following
      _googleSignIn.signOut();
      //try the following

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              const SizedBox(height: 10),
              PushButton(
                  buttonSize: 60, text: "Sign Out", onPress: () => signOut()),
            ]))));
  }
}
