import 'package:flutter/material.dart';

class DateTimeText extends StatelessWidget {
  final String text;
  final Function()? onPress;
  final Icon icon;

  const DateTimeText({
    super.key,
    required this.text,
    required this.onPress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        decoration: BoxDecoration(
          //border: Border.all(color: Colors.blueGrey[300]!, width: 1),
          borderRadius: BorderRadius.circular(60.0),
          color: Colors.blueGrey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey[300]!.withOpacity(0.5), // Shadow color
              spreadRadius: 2,
              blurRadius: 0,
              offset: Offset(0, 0), // changes position of shadow
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
