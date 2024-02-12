import 'package:flutter/material.dart';

class GoogleButton extends StatelessWidget {
  final double buttonSize;
  final Function()? onPress;
  const GoogleButton({
    super.key,
    required this.buttonSize,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: buttonSize,
      child: ElevatedButton(
          onPressed: onPress,
          clipBehavior: Clip.antiAlias, // <--add this
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0), // <--add this
            ),
            padding: EdgeInsets.zero, // <--add this
          ),
          child: Image.asset(
            'lib/images/google_icon.png',
          )),
    );
  }
}
