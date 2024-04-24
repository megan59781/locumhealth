import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/pages/login.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:google_sign_in/google_sign_in.dart';

class WorkerSettings extends StatefulWidget {
  final String workerId;

  const WorkerSettings({super.key, required this.workerId});

  @override
  State createState() => WorkerSettingsState();
}

class WorkerSettingsState extends State<WorkerSettings> {
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
      getProfile(widget.workerId);
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

  void getProfile(String userId) async {
    await dbhandler
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
        .equalTo(widget.workerId)
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
                await updateProfile(item, textController.text);
                textController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
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
              const SizedBox(height: 20),
              const DisplayText(
                  text: "Settings", fontSize: 30, colour: Colors.black),
              const SizedBox(height: 40),
              PushButton(
                  buttonSize: 70,
                  text: "Change Name",
                  onPress: () =>
                      profileChanger(context, "Profile Name", "name", name)),
              const SizedBox(height: 20),
              PushButton(
                  buttonSize: 70,
                  text: "Change Gender", ///////////////////// TO DO
                  onPress: () =>
                      profileChanger(context, "Gender", 'img', null)),
              const SizedBox(height: 20),
              PushButton(
                  buttonSize: 70,
                  text: "Change Expeience",
                  onPress: () => profileChanger(context, "Years of Experience",
                      "experience", experience)),
              const SizedBox(height: 20),
              PushButton(
                  buttonSize: 70,
                  text: "Change Description",
                  onPress: () => profileChanger(context, "About you summary",
                      "description", description)),
              const SizedBox(height: 20),
              PushButton(
                  buttonSize: 70, text: "Delete Account", onPress: () => null),
              const SizedBox(height: 20),
              PushButton(
                  buttonSize: 70, text: "Sign Out", onPress: () => signOut()),
              const SizedBox(height: 20),
            ]))));
  }
}
