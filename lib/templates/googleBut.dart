import 'package:flutter/material.dart';

class GoogleButton extends StatelessWidget {
  final String image;
  final Function()? onPress;
  const GoogleButton({
    super.key,
    required this.image,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
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
            // ignore: prefer_adjacent_string_concatenation
            'lib/images/$image',
          )),
    );
  }
}
