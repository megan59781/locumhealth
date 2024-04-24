import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/profileView.dart';

class WorkerProfile extends StatefulWidget {
  final String workerId;

  const WorkerProfile({super.key, required this.workerId});

  @override
  State createState() => WorkerProfileState();
}

class WorkerProfileState extends State<WorkerProfile> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  String name = " First Last Name ";
  String imgPath = "default";
  int experience = 0;
  String description = "No Description";

  @override
  void initState() {
    super.initState();
    setState(() {
      getProfile();
    });
  }

  void getProfile() async {
    await dbhandler
        .child('Profiles')
        .orderByChild('user_id')
        .equalTo(widget.workerId)
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

  @override
  Widget build(BuildContext context) {
    // setState(() {
    //   getProfile(widget.workerId);
    // });
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              const SizedBox(height: 30),
              const DisplayText(
                  text: "Your Profile", fontSize: 30, colour: Colors.black),
                  const SizedBox(height: 40),
              ProfileView(
                  name: name,
                  imgPath: imgPath,
                  experience: '$experience Years Experience',
                  description: description,
                  scale: 1,),
              const SizedBox(height: 40),
              const DisplayText(
                  text: "To edit your profile go to settings",
                  fontSize: 20,
                  colour: Colors.deepPurple),
            ]))));
  }
}
