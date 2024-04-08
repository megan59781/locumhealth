import 'package:flutter/material.dart';

class AbilityButton extends StatelessWidget {
  final String text;
  final Function()? onPress;

  const AbilityButton({super.key, required this.text, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        decoration:
            BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // ListTile(
              //   title: Text(text,
              //       style: const TextStyle(
              //         color: Colors.black,
              //         fontSize: 28,
              //         decorationStyle: TextDecorationStyle.wavy,
              //       )),
              //   leading: Radio(
              //     value: BestTutorSite.javatpoint,
              //     groupValue: _site,
              //     onChanged: (BestTutorSite value) {
              //       setState(() {
              //         _site = value;
              //       });
              //     },
              //   ),
              // ),

              // IconButton(
              //     iconSize: 30,
              //     color: Colors.black,
              //     icon: icon,
              //     onPressed: onPress),
              // Text(
              //   text,
              //   style: const TextStyle(
              //     color: Colors.black,
              //     fontSize: 28,
              //     decorationStyle: TextDecorationStyle.wavy,
              //   ),
              // ),
            ]));
  }
}
