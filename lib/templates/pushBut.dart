import 'package:flutter/material.dart';

class PushButton extends StatelessWidget {
  final double buttonSize;
  final String text;
  final Function()? onPress;
  const PushButton( {
    super.key,
    required this.buttonSize,
    required this.text,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: buttonSize,
      width: buttonSize * 4,
      child: ElevatedButton(
        onPressed: onPress,
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
            padding: MaterialStateProperty.all(const EdgeInsets.all(0))),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
