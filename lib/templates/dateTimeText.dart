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
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        decoration:
            BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                  color: Colors.black,
                  icon: icon,
                  onPressed: onPress),
            ]));
  }
}
