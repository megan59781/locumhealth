import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/pages/company/companyNav.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/profileView.dart';

class CompanyProfile extends StatefulWidget {
  final String companyId;

  const CompanyProfile({super.key, required this.companyId});

  @override
  State createState() => CompanyProfileState();
}

class CompanyProfileState extends State<CompanyProfile> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  String name = "Company Name";
  String imgPath = "general care";
  String description = "No Description";

  @override
  void initState() {
    super.initState();
    setState(() {
      getProfile(widget.companyId);
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
            description = pData['description'];
          });
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
            padding: EdgeInsets.only(top: 15), // Add padding above the title
            child: Center(
              child: DisplayText(
                  text: 'Company Profile', fontSize: 36, colour: Colors.black),
            ),
          ),
          automaticallyImplyLeading: false, // Remove the back button
        ),
        body: SafeArea(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              const SizedBox(height: 30),
              ProfileView(
                  name: name,
                  imgPath: imgPath,
                  experience: "",
                  description: description,
                  scale: 1),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  // Action to perform when the button is pressed
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CompanyNavigationBar(companyId: widget.companyId, setIndex: 3)));
                },
                child: const DisplayText(
                    text: "To edit the profile go to settings",
                    fontSize: 18,
                    colour: Colors.deepPurple),
              ),
            ]))));
  }
}
