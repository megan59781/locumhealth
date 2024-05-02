import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';

// template for the help button in the app
class HelpButton extends StatefulWidget {
  final String message;
  final String title;

  const HelpButton({
    super.key,
    required this.message, // message to be displayed in pop-up
    required this.title, // title of the pop-up
  });

  @override
  _HelpButtonState createState() => _HelpButtonState();
}

class _HelpButtonState extends State<HelpButton> {

  // Displays the help message in a pop-up
  void helpViewer(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("${widget.title} Help"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DisplayText(
                  text: widget.message, fontSize: 18, colour: Colors.black),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 35,
        width: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Colors.blueGrey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey[300]!.withOpacity(0.5), // Shadow color
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 0), // changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: Material(
                color: Colors.blueGrey[50], // button color
                child: InkWell(
                  onTap: () {
                    helpViewer(context);
                  }, // button pressed
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.help_outline_rounded,
                        color: Color(0xffb00003),
                        size: 35,
                      ), // icon
                    ],
                  ),
                )))); //
  }
}
