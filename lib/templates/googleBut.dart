import 'package:flutter/material.dart';

// template for the google buttons in login page
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
          clipBehavior: Clip.antiAlias,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100.0), 
            ),
            padding: EdgeInsets.zero,
          ),
          child: Image.asset(
            'lib/images/$image',
          )),
    );
  }
}
