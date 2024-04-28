import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';

class HelpButton extends StatefulWidget {
  final String message;
  final String title;

  const HelpButton({
    super.key,
    required this.message,
    required this.title,
  });

  @override
  _HelpButtonState createState() => _HelpButtonState();
}

class _HelpButtonState extends State<HelpButton> {
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
          //border: Border.all(color: Colors.blueGrey[300]!, width: 1),
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
