import 'package:flutter/material.dart';

class DisplayText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? colour;

  const DisplayText( {
    super.key,
    required this.text,
    required this.fontSize,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Text(
        text,
        style: TextStyle(
          color: colour,
          fontSize: fontSize,
          decorationStyle: TextDecorationStyle.wavy,
        ),
      ),
    );
  }
}
