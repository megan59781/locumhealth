import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';

// template for the profile view in the app
class ProfileView extends StatelessWidget {
  final String name;
  final String imgPath;
  final String experience;
  final String description;
  final int scale;

  ProfileView(
      {required this.name,
      required this.imgPath,
      required this.experience,
      required this.description,
      required this.scale}); // scale to alter pop up vs profile page view

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 100/scale,
          backgroundImage: AssetImage('lib/images/$imgPath.png'), // image path
        ),
        const SizedBox(height: 20),
        DisplayText(text: name, fontSize: 30/scale, colour: Colors.black),
        const SizedBox(height: 10),
        if (experience != "")
          DisplayText(text: experience, fontSize: 30/scale, colour: Colors.black),
        const SizedBox(height: 20),
        Container(
            height: 270/scale,
            width: 350/scale,
            padding:
                const EdgeInsets.symmetric(horizontal: 2.0, vertical: 10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.black, width: 2)),
            child: DisplayText(
                text: description, fontSize: 20/scale, colour: Colors.black)),
      ],
    );
  }
}
