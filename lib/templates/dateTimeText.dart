import 'package:flutter/material.dart';

// template for the date and time text in companycreatejob page
class DateTimeText extends StatelessWidget { 
  final String text;
  final Function()? onPress;
  final Icon icon;

  const DateTimeText({
    super.key,
    required this.text, // pass text of the date/time/location
    required this.onPress, // pass function
    required this.icon, // pass icon e.g clock/calendar
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(60.0),
          color: Colors.blueGrey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey[300]!.withOpacity(0.5), // Shadow color
              spreadRadius: 2,
              blurRadius: 0,
              offset: const Offset(0, 0), 
            ),
          ],
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                " ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  decorationStyle: TextDecorationStyle.wavy,
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  decorationStyle: TextDecorationStyle.wavy,
                ),
              ),
              IconButton(
                  iconSize: 30,
                  color: Colors.deepPurple,
                  icon: icon,
                  onPressed: onPress),
            ]));
  }
}
